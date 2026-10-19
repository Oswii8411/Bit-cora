import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/validators.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/views/asistente_red.dart';
import 'package:bitacora_red/views/pantalla_segmentos.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/motion.dart';
import 'package:flutter/material.dart';

/// Colores que se pueden asignar a un edificio (los primeros son de la paleta de marca).
const List<Color> kNetworkColors = [
  AppColors.palette4,
  AppColors.palette3,
  Color(0xFF0F766E),
  Color(0xFFB45309),
  Color(0xFFB91C1C),
  Color(0xFF475569),
];

/// Edificios: el administrador los administra; el técnico solo los consulta.
class BuildingsScreen extends StatefulWidget {
  const BuildingsScreen({super.key});

  @override
  State<BuildingsScreen> createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  final dbHelper = DatabaseHelper();
  List<NetworkGroup> networks = [];
  final Map<String, int> switchCount = {}, vlanCount = {};
  bool loading = true;

  bool get isAdmin => AppSession.isAdmin;

  @override
  void initState() {
    super.initState();
    DatabaseHelper().changes.addListener(_onDataChanged);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await dbHelper.getNetworks();
      final switches = await dbHelper.getAllSwitches();
      final vlans = await dbHelper.getSubnets();
      switchCount.clear();
      vlanCount.clear();
      for (final sw in switches) {
        switchCount[sw.networkId] = (switchCount[sw.networkId] ?? 0) + 1;
      }
      for (final v in vlans) {
        vlanCount[v.networkId] = (vlanCount[v.networkId] ?? 0) + 1;
      }
      if (mounted) setState(() => networks = data);
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudieron cargar los edificios: $e', error: true);
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

  void _onDataChanged() {
    if (mounted) _loadData();
  }

  @override
  void dispose() {
    DatabaseHelper().changes.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edificios', style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.4)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(child: Text('${networks.length}', style: AppText.mono(size: 15, color: AppColors.inkMuted))),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : networks.isEmpty
              ? EmptyState(
                  icon: Icons.apartment_outlined,
                  title: 'Sin edificios registrados',
                  hint: isAdmin ? 'Toca "Agregar edificio" para crear el primero.' : 'El administrador aún no registra edificios.',
                )
              : RefreshIndicator(
                  onRefresh: () {
            DatabaseHelper().invalidateCache();
            return _loadData();
          },
                  child: ResponsiveList(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                    itemCount: networks.length,
                    itemBuilder: (context, index) {
                      final net = networks[index];
                      return FadeSlideIn(
                        index: index,
                        child: _BuildingRow(
                          net: net,
                          switches: switchCount[net.id] ?? 0,
                          vlans: vlanCount[net.id] ?? 0,
                          isAdmin: isAdmin,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SegmentsScreen(network: net)),
                            );
                            _loadData();
                          },
                          onMenu: (value) => _onMenu(value, net),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NetworkWizardScreen()),
                );
                _loadData();
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar edificio'),
            )
          : null,
    );
  }

  Future<void> _onMenu(String value, NetworkGroup net) async {
    switch (value) {
      case 'info':
        await _showInfo(net);
      case 'history':
        await showHistorialDialog(context, titulo: net.name, entityId: net.id);
      case 'edit':
        await _editInfo(net);
      case 'estado':
        final nuevo = await pickEstado(context, titulo: 'Estado del edificio', opciones: kEstadosInfra, actual: net.estado);
        if (nuevo == null || nuevo == net.estado) return;
        final anterior = net.estado;
        net.estado = nuevo;
        await _run(
          () => dbHelper.updateNetwork(net, detalle: 'El edificio "${net.name}" cambió de "$anterior" a "$nuevo"'),
          'Estado actualizado',
        );
      case 'color':
        await _changeColor(net);
      case 'delete':
        final ok = await confirmar(
          context,
          titulo: 'Eliminar edificio',
          mensaje: 'Se eliminará "${net.name}" junto con sus VLAN, switches y puertos. ¿Continuar?',
        );
        if (ok) await _run(() => dbHelper.deleteNetwork(net.id, net.name), 'Edificio eliminado');
    }
  }

  Future<void> _showInfo(NetworkGroup net) async {
    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 100, child: Text(k, style: TextStyle(color: AppColors.inkMuted))),
              Expanded(child: Text(v.isEmpty ? '—' : v, style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(net.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row('IP base', net.baseIp),
            row('Ubicación', net.ubicacion),
            row('Estado', net.estado),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Future<void> _editInfo(NetworkGroup net) async {
    final name = TextEditingController(text: net.name);
    final ubicacion = TextEditingController(text: net.ubicacion);
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar edificio'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) =>
                    Validators.text(v, campo: 'El nombre', min: 2, max: 60) ??
                    (networks.any((n) => n.id != net.id && Validators.duplicated(v!, [n.name]))
                        ? 'Ya existe un edificio con ese nombre'
                        : null),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ubicacion,
                decoration: const InputDecoration(labelText: 'Ubicación (opcional)'),
                validator: (v) => Validators.optional(v, campo: 'La ubicación', max: 80),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('IP base: ${net.baseIp} (no editable)', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              ),
            ],
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
    );
    if (saved != true) return;
    final anterior = net.name;
    net.name = name.text.trim();
    net.ubicacion = ubicacion.text.trim();
    await _run(
      () => dbHelper.updateNetwork(
        net,
        detalle: anterior == net.name
            ? 'Se actualizó la información del edificio "${net.name}"'
            : 'El edificio "$anterior" ahora se llama "${net.name}"',
      ),
      'Edificio actualizado',
    );
  }

  Future<void> _changeColor(NetworkGroup net) async {
    final picked = await showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color del edificio'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kNetworkColors.map((color) {
            final selected = color.toARGB32() == net.colorValue;
            return GestureDetector(
              onTap: () => Navigator.pop(context, color),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: color,
                child: selected ? const Icon(Icons.check, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar'))],
      ),
    );
    if (picked == null || picked.toARGB32() == net.colorValue) return;
    net.colorValue = picked.toARGB32();
    await _run(() => dbHelper.updateNetwork(net, detalle: 'Se cambió el color del edificio "${net.name}"'), 'Color actualizado');
  }
}

