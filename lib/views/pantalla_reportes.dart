import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/controllers/report_service.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reportes en PDF (solo administrador).
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final service = ReportService();
  final db = DatabaseHelper();
  String? generating; // clave del reporte en curso

  Future<void> _generate(String key, Future<void> Function() action) async {
    setState(() => generating = key);
    try {
      await action();
      if (mounted) showMsg(context, 'Reporte generado');
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo generar el reporte: $e', error: true);
    } finally {
      if (mounted) setState(() => generating = null);
    }
  }

  Future<NetworkGroup?> _pickNetwork({required bool allowAll}) async {
    final nets = await db.getNetworks();
    if (!mounted) return null;
    if (nets.isEmpty) {
      showMsg(context, 'Aún no hay edificios registrados.', error: true);
      return null;
    }
    // Para "todos" se devuelve un edificio vacío especial.
    final all = NetworkGroup(id: '', name: 'Todos los edificios', baseIp: '', colorValue: 0);
    return showDialog<NetworkGroup>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Elige un edificio'),
        children: [
          if (allowAll)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, all),
              child: const Text('Todos los edificios', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          for (final n in nets)
            SimpleDialogOption(onPressed: () => Navigator.pop(context, n), child: Text(n.name)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reports = <_Report>[
      _Report(
        'infra',
        Icons.apartment,
        'Infraestructura de un edificio',
        'Datos del edificio, sus switches con puertos operativos y sus VLAN.',
        () async {
          final net = await _pickNetwork(allowAll: false);
          if (net != null) await _generate('infra', () => service.infraestructura(net));
        },
      ),
      _Report(
        'bitacora',
        Icons.menu_book,
        'Bitácora',
        'Todos los movimientos: quién, qué y cuándo. Puedes limitarlo a un periodo.',
        () async {
          final range = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2024),
            lastDate: DateTime.now().add(const Duration(days: 1)),
            helpText: 'Periodo (cancela para incluir todo)',
          );
          await _generate('bitacora', () => service.bitacora(range: range));
        },
      ),
      _Report(
        'incidencias',
        Icons.report_problem_outlined,
        'Incidencias',
        'Fallas reportadas con su prioridad, estado y responsable.',
        () => _generate('incidencias', service.incidencias),
      ),
      _Report(
        'usuarios',
        Icons.group,
        'Usuarios',
        'Lista de usuarios con su rol, estado y área.',
        () => _generate('usuarios', service.usuarios),
      ),
      _Report(
        'segmentacion',
        Icons.lan,
        'Segmentación de red',
        'VLAN con máscara, ruteador, rangos y hosts usables.',
        () async {
          final net = await _pickNetwork(allowAll: true);
          if (net != null) await _generate('segmentacion', () => service.segmentacion(net: net.id.isEmpty ? null : net));
        },
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: Centered(maxWidth: 760, child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(
            'Genera un PDF para entregarlo o archivarlo. ${DateFormat("d 'de' MMMM yyyy", 'es').format(DateTime.now())}',
            style: TextStyle(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < reports.length; i++)
            FadeSlideIn(
              index: i,
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(reports[i].icon, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reports[i].title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text(reports[i].description, style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      generating == reports[i].key
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : FilledButton.tonalIcon(
                              onPressed: generating == null ? reports[i].onTap : null,
                              icon: const Icon(Icons.picture_as_pdf, size: 18),
                              label: const Text('PDF'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      )),
    );
  }
}

class _Report {
  final String key;
  final IconData icon;
  final String title, description;
  final Future<void> Function() onTap;
  _Report(this.key, this.icon, this.title, this.description, this.onTap);
}
