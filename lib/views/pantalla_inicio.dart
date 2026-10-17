import 'dart:math' as math;

import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/history_log.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Inicio: primero lo que requiere atención, después el estado de la red en
/// gráficas (puertos operativos, puertos por edificio y cambios de la semana).
class InicioScreen extends StatefulWidget {
  final void Function(String key) onGoTo;
  const InicioScreen({super.key, required this.onGoTo});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final db = DatabaseHelper();
  DashboardStats? stats;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await db.getDashboardStats();
      if (!mounted) return;
      setState(() {
        stats = s;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = 'No se pudo cargar el resumen.\n$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppSession.profile!;
    final s = stats;
    final fecha = toBeginningOfSentenceCase(DateFormat("EEEE d 'de' MMMM", 'es').format(DateTime.now()));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${p.nombre.isEmpty ? p.email.split('@').first : p.nombre}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                        ),
                        const SizedBox(height: 2),
                        Text(fecha, style: TextStyle(color: AppColors.inkMuted)),
                      ],
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(top: 6), child: Tag(p.roleLabel, color: AppColors.primary)),
                ],
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState(icon: Icons.cloud_off, title: 'Sin conexión', hint: error),
                )
              else if (s == null)
                const Padding(padding: EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator()))
              else
                ..._body(s),
            ],
          ),
        ),
      ),
    );
  }

  /// Una columna en celular; dos en pantallas anchas.
  List<Widget> _body(DashboardStats s) {
    final (left, right) = _content(s);
    if (!isWide(context)) return [...left, ...right];
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
          const SizedBox(width: 26),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
        ],
      ),
    ];
  }

  (List<Widget>, List<Widget>) _content(DashboardStats s) {
    final admin = AppSession.isAdmin;

    // Cada elemento: (texto, destino)
    final attention = <(String, String)>[
      if (admin && s.pendingUsers > 0)
        (s.pendingUsers == 1 ? '1 solicitud de acceso por aprobar' : '${s.pendingUsers} solicitudes de acceso por aprobar', 'usuarios'),
      if (s.portsIncident > 0)
        (s.portsIncident == 1 ? '1 puerto con incidencia' : '${s.portsIncident} puertos con incidencia', 'switches'),
      if (s.pendingIncidents > 0)
        (s.pendingIncidents == 1 ? '1 incidencia sin resolver' : '${s.pendingIncidents} incidencias sin resolver', 'bitacora'),
      if (s.degradedInfra > 0)
        (s.degradedInfra == 1 ? '1 edificio o switch fuera de operación normal' : '${s.degradedInfra} edificios o switches fuera de operación normal', 'edificios'),
    ];

    final left = <Widget>[
      const SectionLabel('Requiere atención'),
      _Panel(
        children: attention.isEmpty
            ? [
                _AttentionRow(
                  color: AppColors.tint(const Color(0xFF15803D)),
                  text: 'Todo en orden. No hay pendientes.',
                  muted: true,
                ),
              ]
            : [
                for (final (text, to) in attention)
                  _AttentionRow(color: AppColors.accent, text: text, onTap: () => widget.onGoTo(to)),
              ],
      ),
      const SectionLabel('Estado de la red'),
      _NetworkCard(s: s, admin: admin),
      if (s.portsByBuilding.isNotEmpty) ...[
        const SectionLabel('Puertos por edificio'),
        _BarsCard(entries: s.portsByBuilding.take(5).toList()),
      ],
    ];

    final right = <Widget>[
      SectionLabel(admin ? 'Cambios de la semana' : 'Mi actividad de la semana'),
      _WeekCard(counts: s.changesWeek, days: s.weekDays),
      SectionLabel(
        admin ? 'Actividad reciente' : 'Mis últimos movimientos',
        trailing: TextButton(
          onPressed: () => widget.onGoTo('bitacora'),
          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
          child: const Text('Ver bitácora'),
        ),
      ),
      _Activity(logs: s.recentActivity, showUser: admin),
    ];

    return (left, right);
  }
}

/// Contenedor de filas con bordes finos.
class _Panel extends StatelessWidget {
  final List<Widget> children;
  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: AppColors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Tarjeta con borde fino y relleno estándar para las gráficas.
class _ChartCard extends StatelessWidget {
  final Widget child;
  const _ChartCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppTheme.radius + 2),
      ),
      child: child,
    );
  }
}

class _AttentionRow extends StatelessWidget {
  final Color color;
  final String text;
  final bool muted;
  final VoidCallback? onTap;
  const _AttentionRow({required this.color, required this.text, this.onTap, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontWeight: muted ? FontWeight.w500 : FontWeight.w600, color: muted ? AppColors.inkMuted : AppColors.ink),
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, size: 20, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}

/// Dona de puertos operativos y los totales de infraestructura.
class _NetworkCard extends StatelessWidget {
  final DashboardStats s;
  final bool admin;
  const _NetworkCard({required this.s, required this.admin});

