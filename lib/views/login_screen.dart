import 'package:bitacora_red/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../controllers/auth_controller.dart';
import 'pantalla_principal.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Mensaje opcional al llegar (por ejemplo, cuando la sesión expiró).
  final String? notice;
  const LoginScreen({super.key, this.notice});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _snack(widget.notice!));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _snack(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? AppColors.error : null,
    ));
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainTabScreen()),
        );
      }
    } on AccountStatusException catch (e) {
      _snack(e.message, error: true);
    } on AuthException catch (error) {
      String mensajeError = 'Error al iniciar sesión.';
      if (error.message.contains('Invalid login credentials')) {
        mensajeError = 'El correo o la contraseña son incorrectos.';
      } else if (error.message.contains('Email not confirmed')) {
        mensajeError = 'Debes confirmar tu correo electrónico primero.';
      } else if (error.message.contains('Too many requests')) {
        mensajeError = 'Demasiados intentos. Por favor, espera un momento.';
      } else if (error.message.contains('perfil')) {
        mensajeError = error.message;
      }
      _snack(mensajeError, error: true);
    } catch (error) {
      _snack('Error inesperado de conexión.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Escribe tu correo y te enviaremos un enlace para crear una contraseña nueva.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    if (!email.contains('@')) {
      _snack('Ingresa un correo válido', error: true);
      return;
    }
    try {
      await _authController.sendPasswordRecovery(email);
      _snack('Si el correo existe, recibirás un enlace para restablecer tu contraseña.');
    } on AuthException catch (e) {
      _snack(e.message.contains('rate') ? 'Espera un momento antes de pedir otro enlace.' : 'No se pudo enviar el correo.', error: true);
    } catch (_) {
      _snack('No se pudo enviar el correo.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.palette5, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.router_outlined, color: AppColors.palette1, size: 26),
                    ),
                    const SizedBox(height: 22),
                    const Text('Bitácora de Red',
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.9, height: 1.1)),
                    const SizedBox(height: 6),
                    Text('Inicia sesión para administrar la red del instituto.',
                        style: TextStyle(color: AppColors.inkMuted, fontSize: 15)),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      icon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
                        if (!value.contains('@')) return 'Ingresa un correo válido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'La contraseña es obligatoria';
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(onPressed: _forgotPassword, child: const Text('¿Olvidaste tu contraseña?')),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onPrimary))
                          : const Text('Iniciar sesión'),
                    ),
                    const SizedBox(height: 22),
                    Divider(color: AppColors.border),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text('¿Aún no tienes cuenta?', style: TextStyle(color: AppColors.inkMuted)),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) => const RegisterScreen())),
                          child: const Text('Solicitar acceso'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: isPassword ? TextInputType.text : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 21, color: AppColors.inkMuted),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, size: 21, color: AppColors.inkMuted),
                onPressed: onTogglePassword,
              )
            : null,
      ),
    );
  }
}
