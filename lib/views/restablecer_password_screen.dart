import 'package:bitacora_red/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

/// Pantalla que se abre con el enlace de "recuperar contraseña" del correo.
class RestablecerPasswordScreen extends StatefulWidget {
  const RestablecerPasswordScreen({super.key});

  @override
  State<RestablecerPasswordScreen> createState() => _RestablecerPasswordScreenState();
}

class _RestablecerPasswordScreenState extends State<RestablecerPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = AuthController();
      await auth.updatePassword(_pass.text.trim());
      await auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(notice: 'Contraseña actualizada. Inicia sesión con la nueva.'),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      _error(e.message);
    } catch (_) {
      _error('No se pudo actualizar la contraseña.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _error(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: AppColors.error));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text('Crea una contraseña nueva para tu cuenta.', style: TextStyle(color: AppColors.inkMuted)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _pass,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña nueva',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (v) => v != _pass.text ? 'Las contraseñas no coinciden' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Guardar contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
