import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_principal.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Llave para validar el formulario
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final supabase = Supabase.instance.client;

  Future<void> _signIn() async {
    // Valida que los campos no estén vacíos antes de intentar iniciar sesión
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (res.user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainTabScreen()),
        );
      }
    } on AuthException catch (error) {
      // Interceptar y traducir el mensaje de Supabase
      String mensajeError = 'Error al iniciar sesión.';

      if (error.message.contains('Invalid login credentials')) {
        mensajeError = 'El correo o la contraseña son incorrectos.';
      } else if (error.message.contains('Email not confirmed')) {
        mensajeError = 'Debes confirmar tu correo electrónico primero.';
      } else if (error.message.contains('Too many requests')) {
        mensajeError = 'Demasiados intentos. Por favor, espera un momento.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeError),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating, // Hace que el mensaje se vea más moderno (flotante)
            )
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error inesperado de conexión.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Paleta Púrpura Moderna
    const colorFondo = Color(0xFFF3E8FF); // Púrpura muy claro
    const colorPrimario = Color(0xFF6D28D9); // Púrpura profundo y vibrante
    const colorTextoOscuro = Color(0xFF1E1B4B);

    return Scaffold(
      backgroundColor: colorFondo,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                      ),
                      child: const Icon(Icons.router_outlined, size: 60, color: colorPrimario),
                    ),
                    const SizedBox(height: 16),
                    const Text('NetControl ITSU', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorTextoOscuro)),
                    const SizedBox(height: 8),
                    const Text('Control y administración de red', style: TextStyle(color: colorTextoOscuro, fontSize: 14)),
                  ],
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey, // Asignamos la llave al formulario
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Bienvenido', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorTextoOscuro)),
                        const SizedBox(height: 8),
                        const Text('Ingresa con tus credenciales para continuar', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 32),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Correo electrónico',
                          icon: Icons.email_outlined,
                          colorPrimario: colorPrimario,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
                            if (!value.contains('@')) return 'Ingresa un correo válido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(
                          controller: _passwordController,
                          label: 'Contraseña',
                          icon: Icons.lock_outline,
                          colorPrimario: colorPrimario,
                          isPassword: true,
                          obscureText: _obscurePassword,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'La contraseña es obligatoria';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: colorPrimario, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorPrimario,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _signIn,
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('Iniciar sesión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('¿Aún no tienes cuenta? ', style: TextStyle(color: Colors.grey)),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const RegisterScreen())),
                              child: const Text('Crear cuenta', style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color colorPrimario,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator, // Recibe la regla de validación
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: colorPrimario),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onTogglePassword,
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF7FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: colorPrimario, width: 1.5)),
        // Configuración para resaltar en rojo cuando hay error
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 2.0)),
      ),
    );
  }
}