class _BuildingRow extends StatelessWidget {
  final NetworkGroup net;
  final int switches, vlans;
  final bool isAdmin;
  final VoidCallback onTap;
  final ValueChanged<String> onMenu;

  const _BuildingRow({
    required this.net,
    required this.switches,
    required this.vlans,
    required this.isAdmin,
    required this.onTap,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final base = accessibleColor(Color(net.colorValue));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // El bloque de color con la inicial identifica al edificio.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      net.name.isEmpty ? '?' : net.name.characters.first.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 0, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          net.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 3),
                        Text(net.baseIp, style: AppText.mono(size: 13, color: AppColors.inkMuted)),
                        const SizedBox(height: 9),
                        Wrap(
                          spacing: 14,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            EstadoChip(net.estado),
                            Text(
                              '$switches ${switches == 1 ? 'switch' : 'switches'}',
                              style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                            ),
                            Text('$vlans VLAN', style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.inkMuted),
                  onSelected: onMenu,
                  itemBuilder: (context) => [
                    if (isAdmin) ...[
                      _item('edit', Icons.edit_outlined, 'Editar información'),
                      _item('estado', Icons.flag_outlined, 'Cambiar estado'),
                      _item('color', Icons.palette_outlined, 'Cambiar color'),
                    ] else
                      _item('info', Icons.info_outline, 'Consultar información'),
                    _item('history', Icons.history, 'Ver historial'),
                    if (isAdmin) _item('delete', Icons.delete_outline, 'Eliminar edificio', danger: true),
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
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
