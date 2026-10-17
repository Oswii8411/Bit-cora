import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/estados.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Estado de un edificio, switch, VLAN o puerto: un punto de color y el texto.
/// (Más sobrio que una pastilla y se lee igual de rápido.)
class EstadoChip extends StatelessWidget {
  final String estado;
  final bool onDark;
  const EstadoChip(this.estado, {super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final color = estadoColor(estado);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: onDark ? Colors.white : AppColors.tint(color),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          estado,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: onDark ? Colors.white : AppColors.ink,
          ),
        ),
      ],
    );
  }
}

/// Encabezado de sección en mayúsculas pequeñas.
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;
  const SectionLabel(this.text, {super.key, this.padding = const EdgeInsets.fromLTRB(0, 22, 0, 8), this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: AppText.overline())),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Etiqueta con borde fino (por ejemplo "VLAN 10", un rol).
class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final bool mono;
  const Tag(this.text, {super.key, this.color, this.mono = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: c.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: mono
            ? AppText.mono(size: 11.5, color: c, weight: FontWeight.w700)
            : TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

/// Número grande con su etiqueta (resumen). Plana, sin recuadros de ícono.
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.icon, required this.value, required this.label, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.inkMuted))),
                  Icon(icon, size: 17, color: AppColors.inkMuted),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: AppText.mono(size: 28, weight: FontWeight.w700, color: AppColors.tint(color ?? AppColors.ink))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado vacío: ícono, título y una línea de ayuda.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? hint;
  const EmptyState({super.key, required this.icon, required this.title, this.hint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.inkMuted.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
            if (hint != null) ...[
              const SizedBox(height: 4),
              Text(hint!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.inkMuted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Muestra una lista de estados y devuelve el elegido (o null si se cancela).
Future<String?> pickEstado(
  BuildContext context, {
  required String titulo,
  required List<String> opciones,
  required String actual,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(titulo),
      children: opciones.map((e) {
        return SimpleDialogOption(
          onPressed: () => Navigator.pop(context, e),
          child: Row(
            children: [
              Icon(
                e == actual ? Icons.radio_button_checked : Icons.radio_button_off,
                color: estadoColor(e),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(e, style: const TextStyle(fontSize: 16)),
            ],
          ),
        );
      }).toList(),
    ),
  );
}

/// Diálogo de confirmación para acciones destructivas. Devuelve true si se acepta.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String accion = 'Eliminar',
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: Text(accion),
        ),
      ],
    ),
  );
  return res ?? false;
}

/// Historial de acciones (tomado de la bitácora) de un elemento concreto.
Future<void> showHistorialDialog(
  BuildContext context, {
  required String titulo,
  required String entityId,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Historial · $titulo'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder(
          future: DatabaseHelper().getHistoryByEntity(entityId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text('No se pudo cargar el historial.\n${snapshot.error}');
            }
            final logs = snapshot.data ?? [];
            if (logs.isEmpty) {
              return const Text('Aún no hay movimientos registrados.');
            }
            return ListView.separated(
              shrinkWrap: true,
              itemCount: logs.length,
              separatorBuilder: (_, _) => const Divider(height: 16),
              itemBuilder: (context, i) {
                final log = logs[i];
                final fecha = log.createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(log.createdAt!) : '';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '$fecha · ${log.userLabel}',
                      style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

/// Pequeño aviso de resultado, usado por todas las pantallas.
void showMsg(BuildContext context, String text, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(text),
    backgroundColor: error ? AppColors.error : null,
  ));
}
