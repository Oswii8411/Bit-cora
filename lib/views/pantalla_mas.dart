import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/auth_controller.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/views/login_screen.dart';
import 'package:bitacora_red/views/pantalla_cuenta.dart';
import 'package:bitacora_red/views/pantalla_equipos.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:flutter/material.dart';

/// "Más": administración (solo admin), cuenta, herramientas y cerrar sesión.
class MasScreen extends StatefulWidget {
  final void Function(String key) onGoTo;
  const MasScreen({super.key, required this.onGoTo});

  @override
  State<MasScreen> createState() => _MasScreenState();
}

class _MasScreenState extends State<MasScreen> {
  int pending = 0;

  @override
  void initState() {
    super.initState();
    DatabaseHelper().changes.addListener(_onDataChanged);
    if (AppSession.isAdmin) _loadPending();
  }

  Future<void> _loadPending() async {
    try {
      final users = await DatabaseHelper().getProfiles();
      if (mounted) setState(() => pending = users.where((u) => u.isPending).length);
    } catch (_) {
      // El contador es solo informativo.
    }
  }

  void _onDataChanged() {
    if (mounted) _loadPending();
  }

  @override
  void dispose() {
    DatabaseHelper().changes.removeListener(_onDataChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Al cerrar sesión el perfil se borra un instante antes de salir de esta pantalla;
    // si se redibuja en ese momento no debe fallar.
    final profile = AppSession.profile;
    if (profile == null) return const SizedBox.shrink();
    final p = profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: Centered(maxWidth: 720, child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  p.fullName.substring(0, 1).toUpperCase(),
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text(p.email, style: AppText.mono(size: 12, color: AppColors.inkMuted)),
                  ],
                ),
              ),
              Tag(p.roleLabel, color: AppColors.primary),
            ],
          ),
          if (p.isAdmin) ...[
            const SectionLabel('Administración'),
            _Group(children: [
              _Row(
                icon: Icons.group_outlined,
                title: 'Usuarios',
                subtitle: 'Cuentas, solicitudes de acceso y roles',
                badge: pending > 0 ? '$pending' : null,
                onTap: () => widget.onGoTo('usuarios'),
              ),
              _Row(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Reportes',
                subtitle: 'Genera PDF de infraestructura, bitácora y más',
                onTap: () => widget.onGoTo('reportes'),
              ),
            ]),
          ],
          const SectionLabel('Cuenta'),
          _Group(children: [
            _Row(icon: Icons.person_outline, title: 'Perfil', subtitle: 'Tu información personal', onTap: () => _push(const PerfilScreen())),
            _Row(icon: Icons.lock_outline, title: 'Seguridad', subtitle: 'Correo y contraseña', onTap: () => _push(const SeguridadScreen())),
            _Row(icon: Icons.tune, title: 'Preferencias', subtitle: 'Tema y tiempo de protección de sesión', onTap: () => _push(const PreferenciasScreen())),
          ]),
          const SectionLabel('Herramientas'),
          _Group(children: [
            _Row(
              icon: Icons.devices_other_outlined,
              title: 'Inventario de equipos',
              subtitle: p.isAdmin ? 'Registra y administra los equipos' : 'Consulta los equipos de la red',
              onTap: () => _push(const DevicesScreen()),
            ),
            _Row(icon: Icons.info_outline, title: 'Acerca de', subtitle: 'Bitácora de Red 1.0.0', onTap: _about),
          ]),
          const SizedBox(height: 22),
          OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 19),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      )),
    );
  }

  Future<void> _push(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    if (AppSession.isAdmin) _loadPending();
  }

  Future<void> _logout() async {
    final ok = await confirmar(context, titulo: 'Cerrar sesión', mensaje: '¿Quieres salir de tu cuenta?', accion: 'Cerrar sesión');
    if (!ok || !mounted) return;
    await AuthController().signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _about() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bitácora de Red'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión 1.0.0', style: AppText.mono(size: 12.5, color: AppColors.inkMuted)),
            const SizedBox(height: 12),
            const Text(
              'Aplicación para administrar la infraestructura de red del Instituto Tecnológico Superior de Uruapan: '
              'edificios, switches, puertos, VLAN, equipos, incidencias y bitácora de movimientos.',
            ),
            const SizedBox(height: 12),
            Text('Hecha con Flutter y Supabase.', style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }
}

/// Grupo de filas dentro de un solo contenedor con bordes finos.
class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

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
            if (i > 0) Divider(height: 1, indent: 52, color: AppColors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final String? badge;
  final VoidCallback onTap;
  const _Row({required this.icon, required this.title, required this.subtitle, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(10)),
                child: Text(badge!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.onAccent)),
              ),
            Icon(Icons.chevron_right, size: 20, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
