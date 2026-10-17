import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:bitacora_red/models/net_port.dart';
import 'package:bitacora_red/models/net_switch.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/controllers/network_utils.dart';
import 'package:bitacora_red/views/pantalla_puertos.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/motion.dart';
import 'package:flutter/material.dart';

/// Switches de todos los edificios (menú principal).
class SwitchesScreen extends StatelessWidget {
  const SwitchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Switches')),
      body: const SwitchesTab(),
    );
  }
}

/// Lista de switches. Con [network] muestra solo los de ese edificio.
///  - Administrador: crea, edita, cambia estado, restablece puertos y elimina.
///  - Técnico: solo cambia el estado y consulta el historial.
class SwitchesTab extends StatefulWidget {
  final NetworkGroup? network;
  const SwitchesTab({super.key, this.network});

  @override
  State<SwitchesTab> createState() => _SwitchesTabState();
}

class _SwitchesTabState extends State<SwitchesTab> {
  final dbHelper = DatabaseHelper();
  List<NetSwitch> switches = [];
  List<NetworkGroup> networks = [];
  Map<String, List<NetPort>> portsBySwitch = {};
  bool loading = true;

  bool get isAdmin => AppSession.isAdmin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final nets = await dbHelper.getNetworks();
      final sws = widget.network == null
          ? await dbHelper.getAllSwitches()
          : await dbHelper.getSwitchesByNetwork(widget.network!.id);
      final ports = await dbHelper.getAllPorts();
      final map = <String, List<NetPort>>{};
      for (final p in ports) {
        (map[p.switchId] ??= []).add(p);
      }
      if (mounted) {
        setState(() {
          networks = nets;
          switches = sws;
          portsBySwitch = map;
        });
      }
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudieron cargar los switches: $e', error: true);
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
    _loadData();
  }

  NetworkGroup? _networkOf(NetSwitch sw) {
    for (final n in networks) {
      if (n.id == sw.networkId) return n;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (switches.isEmpty)
          EmptyState(
            icon: Icons.dns_outlined,
            title: widget.network == null ? 'Sin switches registrados' : 'Este edificio aún no tiene switches',
            hint: isAdmin ? 'Toca "Agregar switch" para crear el primero.' : null,
          )
        else
          RefreshIndicator(
            onRefresh: _loadData,
            child: ResponsiveList(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: switches.length,
              itemBuilder: (context, index) => FadeSlideIn(index: index, child: _card(switches[index])),
            ),
          ),
        if (isAdmin && networks.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'add_switch_${widget.network?.id ?? 'global'}',
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar switch'),
            ),
          ),
      ],
    );
  }

  Widget _card(NetSwitch sw) {
    final net = _networkOf(sw);
    final ports = portsBySwitch[sw.id] ?? [];
    final operativos = ports.where((p) => p.operativo).length;
    final sinOperar = ports.length - operativos;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PortsScreen(switchDevice: sw, network: net)),
            );
            _loadData();
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 2, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(sw.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          ),
                          if (widget.network == null && net != null) ...[
                            const SizedBox(width: 8),
                            Tag(net.name),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [if (sw.ip.isNotEmpty) sw.ip, if (sw.model.isNotEmpty) sw.model, if (sw.location.isNotEmpty) sw.location]
                            .join('  ·  '),
                        style: AppText.mono(size: 12.5, color: AppColors.inkMuted),
                      ),
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          EstadoChip(sw.estado),
                          const SizedBox(width: 14),
                          Text('$operativos/${ports.length} puertos',
                              style: AppText.mono(size: 12, color: sinOperar > 0 ? AppColors.accentText : AppColors.inkMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.inkMuted),
                  onSelected: (value) => _onMenu(value, sw),
                  itemBuilder: (context) => [
                    if (isAdmin) _item('edit', Icons.edit_outlined, 'Editar información'),
                    _item('estado', Icons.flag_outlined, 'Cambiar estado'),
                    if (isAdmin) _item('reset', Icons.restart_alt, 'Restablecer puertos'),
                    _item('history', Icons.history, 'Ver historial'),
                    if (isAdmin) _item('delete', Icons.delete_outline, 'Eliminar switch', danger: true),
                  ],
                ),
              ],
            ),
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

  Future<void> _onMenu(String value, NetSwitch sw) async {
    switch (value) {
      case 'edit':
        await _showForm(existing: sw);
      case 'estado':
        final nuevo = await pickEstado(context, titulo: 'Estado del switch', opciones: kEstadosInfra, actual: sw.estado);
        if (nuevo == null || nuevo == sw.estado) return;
        final anterior = sw.estado;
        sw.estado = nuevo;
        await _run(
          () => dbHelper.updateSwitch(sw, detalle: 'El switch "${sw.name}" cambió de "$anterior" a "$nuevo"'),
          'Estado actualizado',
        );
      case 'reset':
        final ok = await confirmar(
          context,
          titulo: 'Restablecer puertos',
          mensaje: 'Todos los puertos de "${sw.name}" quedarán disponibles y sin VLAN, departamento ni observaciones. ¿Continuar?',
          accion: 'Restablecer',
        );
        if (ok) await _run(() => dbHelper.resetSwitchPorts(sw), 'Puertos restablecidos');
      case 'history':
        await showHistorialDialog(context, titulo: sw.name, entityId: sw.id);
      case 'delete':
        final ok = await confirmar(
          context,
          titulo: 'Eliminar switch',
          mensaje: 'Se eliminará "${sw.name}" junto con todos sus puertos. ¿Continuar?',
        );
        if (ok) await _run(() => dbHelper.deleteSwitch(sw), 'Switch eliminado');
    }
  }

  Future<void> _showForm({NetSwitch? existing}) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name ?? '');
    final model = TextEditingController(text: existing?.model ?? '');
    final ip = TextEditingController(text: existing?.ip ?? '');
    final location = TextEditingController(text: existing?.location ?? '');
    final ports = TextEditingController(text: '24');
    String? networkId = existing?.networkId ?? widget.network?.id ?? (networks.isNotEmpty ? networks.first.id : null);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Nuevo switch' : 'Editar switch'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.network == null && existing == null) ...[
                    DropdownButtonFormField<String>(
                      initialValue: networkId,
                      decoration: const InputDecoration(labelText: 'Edificio'),
                      items: networks.map((n) => DropdownMenuItem(value: n.id, child: Text(n.name))).toList(),
                      onChanged: (v) => setLocal(() => networkId = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: model, decoration: const InputDecoration(labelText: 'Modelo / Marca')),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: ip,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'IP de administración'),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      return NetworkUtils.isValidIp(t) ? null : 'IP no válida';
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: location,
                    decoration: const InputDecoration(labelText: 'Ubicación (Ej. Rack 2, Piso 1)'),
                  ),
                  if (existing == null) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: ports,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Número de puertos'),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1 || n > 96) return 'Entre 1 y 96';
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) Navigator.pop(context, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || networkId == null) return;

    if (existing == null) {
      final sw = NetSwitch(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        networkId: networkId!,
        name: name.text.trim(),
        model: model.text.trim(),
        ip: ip.text.trim(),
        location: location.text.trim(),
      );
      final count = int.parse(ports.text);
      await _run(() => dbHelper.insertSwitch(sw, portCount: count), 'Switch creado con $count puertos');
    } else {
      existing
        ..name = name.text.trim()
        ..model = model.text.trim()
        ..ip = ip.text.trim()
        ..location = location.text.trim();
      await _run(() => dbHelper.updateSwitch(existing), 'Switch actualizado');
    }
  }
}
