import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/profile.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:bitacora_red/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Gestión de usuarios (solo administrador): solicitudes de acceso, búsqueda
/// por nombre o correo y lista con su información.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final db = DatabaseHelper();
  List<Profile> users = [];
  bool loading = true;
  String query = '';
  String filtro = 'todos'; // todos | pendiente | activo | rechazado

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await db.getProfiles();
      if (mounted) setState(() => users = data);
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudieron cargar los usuarios: $e', error: true);
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

  @override
  Widget build(BuildContext context) {
    final activos = users.where((u) => u.isActive).length;
    final pendientes = users.where((u) => u.isPending).length;
    final q = query.trim().toLowerCase();
    final visibles = users.where((u) {
      if (filtro != 'todos' && u.estado != filtro) return false;
      if (q.isEmpty) return true;
      return u.fullName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(icon: Icons.group, value: '$activos', label: 'Usuarios activos'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.person_add_alt_1,
                          value: '$pendientes',
                          label: 'Solicitudes pendientes',
                          color: const Color(0xFFB45309),
                          onTap: () => setState(() => filtro = 'pendiente'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Buscar por nombre o correo',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (key, label) in const [
                        ('todos', 'Todos'),
                        ('pendiente', 'Pendientes'),
                        ('activo', 'Activos'),
                        ('rechazado', 'Rechazados'),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: filtro == key,
                          onSelected: (_) => setState(() => filtro = key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (visibles.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: EmptyState(icon: Icons.person_search, title: 'Sin usuarios que coincidan'),
                    )
                  else
                    ResponsiveColumns(
                      minColumnWidth: 400,
                      children: [for (var i = 0; i < visibles.length; i++) FadeSlideIn(index: i, child: _userCard(visibles[i]))],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _userCard(Profile u) {
    final isMe = u.id == AppSession.profile?.id;
    final color = u.isPending ? const Color(0xFFB45309) : (u.isActive ? const Color(0xFF15803D) : AppColors.error);
    final estadoLabel = u.isPending ? 'Pendiente' : (u.isActive ? 'Activo' : 'Rechazado');
    final fecha = u.createdAt != null ? DateFormat('dd/MM/yyyy').format(u.createdAt!) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                  child: Text(
                    (u.nombre.isNotEmpty ? u.nombre : u.email).substring(0, 1).toUpperCase(),
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isMe ? '${u.fullName} (tú)' : u.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      if (u.fullName != u.email)
                        Text(u.email, style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
                if (!u.isPending && !isMe)
                  PopupMenuButton<String>(
                    onSelected: (v) => _onMenu(v, u),
                    itemBuilder: (context) => [
                      if (u.isActive)
                        PopupMenuItem(
                          value: 'rol',
                          child: Text(u.isAdmin ? 'Cambiar a Técnico' : 'Cambiar a Administrador'),
                        ),
                      if (u.isActive)
                        PopupMenuItem(value: 'rechazar', child: Text('Desactivar cuenta', style: TextStyle(color: AppColors.error))),
                      if (!u.isActive) const PopupMenuItem(value: 'aprobar', child: Text('Reactivar cuenta')),
                    ],
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _pill(estadoLabel, color),
                if (u.isPending)
                  _pill('Solicita: ${u.requestedRoleLabel}', u.requestedAdmin ? const Color(0xFFB45309) : AppColors.inkMuted)
                else
                  _pill(u.roleLabel, u.isAdmin ? AppColors.palette4 : AppColors.inkMuted),
                if (u.departamento.isNotEmpty) Text(u.departamento, style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                if (u.cargo.isNotEmpty) Text('· ${u.cargo}', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                if (fecha.isNotEmpty) Text('· desde $fecha', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
            if (u.isPending)
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _run(() => db.setUserEstado(u, 'rechazado'), 'Solicitud rechazada'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, minimumSize: const Size.fromHeight(42)),
                        child: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _approve(u),
                        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                        child: const Text('Aprobar'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
              color: AppColors.isDark ? Color.lerp(color, Colors.white, 0.45) : color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            )),
      );

  /// ¿[u] es el único administrador activo?
  bool _lastAdmin(Profile u) => u.isAdmin && u.isActive && users.where((x) => x.isAdmin && x.isActive).length <= 1;

  /// Aprueba una cuenta pendiente; el admin confirma (o cambia) el rol.
  Future<void> _approve(Profile u) async {
    var rol = u.rolSolicitado;
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Aprobar cuenta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${u.fullName} solicitó el rol ${u.requestedRoleLabel}. Elige el rol que tendrá:',
                  style: TextStyle(color: AppColors.inkMuted)),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: rol,
                onChanged: (v) => setLocal(() => rol = v ?? rol),
                child: const Column(
                  children: [
                    RadioListTile<String>(value: 'tecnico', title: Text('Técnico'), subtitle: Text('Consulta y opera la red'), contentPadding: EdgeInsets.zero),
                    RadioListTile<String>(value: 'admin', title: Text('Administrador'), subtitle: Text('Gestiona todo el sistema'), contentPadding: EdgeInsets.zero),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(context, rol), child: const Text('Aprobar')),
          ],
        ),
      ),
    );
    if (chosen == null) return;
    await _run(() => db.setUserEstado(u, 'activo', rol: chosen), 'Cuenta aprobada como ${chosen == 'admin' ? 'Administrador' : 'Técnico'}');
  }

  Future<void> _onMenu(String value, Profile u) async {
    switch (value) {
      case 'rol':
        if (u.isAdmin && _lastAdmin(u)) {
          showMsg(context, 'No puedes quitarle el rol al único administrador activo.', error: true);
          return;
        }
        final nuevo = u.isAdmin ? 'tecnico' : 'admin';
        final ok = await confirmar(
          context,
          titulo: 'Cambiar rol',
          mensaje: '${u.fullName} pasará a ser ${nuevo == 'admin' ? 'Administrador' : 'Técnico'}. ¿Continuar?',
          accion: 'Cambiar',
        );
        if (ok) await _run(() => db.setUserRole(u, nuevo), 'Rol actualizado');
      case 'rechazar':
        if (u.isAdmin && _lastAdmin(u)) {
          showMsg(context, 'No puedes desactivar al único administrador activo.', error: true);
          return;
        }
        final ok = await confirmar(
          context,
          titulo: 'Desactivar cuenta',
          mensaje: '${u.fullName} ya no podrá iniciar sesión. ¿Continuar?',
          accion: 'Desactivar',
        );
        if (ok) await _run(() => db.setUserEstado(u, 'rechazado'), 'Cuenta desactivada');
      case 'aprobar':
        await _run(() => db.setUserEstado(u, 'activo'), 'Cuenta reactivada');
    }
  }
}
