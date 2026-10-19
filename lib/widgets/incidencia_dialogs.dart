import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/validators.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:flutter/material.dart';

/// Pide la descripción de la falla al reportar una incidencia en un puerto.
/// Devuelve null si se cancela.
Future<({String descripcion, String prioridad})?> showReportIncidentDialog(
  BuildContext context, {
  required String titulo,
  String inicial = '',
}) {
  final formKey = GlobalKey<FormState>();
  final text = TextEditingController(text: inicial);
  var prioridad = 'Media';

  return showDialog<({String descripcion, String prioridad})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Reportar incidencia'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppText.mono(size: 12.5, color: AppColors.inkMuted)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: text,
                  autofocus: true,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: '¿Qué falla tiene?'),
                  validator: (v) => Validators.text(v, campo: 'La descripción', min: 5, max: 300),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: prioridad,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Prioridad'),
                  items: const ['Baja', 'Media', 'Alta'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setLocal(() => prioridad = v ?? prioridad),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, (descripcion: text.text.trim(), prioridad: prioridad));
            },
            child: const Text('Reportar'),
          ),
        ],
      ),
    ),
  );
}

/// Pide qué se hizo y cómo se resolvió la incidencia, y en qué estado queda el
/// puerto. Queda registrado a nombre de quien resuelve, con fecha y hora.
/// Devuelve null si se cancela.
Future<({String solucion, String estadoFinal})?> showResolveIncidentDialog(
  BuildContext context, {
  required String titulo,
  String estadoInicial = 'Disponible',
}) {
  final formKey = GlobalKey<FormState>();
  final text = TextEditingController();
  final opciones = kEstadosPuerto.where((e) => e != 'Con incidencia').toList();
  var estado = opciones.contains(estadoInicial) ? estadoInicial : 'Disponible';
  final quien = AppSession.profile?.fullName ?? 'ti';

  return showDialog<({String solucion, String estadoFinal})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setLocal) => AlertDialog(
        title: const Text('Resolver incidencia'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: AppText.mono(size: 12.5, color: AppColors.inkMuted)),
                const SizedBox(height: 14),
                TextFormField(
                  controller: text,
                  autofocus: true,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: '¿Qué se hizo y cómo se resolvió?',
                    hintText: 'Ej. Se cambió el cable de red y se probó la conexión',
                  ),
                  validator: (v) => Validators.text(v, campo: 'La solución', min: 10, max: 500),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: estado,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Estado del puerto al terminar'),
                  items: opciones.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setLocal(() => estado = v ?? estado),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.inkMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quedará registrado a nombre de $quien, con la fecha y la hora.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(context, (solucion: text.text.trim(), estadoFinal: estado));
            },
            child: const Text('Resolver'),
          ),
        ],
      ),
    ),
  );
}
