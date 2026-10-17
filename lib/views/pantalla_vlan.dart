import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/controllers/network_utils.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/motion.dart';
import 'package:flutter/material.dart';

/// Segmentos y VLAN de todos los edificios (menú del administrador).
class VlanScreen extends StatelessWidget {
  const VlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segmentos y VLAN')),
      body: const VlansTab(),
    );
  }
}

/// Lista de VLAN. Con [network] muestra solo las de ese edificio.
/// Solo el administrador puede crear, editar y eliminar.
class VlansTab extends StatefulWidget {
  final NetworkGroup? network;
  const VlansTab({super.key, this.network});

  @override
  State<VlansTab> createState() => _VlansTabState();
}

class _VlansTabState extends State<VlansTab> {
  final db = DatabaseHelper();
  List<Subnet> vlans = [];
  List<NetworkGroup> networks = [];
  bool loading = true;

  bool get isAdmin => AppSession.isAdmin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final nets = await db.getNetworks();
      final all = widget.network == null ? await db.getSubnets() : await db.getSubnetsByNetwork(widget.network!.id);
      if (mounted) {
        setState(() {
          networks = nets;
          vlans = all;
        });
      }
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudieron cargar las VLAN: $e', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _run(Future<void> Function() action, String ok) async {
    try {
      await action();
      if (mounted) showMsg(context, ok);
    } catch (e) {
      if (mounted) showMsg(context, 'Error: $e', error: true);
    }
    _load();
  }

  String _networkName(String id) {
    for (final n in networks) {
      if (n.id == id) return n.name;
    }
    return '';
  }

  Future<void> _openForm({Subnet? existing}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => VlanFormScreen(
          existing: existing,
          networks: networks,
          fixedNetwork: widget.network,
          allVlans: vlans,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (vlans.isEmpty)
          EmptyState(
            icon: Icons.lan_outlined,
            title: 'Sin VLAN registradas',
            hint: isAdmin ? 'Toca "Nueva VLAN" para crear la primera.' : null,
          )
        else
          RefreshIndicator(
            onRefresh: _load,
            child: ResponsiveList(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: vlans.length,
              itemBuilder: (context, i) => FadeSlideIn(index: i, child: _card(vlans[i])),
            ),
          ),
        if (isAdmin && networks.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'add_vlan_${widget.network?.id ?? 'global'}',
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nueva VLAN'),
            ),
          ),
      ],
    );
  }

  Widget _card(Subnet v) {
    Widget kv(String k, String val) => Padding(
          padding: const EdgeInsets.only(right: 18, top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(k, style: TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
              const SizedBox(height: 1),
              Text(val.isEmpty ? '-' : val, style: AppText.mono(size: 12.5, weight: FontWeight.w600)),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 2, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Tag(v.vlanNumber != null ? 'VLAN ${v.vlanNumber}' : 'VLAN', color: AppColors.primary, mono: true),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        if (widget.network == null)
                          Text(_networkName(v.networkId), style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  EstadoChip(v.estado),
                  if (isAdmin)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: AppColors.inkMuted),
                      onSelected: (value) => _onMenu(value, v),
                      itemBuilder: (context) => [
                        _item('edit', Icons.edit_outlined, 'Editar'),
                        _item('estado', Icons.flag_outlined, 'Cambiar estado'),
                        _item('history', Icons.history, 'Ver historial'),
                        _item('delete', Icons.delete_outline, 'Eliminar VLAN', danger: true),
                      ],
                    )
                  else
                    const SizedBox(width: 14),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Wrap(
                  children: [
                    kv('Red', '${v.baseIp}/${v.mask}'),
                    kv('Ruteador', v.gateway),
                    kv('Rango', '${v.ipStart} - ${v.ipEnd}'),
                    kv('Broadcast', v.broadcast),
                    kv('Hosts', v.hosts?.toString() ?? ''),
                    if (v.excluded.isNotEmpty) kv('Excluido', v.excluded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label, {bool danger = false}) {
    final color = danger ? AppColors.error : AppColors.ink;
    return PopupMenuItem(
      value: value,
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ]),
    );
  }

  Future<void> _onMenu(String value, Subnet v) async {
    switch (value) {
      case 'edit':
        await _openForm(existing: v);
      case 'estado':
        final nuevo = await pickEstado(context, titulo: 'Estado de la VLAN', opciones: kEstadosInfra, actual: v.estado);
        if (nuevo == null || nuevo == v.estado) return;
        final anterior = v.estado;
        v.estado = nuevo;
        await _run(
          () => db.updateSubnet(v, detalle: 'La VLAN "${v.name}" cambió de "$anterior" a "$nuevo"'),
          'Estado actualizado',
        );
      case 'history':
        await showHistorialDialog(context, titulo: v.name, entityId: v.id);
      case 'delete':
        final ok = await confirmar(
          context,
          titulo: 'Eliminar VLAN',
          mensaje: 'Se eliminará "${v.name}". Los equipos registrados en ella quedarán sin segmento. ¿Continuar?',
        );
        if (ok) await _run(() => db.deleteSubnet(v.id, v.name), 'VLAN eliminada');
    }
  }
}

/// Formulario de VLAN: nombre, VLAN, estado, red, máscara, ruteador
/// predeterminado, broadcast, rango inicial y final, rango excluido (opcional)
/// y hosts usables.
class VlanFormScreen extends StatefulWidget {
  final Subnet? existing;
  final List<NetworkGroup> networks;
  final NetworkGroup? fixedNetwork;
  final List<Subnet> allVlans;
  const VlanFormScreen({
    super.key,
    this.existing,
    required this.networks,
    this.fixedNetwork,
    required this.allVlans,
  });

  @override
  State<VlanFormScreen> createState() => _VlanFormScreenState();
}

class _VlanFormScreenState extends State<VlanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final db = DatabaseHelper();

  late final TextEditingController name, vlanNumber, red, mask, gateway, broadcast, ipStart, ipEnd, excluded, hosts;
  String? networkId;
  String estado = 'Activo';
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    name = TextEditingController(text: e?.name ?? '');
    vlanNumber = TextEditingController(text: e?.vlanNumber?.toString() ?? '');
    red = TextEditingController(text: e?.baseIp ?? '');
    mask = TextEditingController(text: e?.mask ?? '');
    gateway = TextEditingController(text: e?.gateway ?? '');
    broadcast = TextEditingController(text: e?.broadcast ?? '');
    ipStart = TextEditingController(text: e?.ipStart ?? '');
    ipEnd = TextEditingController(text: e?.ipEnd ?? '');
    excluded = TextEditingController(text: e?.excluded ?? '');
    hosts = TextEditingController(text: e?.hosts?.toString() ?? '');
    estado = e?.estado ?? 'Activo';
    networkId = e?.networkId ?? widget.fixedNetwork?.id ?? (widget.networks.isNotEmpty ? widget.networks.first.id : null);
  }

  @override
  void dispose() {
    for (final c in [name, vlanNumber, red, mask, gateway, broadcast, ipStart, ipEnd, excluded, hosts]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Si la red y la máscara son válidas, completa los campos calculados.
  void _recalculate() {
    final m = NetworkUtils.parseMask(mask.text);
    if (!NetworkUtils.isValidIp(red.text) || m == null) return;
    final net = NetworkUtils.ipToLong(red.text.trim());
    final size = NetworkUtils.sizeFromMask(m);
    setState(() {
      broadcast.text = NetworkUtils.longToIp(net + size - 1);
      gateway.text = NetworkUtils.longToIp(net + 1);
      ipStart.text = NetworkUtils.longToIp(net + 2);
      ipEnd.text = NetworkUtils.longToIp(net + size - 2);
      hosts.text = '${size - 2}';
    });
  }

  bool _inRange(String ip, int net, int size) {
    final v = NetworkUtils.ipToLong(ip.trim());
    return v >= net + 1 && v <= net + size - 2;
  }

  String? _validateIp(String? v, {bool required = true}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return required ? 'Requerido' : null;
    return NetworkUtils.isValidIp(t) ? null : 'IP no válida';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || networkId == null) return;

    final maskDotted = NetworkUtils.parseMask(mask.text)!;
    final net = NetworkUtils.ipToLong(red.text.trim());
    final size = NetworkUtils.sizeFromMask(maskDotted);

    // La dirección de red debe ser la primera del bloque.
    if (net % size != 0) {
      showMsg(context, 'La dirección de red no corresponde a esa máscara. ¿Quisiste ${NetworkUtils.longToIp(net - net % size)}?', error: true);
      return;
    }
    if (!_inRange(gateway.text, net, size) || !_inRange(ipStart.text, net, size) || !_inRange(ipEnd.text, net, size)) {
      showMsg(context, 'El ruteador y el rango deben estar dentro de la red.', error: true);
      return;
    }
    if (NetworkUtils.ipToLong(ipStart.text.trim()) > NetworkUtils.ipToLong(ipEnd.text.trim())) {
      showMsg(context, 'El rango inicial no puede ser mayor que el final.', error: true);
      return;
    }
    final ex = excluded.text.trim();
    if (ex.isNotEmpty) {
      final parts = ex.split(RegExp(r'\s*[-–]\s*'));
      final ok = parts.length <= 2 &&
          parts.every((p) => NetworkUtils.isValidIp(p) && _inRange(p, net, size)) &&
          (parts.length == 1 || NetworkUtils.ipToLong(parts[0]) <= NetworkUtils.ipToLong(parts[1]));
      if (!ok) {
        showMsg(context, 'El rango excluido debe ser "IP" o "IP inicial - IP final" dentro de la red.', error: true);
        return;
      }
    }
    // No traslapar con otras VLAN del mismo edificio.
    for (final other in widget.allVlans) {
      if (other.networkId != networkId || other.id == widget.existing?.id) continue;
      final oStart = other.networkLong;
      final oEnd = other.networkLong + other.size - 1;
      if (net <= oEnd && net + size - 1 >= oStart) {
        showMsg(context, 'Esa red se traslapa con la VLAN "${other.name}" (${other.baseIp}).', error: true);
        return;
      }
    }

    final subnet = Subnet(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      networkId: networkId!,
      name: name.text.trim(),
      baseIp: red.text.trim(),
      size: size,
      vlanNumber: int.parse(vlanNumber.text.trim()),
      estado: estado,
      mask: maskDotted,
      gateway: gateway.text.trim(),
      broadcast: NetworkUtils.longToIp(net + size - 1),
      ipStart: ipStart.text.trim(),
      ipEnd: ipEnd.text.trim(),
      excluded: ex,
      hosts: size - 2,
    );

    setState(() => saving = true);
    try {
      if (widget.existing == null) {
        await db.insertSubnet(subnet, log: true);
      } else {
        await db.updateSubnet(subnet);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar VLAN' : 'Nueva VLAN')),
      body: Centered(child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (widget.fixedNetwork == null && !editing) ...[
              DropdownButtonFormField<String>(
                initialValue: networkId,
                decoration: const InputDecoration(labelText: 'Edificio'),
                items: widget.networks.map((n) => DropdownMenuItem(value: n.id, child: Text(n.name))).toList(),
                onChanged: (v) => setState(() => networkId = v),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre (Ej. Alumnos)'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: vlanNumber,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'VLAN (1-4094)'),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1 || n > 4094) return 'Entre 1 y 4094';
                      for (final o in widget.allVlans) {
                        if (o.networkId == networkId && o.vlanNumber == n && o.id != widget.existing?.id) {
                          return 'Ya existe en este edificio';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: kEstadosInfra.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                    isExpanded: true,
                    onChanged: (v) => setState(() => estado = v ?? estado),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: red,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Red (Ej. 192.168.10.0)'),
              onChanged: (_) => _recalculate(),
              validator: _validateIp,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: mask,
              decoration: const InputDecoration(
                labelText: 'Máscara de subred',
                hintText: '255.255.255.0 o /24',
              ),
              onChanged: (_) => _recalculate(),
              validator: (v) => NetworkUtils.parseMask(v ?? '') == null ? 'Máscara no válida (Ej. 255.255.255.0 o /24)' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: gateway,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ruteador predeterminado'),
              validator: _validateIp,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: broadcast,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Broadcast (se calcula solo)'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: ipStart,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rango IP inicial'),
                    validator: _validateIp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: ipEnd,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Rango IP final'),
                    validator: _validateIp,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: excluded,
              decoration: const InputDecoration(
                labelText: 'Rango excluido (opcional)',
                hintText: '192.168.10.2 - 192.168.10.10',
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: hosts,
              readOnly: true,
              decoration: const InputDecoration(labelText: 'Hosts usables (se calcula solo)'),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : Text(editing ? 'Guardar cambios' : 'Crear VLAN'),
            ),
          ],
        ),
      )),
    );
  }
}
