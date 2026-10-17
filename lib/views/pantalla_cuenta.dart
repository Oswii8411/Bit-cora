import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/auth_controller.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;

/// Perfil: consulta y edición de la información personal.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final db = DatabaseHelper();
  late final TextEditingController nombre, apellido, departamento, cargo;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final p = AppSession.profile!;
    nombre = TextEditingController(text: p.nombre);
    apellido = TextEditingController(text: p.apellido);
    departamento = TextEditingController(text: p.departamento);
    cargo = TextEditingController(text: p.cargo);
  }

  @override
  void dispose() {
    for (final c in [nombre, apellido, departamento, cargo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final p = AppSession.profile!;
    p
      ..nombre = nombre.text.trim()
      ..apellido = apellido.text.trim()
      ..departamento = departamento.text.trim()
      ..cargo = cargo.text.trim();
    setState(() => saving = true);
    try {
      await db.updateOwnProfile(p);
      if (mounted) showMsg(context, 'Perfil actualizado');
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo guardar: $e', error: true);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppSession.profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: Centered(child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _readonly('Correo electrónico', p.email, Icons.email_outlined),
            const SizedBox(height: 12),
            _readonly('Rol', p.roleLabel, Icons.badge_outlined),
            const SizedBox(height: 20),
            TextFormField(
              controller: nombre,
              decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: apellido,
              decoration: const InputDecoration(labelText: 'Apellido', prefixIcon: Icon(Icons.person_outline)),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: departamento,
              decoration: const InputDecoration(labelText: 'Departamento', prefixIcon: Icon(Icons.business_outlined)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: cargo,
              decoration: const InputDecoration(labelText: 'Cargo o puesto', prefixIcon: Icon(Icons.work_outline)),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: saving ? null : _save,
              child: saving
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                  : const Text('Guardar cambios'),
            ),
          ],
        ),
      )),
    );
  }

  Widget _readonly(String label, String value, IconData icon) => InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), enabled: false),
        child: Text(value),
      );
}

/// Seguridad: cambio de correo y de contraseña.
class SeguridadScreen extends StatefulWidget {
  const SeguridadScreen({super.key});

  @override
  State<SeguridadScreen> createState() => _SeguridadScreenState();
}

class _SeguridadScreenState extends State<SeguridadScreen> {
  final auth = AuthController();
  final emailForm = GlobalKey<FormState>();
  final passForm = GlobalKey<FormState>();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();
  bool busy = false;
  bool obscure = true;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => busy = true);
    try {
      await action();
      if (mounted) showMsg(context, ok);
    } on AuthException catch (e) {
      if (mounted) showMsg(context, e.message, error: true);
    } catch (e) {
      if (mounted) showMsg(context, 'Error: $e', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppSession.profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: Centered(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Correo electrónico', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text('Actual: ${p.email}. Te enviaremos un correo para verificar el cambio.',
              style: TextStyle(color: AppColors.inkMuted)),
          const SizedBox(height: 12),
          Form(
            key: emailForm,
            child: TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Correo nuevo', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (!t.contains('@')) return 'Ingresa un correo válido';
                if (t == p.email) return 'Es el mismo correo';
                return null;
              },
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: busy
                ? null
                : () {
                    if (emailForm.currentState!.validate()) {
                      _run(() => auth.updateEmail(email.text.trim()), 'Revisa tu correo nuevo para confirmar el cambio');
                    }
                  },
            child: const Text('Cambiar correo'),
          ),
          const SizedBox(height: 28),
          Text('Contraseña', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          Form(
            key: passForm,
            child: Column(
              children: [
                TextFormField(
                  controller: pass,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña nueva',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirm,
                  obscureText: obscure,
                  decoration: const InputDecoration(labelText: 'Confirmar contraseña', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v != pass.text ? 'Las contraseñas no coinciden' : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: busy
                ? null
                : () {
                    if (passForm.currentState!.validate()) {
                      _run(() async {
                        await auth.updatePassword(pass.text.trim());
                        pass.clear();
                        confirm.clear();
                      }, 'Contraseña actualizada');
                    }
                  },
            child: const Text('Cambiar contraseña'),
          ),
          const SizedBox(height: 28),
          Text('Recuperación de contraseña', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text('Si la olvidas, te enviamos un enlace a ${p.email} para crear una nueva.',
              style: TextStyle(color: AppColors.inkMuted)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.mail_outline),
            onPressed: busy ? null : () => _run(() => auth.sendPasswordRecovery(p.email), 'Enlace enviado a ${p.email}'),
            label: const Text('Enviarme el enlace'),
          ),
        ],
      )),
    );
  }
}

/// Preferencias: tema y tiempo de protección de sesión.
class PreferenciasScreen extends StatefulWidget {
  const PreferenciasScreen({super.key});

  @override
  State<PreferenciasScreen> createState() => _PreferenciasScreenState();
}

class _PreferenciasScreenState extends State<PreferenciasScreen> {
  final db = DatabaseHelper();
  static const opciones = [5, 15, 30, 60, 120];

  Future<void> _save() async {
    try {
      await db.updatePreferences(AppSession.profile!);
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudo guardar la preferencia: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppSession.profile!;
    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias')),
      body: Centered(child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Tema', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'claro', icon: Icon(Icons.light_mode_outlined), label: Text('Claro')),
              ButtonSegment(value: 'oscuro', icon: Icon(Icons.dark_mode_outlined), label: Text('Oscuro')),
            ],
            selected: {p.tema},
            onSelectionChanged: (s) {
              setState(() => p.tema = s.first);
              AppSession.themeMode.value = p.tema == 'oscuro' ? ThemeMode.dark : ThemeMode.light;
              _save();
            },
          ),
          const SizedBox(height: 30),
          Text('Tiempo de protección de sesión',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text('Tu sesión se cierra sola después de este tiempo sin usar la aplicación.',
              style: TextStyle(color: AppColors.inkMuted)),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: opciones.contains(p.sesionMin) ? p.sesionMin : 30,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.timer_outlined)),
            items: [
              for (final m in opciones)
                DropdownMenuItem(value: m, child: Text(m < 60 ? '$m minutos' : (m == 60 ? '1 hora' : '${m ~/ 60} horas'))),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() => p.sesionMin = v);
              AppSession.sessionMinutes.value = v;
              _save();
            },
          ),
        ],
      )),
    );
  }
}