  @override
  Widget build(BuildContext context) {
    final pct = s.portsTotal == 0 ? 0.0 : s.portsOperational / s.portsTotal;

    Widget metric(String value, String label) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: AppText.mono(size: 20, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            ],
          ),
        );

    return _ChartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 92,
                height: 92,
                child: CustomPaint(
                  painter: _DonutPainter(value: pct, color: AppColors.chart2, track: AppColors.border),
                  child: Center(
                    child: Text(
                      s.portsTotal == 0 ? '-' : '${(pct * 100).round()}%',
                      style: AppText.mono(size: 18, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Puertos operativos', style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${s.portsOperational}', style: AppText.mono(size: 30, weight: FontWeight.w700)),
                        Text(' de ${s.portsTotal}', style: AppText.mono(size: 15, color: AppColors.inkMuted)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.portsIncident == 0
                          ? (s.portsTotal == 0 ? 'Aún no hay puertos registrados' : 'Sin incidencias')
                          : (s.portsIncident == 1 ? '1 con incidencia' : '${s.portsIncident} con incidencia'),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: s.portsIncident == 0 ? AppColors.inkMuted : AppColors.accentText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
          Row(
            children: [
              metric('${s.buildings}', 'Edificios'),
              metric('${s.switches}', 'Switches'),
              metric('${s.vlansActive}', s.vlansActive == s.vlansTotal ? 'VLAN activas' : 'VLAN de ${s.vlansTotal}'),
              if (admin) metric('${s.users}', 'Usuarios') else metric('${s.portsTotal}', 'Puertos'),
            ],
          ),
          if (admin) ...[
            const SizedBox(height: 14),
            Row(children: [metric('${s.changes}', 'Cambios registrados'), const Spacer(flex: 3)]),
          ],
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final double value;
  final Color color, track;
  _DonutPainter({required this.value, required this.color, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (value <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value.clamp(0.0, 1.0), false, arc);
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.value != value || old.color != color || old.track != track;
}

/// Barras horizontales: una por edificio.
class _BarsCard extends StatelessWidget {
  final List<MapEntry<String, int>> entries;
  const _BarsCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final max = entries.map((e) => e.value).fold<int>(1, math.max);
    final colors = [AppColors.chart1, AppColors.chart2, AppColors.chart3];

    return _ChartCard(
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == entries.length - 1 ? 0 : 11),
              child: Row(
                children: [
                  SizedBox(
                    width: 82,
                    child: Text(entries[i].key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(height: 10, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(5))),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                            height: 10,
                            width: c.maxWidth * entries[i].value / max,
                            decoration: BoxDecoration(color: colors[i % colors.length], borderRadius: BorderRadius.circular(5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 34,
                    child: Text('${entries[i].value}', textAlign: TextAlign.right, style: AppText.mono(size: 13, weight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Movimientos de los últimos 7 días.
class _WeekCard extends StatelessWidget {
  final List<int> counts;
  final List<DateTime> days;
  const _WeekCard({required this.counts, required this.days});

  @override
  Widget build(BuildContext context) {
    final max = counts.fold<int>(1, math.max);
    final total = counts.fold<int>(0, (a, b) => a + b);
    const chartHeight = 78.0;

    return _ChartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            total == 0 ? 'Sin movimientos en los últimos 7 días' : '$total ${total == 1 ? 'movimiento' : 'movimientos'} en 7 días',
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight + 52,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < counts.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          counts[i] == 0 ? '' : '${counts[i]}',
                          style: AppText.mono(size: 11, weight: FontWeight.w700, color: i == counts.length - 1 ? AppColors.ink : AppColors.inkMuted),
                        ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: math.max(4, chartHeight * counts[i] / max),
                          decoration: BoxDecoration(
                            color: i == counts.length - 1 ? AppColors.chart1 : AppColors.chart3,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          i < days.length ? DateFormat('E', 'es').format(days[i]).substring(0, 1).toUpperCase() : '',
                          style: TextStyle(fontSize: 11.5, color: i == counts.length - 1 ? AppColors.ink : AppColors.inkMuted, fontWeight: i == counts.length - 1 ? FontWeight.w700 : FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Activity extends StatelessWidget {
  final List<HistoryLog> logs;
  final bool showUser;
  const _Activity({required this.logs, required this.showUser});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _Panel(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Text('Todavía no hay movimientos.', style: TextStyle(color: AppColors.inkMuted)),
        ),
      ]);
    }
    return _Panel(children: [
      for (final log in logs)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 54,
                child: Text(
                  log.createdAt != null ? DateFormat('dd/MM\nHH:mm').format(log.createdAt!) : '',
                  style: AppText.mono(size: 11.5, color: AppColors.inkMuted),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    if (showUser)
                      Text(log.userLabel, style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
    ]);
  }
}
