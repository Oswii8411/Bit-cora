import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/validators.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:bitacora_red/models/net_port.dart';
import 'package:bitacora_red/models/net_switch.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/incidencia_dialogs.dart';
import 'package:flutter/material.dart';

/// Puertos de un switch.
///  - Administrador: agrega, edita, cambia estado, restablece y elimina puertos.
///  - Técnico: consulta y cambia el estado.
class PortsScreen extends StatefulWidget {
  final NetSwitch switchDevice;
  final NetworkGroup? network;
  const PortsScreen({super.key, required this.switchDevice, this.network});

  @override
  State<PortsScreen> createState() => _PortsScreenState();
}

class _PortsScreenState extends State<PortsScreen> {
  final dbHelper = DatabaseHelper();
  List<NetPort> ports = [];
  List<Subnet> vlans = [];
  bool loading = true;

  NetSwitch get sw => widget.switchDevice;
  bool get isAdmin => AppSession.isAdmin;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final p = await dbHelper.getPortsBySwitch(sw.id);
      final v = await dbHelper.getSubnetsByNetwork(sw.networkId);
      if (mounted) {
        setState(() {
          ports = p;
          vlans = v;
        });
      }
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudieron cargar los puertos: $e', error: true);
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

  String _vlanName(String? id) {
    if (id == null) return 'Sin VLAN';
    for (final v in vlans) {
      if (v.id == id) return v.label;
    }
    return 'Sin VLAN';
  }

