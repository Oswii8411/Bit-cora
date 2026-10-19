import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:bitacora_red/models/history_log.dart';
import 'package:bitacora_red/models/incidencia.dart';
import 'package:bitacora_red/views/formulario_incidencia.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Bitácora: movimientos del sistema (quién, qué, cuándo) e incidencias.
///  - Administrador: ve todos los movimientos y puede filtrar por usuario.
///  - Técnico: solo ve sus propios movimientos.
class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({super.key});

  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> with SingleTickerProviderStateMixin {
  final db = DatabaseHelper();
  late final TabController _tabs;

  List<HistoryLog> logs = [];
  List<Incidencia> incidencias = [];
  bool loading = true;

  // Filtros
  String query = '';
  String? fUser; // texto de userLabel
  String? fModule; // valor de BD
  String? fAction;
  DateTimeRange? fRange;

  bool get isAdmin => AppSession.isAdmin;
  int get activeFilters => [fUser, fModule, fAction, fRange].where((e) => e != null).length;

  @override
  void initState() {
    super.initState();
    DatabaseHelper().changes.addListener(_onDataChanged);
    _tabs = TabController(length: 2, vsync: this)..addListener(() => setState(() {}));
    _load();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    DatabaseHelper().changes.removeListener(_onDataChanged);
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Solo la primera carga muestra el círculo; las demás actualizan en silencio.
    if (logs.isEmpty && incidencias.isEmpty) setState(() => loading = true);
    try {
      final l = await db.getHistoryLogs(userId: isAdmin ? null : AppSession.profile?.id);
      final i = await db.getIncidencias();
      if (mounted) {
        setState(() {
          logs = l;
          incidencias = i;
        });
      }
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo cargar la bitácora: $e', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  List<HistoryLog> get _filtered {
    final q = query.trim().toLowerCase();
    return logs.where((l) {
      if (fUser != null && l.userLabel != fUser) return false;
      if (fModule != null && l.entityType != fModule) return false;
      if (fAction != null && l.actionType != fAction) return false;
      if (fRange != null && l.createdAt != null) {
        final end = fRange!.end.add(const Duration(days: 1));
        if (l.createdAt!.isBefore(fRange!.start) || !l.createdAt!.isBefore(end)) return false;
      }
      if (q.isNotEmpty && !('${l.description} ${l.userLabel}'.toLowerCase().contains(q))) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bitácora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              DatabaseHelper().invalidateCache();
              _load();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Movimientos'),
            Tab(icon: Icon(Icons.report_problem_outlined), text: 'Incidencias'),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [_movimientos(), _incidencias()],
            ),
      floatingActionButton: _tabs.index == 1
          ? FloatingActionButton.extended(
              heroTag: null,
              icon: const Icon(Icons.add),
              label: const Text('Reportar'),
              onPressed: () async {
                final recargar = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FormularioIncidencia()),
                );
                if (recargar == true) _load();
              },
            )
          : null,
    );
  }

  // ------------------------------------------------------------------ Movimientos
  Widget _movimientos() {
    final list = _filtered;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Buscar en la bitácora', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => query = v),
                ),
              ),
              const SizedBox(width: 10),
              Badge(
                isLabelVisible: activeFilters > 0,
                label: Text('$activeFilters'),
                child: IconButton.filledTonal(
                  tooltip: 'Filtros',
                  icon: const Icon(Icons.filter_list),
                  onPressed: _openFilters,
                ),
              ),
            ],
          ),
        ),
        if (activeFilters > 0)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (fUser != null) _chip('Usuario: $fUser', () => setState(() => fUser = null)),
                if (fModule != null) _chip('Módulo: ${kModulosBitacora[fModule] ?? fModule}', () => setState(() => fModule = null)),
                if (fAction != null) _chip('Acción: ${_accionLabel(fAction!)}', () => setState(() => fAction = null)),
                if (fRange != null)
                  _chip(
                    '${DateFormat('dd/MM').format(fRange!.start)} – ${DateFormat('dd/MM/yy').format(fRange!.end)}',
                    () => setState(() => fRange = null),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${list.length} ${list.length == 1 ? 'movimiento' : 'movimientos'}${isAdmin ? '' : ' tuyos'}',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
        ),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(icon: Icons.menu_book_outlined, title: 'No hay movimientos con esos filtros')
              : RefreshIndicator(
                  onRefresh: () {
            DatabaseHelper().invalidateCache();
            return _load();
          },
                  child: ResponsiveList(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: list.length,
                    itemBuilder: (context, i) => i < 12 ? FadeSlideIn(index: i, child: _logTile(list[i])) : _logTile(list[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(String text, VoidCallback onDelete) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Chip(
          label: Text(text, style: const TextStyle(fontSize: 12)),
          onDeleted: onDelete,
          visualDensity: VisualDensity.compact,
          side: BorderSide(color: AppColors.border),
          backgroundColor: AppColors.surface,
        ),
      );

  String _accionLabel(String a) => switch (a) {
        'CREAR' => 'Crear',
        'EDITAR' => 'Editar',
        'ELIMINAR' => 'Eliminar',
        'INICIO' => 'Inicio de sesión',
        'CIERRE' => 'Cierre de sesión',
        'GENERAR' => 'Generar reporte',
        _ => a,
      };

  (IconData, Color) _accionStyle(String a) => switch (a) {
        'CREAR' => (Icons.add_circle, const Color(0xFF15803D)),
        'EDITAR' => (Icons.edit_note, const Color(0xFFB45309)),
        'ELIMINAR' => (Icons.delete_forever, AppColors.error),
        'INICIO' => (Icons.login, AppColors.palette3),
        'CIERRE' => (Icons.logout, AppColors.inkMuted),
        'GENERAR' => (Icons.picture_as_pdf, const Color(0xFF1D4ED8)),
        _ => (Icons.info, AppColors.primary),
      };

  Widget _logTile(HistoryLog log) {
    final (icon, rawColor) = _accionStyle(log.actionType);
    final color = AppColors.tint(rawColor);
    final fecha = log.createdAt != null ? DateFormat('dd/MM/yyyy · HH:mm').format(log.createdAt!) : '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.actionType == 'INICIO' || log.actionType == 'CIERRE'
                        ? '${_accionLabel(log.actionType)}: ${log.userLabel}'
                        : log.description,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.actionType == 'INICIO' || log.actionType == 'CIERRE'
                        ? fecha
                        : '${log.userLabel} · $fecha',
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kModulosBitacora[log.entityType] ?? log.entityType,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final users = logs.map((l) => l.userLabel).toSet().toList()..sort();
    String? user = fUser, module = fModule, action = fAction;
    DateTimeRange? range = fRange;

    final apply = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filtrar bitácora', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 16),
                if (isAdmin) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: user,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Usuario'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                      ...users.map((u) => DropdownMenuItem<String?>(value: u, child: Text(u, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setLocal(() => user = v),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String?>(
                  initialValue: module,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Módulo'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todos')),
                    ...kModulosBitacora.entries.map((e) => DropdownMenuItem<String?>(value: e.key, child: Text(e.value))),
                  ],
                  onChanged: (v) => setLocal(() => module = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: action,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Acción'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
                    ...kAccionesBitacora.map((a) => DropdownMenuItem<String?>(value: a, child: Text(_accionLabel(a)))),
                  ],
                  onChanged: (v) => setLocal(() => action = v),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.date_range),
                  label: Text(range == null
                      ? 'Rango de fechas'
                      : '${DateFormat('dd/MM/yyyy').format(range!.start)} – ${DateFormat('dd/MM/yyyy').format(range!.end)}'),
                  onPressed: () async {
                    final r = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      initialDateRange: range,
                      locale: const Locale('es'),
                    );
                    if (r != null) setLocal(() => range = r);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setLocal(() {
                          user = null;
                          module = null;
                          action = null;
                          range = null;
                        }),
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aplicar')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (apply == true) {
      setState(() {
        fUser = user;
        fModule = module;
        fAction = action;
        fRange = range;
      });
    }
  }

  // ------------------------------------------------------------------ Incidencias
  /// Quién resolvió la incidencia, cuándo y cómo.
  Widget _resolvedBlock(Incidencia item) {
    final ok = AppColors.tint(const Color(0xFF15803D));
    final quien = item.resueltoPor ?? item.responsable;
    final cuando = item.resueltoEn != null ? DateFormat('dd/MM/yyyy HH:mm').format(item.resueltoEn!) : '';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok.withValues(alpha: 0.10),
        border: Border.all(color: ok.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: ok),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Resuelta por $quien', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
          if (cuando.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 26, top: 2),
              child: Text(cuando, style: AppText.mono(size: 12, color: AppColors.inkMuted)),
            ),
          const SizedBox(height: 8),
          Text(item.solucion, style: const TextStyle(fontSize: 14.5)),
        ],
      ),
    );
  }

  Widget _incidencias() {
    if (incidencias.isEmpty) {
      return const EmptyState(
        icon: Icons.report_problem_outlined,
        title: 'No hay incidencias registradas',
        hint: 'Toca "Reportar" para registrar una.',
      );
    }

    return RefreshIndicator(
      onRefresh: () {
            DatabaseHelper().invalidateCache();
            return _load();
          },
      child: ResponsiveList(
        padding: const EdgeInsets.all(16).copyWith(bottom: 90),
        itemCount: incidencias.length,
        itemBuilder: (context, index) {
          final item = incidencias[index];
          final fecha = item.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!) : 'Sin fecha';

          Color colorEstado = const Color(0xFFB45309); // Pendiente
          if (item.estado == 'Resuelto') colorEstado = const Color(0xFF15803D);
          if (item.estado == 'En revisión') colorEstado = const Color(0xFF1D4ED8);
          Color colorPrioridad = AppColors.inkMuted;
          if (item.prioridad == 'Alta') colorPrioridad = AppColors.error;
          if (item.prioridad == 'Media') colorPrioridad = const Color(0xFFB45309);
          if (item.prioridad == 'Baja') colorPrioridad = AppColors.palette3;

          return FadeSlideIn(
            index: index,
            child: Pressable(
              onTap: () async {
                final recargar = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FormularioIncidencia(incidenciaActual: item)),
                );
                if (recargar == true) _load();
              },
              child: Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.dispositivoNombre,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: colorEstado.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item.estado,
                              style: TextStyle(
                                color: AppColors.isDark ? Color.lerp(colorEstado, Colors.white, 0.45) : colorEstado,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.flag_rounded, size: 15, color: colorPrioridad),
                          const SizedBox(width: 4),
                          Text('Prioridad ${item.prioridad}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorPrioridad)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Falla: ${item.descripcion}', style: const TextStyle(fontSize: 15)),
                      if (item.resuelta && item.solucion.isNotEmpty)
                        _resolvedBlock(item)
                      else
                        Text('Acción: ${item.accionRealizada}', style: TextStyle(fontSize: 15, color: AppColors.inkMuted)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              children: [
                                Icon(Icons.person, size: 16, color: AppColors.palette3),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(item.responsable,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          Text(fecha, style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