  @override
  Widget build(BuildContext context) {
    final libres = ports.where((p) => p.estado == 'Disponible').length;
    final atencion = ports.where((p) => p.estado == 'Con incidencia').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(sw.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial del switch',
            onPressed: () => showHistorialDialog(context, titulo: sw.name, entityId: sw.id),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar puerto'),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      _Resumen(label: 'Puertos', valor: '${ports.length}'),
                      _Resumen(label: 'Disponibles', valor: '$libres'),
                      _Resumen(label: 'Con incidencia', valor: '$atencion'),
                      Expanded(child: Align(alignment: Alignment.centerRight, child: EstadoChip(sw.estado))),
                    ],
                  ),
                ),
                Expanded(
                  child: ports.isEmpty
                      ? const EmptyState(icon: Icons.settings_ethernet, title: 'Este switch no tiene puertos')
                      : ResponsiveList(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                          itemCount: ports.length,
                          itemBuilder: (context, index) => _portTile(ports[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _portTile(NetPort port) {
    final color = AppColors.tint(estadoColor(port.estado));
    final alerta = port.estado == 'Con incidencia';
    final detalle = [
      _vlanName(port.subnetId),
      if (port.departamento.isNotEmpty) port.departamento,
      if (port.observaciones.isNotEmpty) port.observaciones,
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isAdmin
              ? () => _showForm(existing: port)
              : (alerta ? () => _resolveIncident(port) : () => _onMenu('estado', port)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 2, 9),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: alerta ? AppColors.accent : AppColors.border, width: alerta ? 1.6 : 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${port.number}', style: AppText.mono(size: 14, weight: FontWeight.w700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 7),
                          Text(port.estado, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(detalle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
                if (alerta)
                  TextButton(
                    onPressed: () => _resolveIncident(port),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accentText,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text('Resolver'),
                  ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.inkMuted),
                  onSelected: (value) => _onMenu(value, port),
                  itemBuilder: (context) => [
                    if (alerta)
                      _item('resolver', Icons.check_circle_outline, 'Resolver incidencia')
                    else
                      _item('reportar', Icons.report_problem_outlined, 'Reportar incidencia'),
                    if (isAdmin) _item('edit', Icons.edit_outlined, 'Editar información'),
                    _item('estado', Icons.flag_outlined, 'Cambiar estado'),
                    if (isAdmin) _item('reset', Icons.restart_alt, 'Restablecer'),
                    _item('history', Icons.history, 'Ver historial'),
                    if (isAdmin) _item('delete', Icons.delete_outline, 'Eliminar puerto', danger: true),
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

  Future<void> _onMenu(String value, NetPort port) async {
    switch (value) {
      case 'edit':
        await _showForm(existing: port);
      case 'estado':
        final nuevo = await pickEstado(
          context,
          titulo: 'Estado del puerto ${port.number}',
          opciones: kEstadosPuerto,
          actual: port.estado,
        );
        if (nuevo == null || nuevo == port.estado) return;
        // Entrar o salir de "Con incidencia" pasa por reportar o resolver, para que
        // quede registrado qué falló y cómo se arregló.
        if (nuevo == 'Con incidencia') {
          await _reportIncident(port);
          return;
        }
        if (port.estado == 'Con incidencia') {
          await _resolveIncident(port, estadoInicial: nuevo);
          return;
        }
        final anterior = port.estado;
        port.estado = nuevo;
        await _run(
          () => dbHelper.updatePort(
            port,
            sw.name,
            detalle: 'El puerto ${port.number} de "${sw.name}" cambió de "$anterior" a "$nuevo"',
          ),
          'Estado actualizado',
        );
      case 'resolver':
        await _resolveIncident(port);
      case 'reportar':
        await _reportIncident(port);
      case 'reset':
        final ok = await confirmar(
          context,
          titulo: 'Restablecer puerto ${port.number}',
          mensaje: 'Quedará disponible y sin VLAN, departamento ni observaciones. ¿Continuar?',
          accion: 'Restablecer',
        );
        if (ok) await _run(() => dbHelper.resetPort(port, sw.name), 'Puerto restablecido');
      case 'history':
        await showHistorialDialog(context, titulo: 'Puerto ${port.number}', entityId: port.id);
      case 'delete':
        final ok = await confirmar(
          context,
          titulo: 'Eliminar puerto ${port.number}',
          mensaje: 'Se eliminará el puerto ${port.number} de "${sw.name}". ¿Continuar?',
        );
        if (ok) await _run(() => dbHelper.deletePort(port, sw.name), 'Puerto eliminado');
    }
  }

  Future<void> _reportIncident(NetPort port, {String inicial = ''}) async {
    final res = await showReportIncidentDialog(
      context,
      titulo: '${sw.name} · Puerto ${port.number}',
      inicial: inicial,
    );
    if (res == null) return;
    await _run(
      () => dbHelper.reportPortIncident(
        port: port,
        switchName: sw.name,
        descripcion: res.descripcion,
        prioridad: res.prioridad,
      ),
      'Incidencia reportada',
    );
  }

  Future<void> _resolveIncident(NetPort port, {String estadoInicial = 'Disponible'}) async {
    final res = await showResolveIncidentDialog(
      context,
      titulo: '${sw.name} · Puerto ${port.number}',
      estadoInicial: estadoInicial,
    );
    if (res == null) return;
    await _run(
      () => dbHelper.resolvePortIncident(
        port: port,
        switchName: sw.name,
        solucion: res.solucion,
        estadoFinal: res.estadoFinal,
      ),
      'Incidencia resuelta',
    );
  }

  /// Formulario de puerto: número, segmentación de red, VLAN, departamento,
  /// estado y observaciones.
  Future<void> _showForm({NetPort? existing}) async {
    final usados = ports.map((p) => p.number).toSet();
    final sugerido = ports.isEmpty ? 1 : ports.map((p) => p.number).reduce((a, b) => a > b ? a : b) + 1;

    final formKey = GlobalKey<FormState>();
    final number = TextEditingController(text: '${existing?.number ?? sugerido}');
    final vlanText = TextEditingController(text: existing?.vlan ?? '');
    final departamento = TextEditingController(text: existing?.departamento ?? '');
    final observaciones = TextEditingController(text: existing?.observaciones ?? '');
    String estado = existing?.estado ?? 'Disponible';
    String? subnetId = vlans.any((v) => v.id == existing?.subnetId) ? existing?.subnetId : null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Nuevo puerto' : 'Puerto ${existing.number}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: number,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Número de puerto'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Número no válido';
                      if (usados.contains(n) && n != existing?.number) return 'Ese puerto ya existe';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: subnetId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Segmentación de red'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Sin segmento')),
                      ...vlans.map((v) => DropdownMenuItem<String?>(
                            value: v.id,
                            child: Text('${v.name} (${v.baseIp})', overflow: TextOverflow.ellipsis),
                          )),
                    ],
                    onChanged: (v) => setLocal(() {
                      subnetId = v;
                      // Sugiere el número de VLAN del segmento elegido.
                      final match = vlans.where((x) => x.id == v);
                      if (match.isNotEmpty && match.first.vlanNumber != null && vlanText.text.trim().isEmpty) {
                        vlanText.text = '${match.first.vlanNumber}';
                      }
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: vlanText,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'VLAN (número)'),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      final n = int.tryParse(t);
                      return (n == null || n < 1 || n > 4094) ? 'Entre 1 y 4094' : null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: departamento,
                    decoration: const InputDecoration(labelText: 'Departamento'),
                    validator: (v) => Validators.optional(v, campo: 'El departamento', max: 60),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: kEstadosPuerto.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setLocal(() => estado = v ?? estado),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: observaciones,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Observaciones'),
                    validator: (v) => Validators.optional(v, campo: 'Las observaciones', max: 200),
                  ),
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

    if (saved != true) return;
    final n = int.parse(number.text);
    final conIncidencia = estado == 'Con incidencia';
    if (existing == null) {
      final port = NetPort(
        id: '${sw.id}p$n-${DateTime.now().millisecondsSinceEpoch}',
        switchId: sw.id,
        number: n,
        subnetId: subnetId,
        vlan: vlanText.text.trim(),
        departamento: departamento.text.trim(),
        observaciones: observaciones.text.trim(),
        // Un puerto nuevo "con incidencia" se crea disponible y luego se reporta.
        estado: conIncidencia ? 'Disponible' : estado,
      );
      await _run(() => dbHelper.insertPort(port, sw.name), 'Puerto $n agregado');
      if (conIncidencia && mounted) await _reportIncident(port, inicial: observaciones.text.trim());
    } else {
      final estabaConIncidencia = existing.estado == 'Con incidencia';
      existing
        ..number = n
        ..subnetId = subnetId
        ..vlan = vlanText.text.trim()
        ..departamento = departamento.text.trim()
        ..observaciones = observaciones.text.trim()
        // Entrar o salir de "Con incidencia" se hace después, con su propio diálogo.
        ..estado = (conIncidencia != estabaConIncidencia) ? existing.estado : estado;
      await _run(() => dbHelper.updatePort(existing, sw.name), 'Puerto actualizado');
      if (!estabaConIncidencia && conIncidencia && mounted) {
        await _reportIncident(existing, inicial: observaciones.text.trim());
      } else if (estabaConIncidencia && !conIncidencia && mounted) {
        await _resolveIncident(existing, estadoInicial: estado);
      }
    }
  }
}

class _Resumen extends StatelessWidget {
  final String label, valor;
  const _Resumen({required this.label, required this.valor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
