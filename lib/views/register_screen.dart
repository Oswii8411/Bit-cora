import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_principal.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // Llave para validar el formulario completo

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _cargoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'tecnico';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final supabase = Supabase.instance.client;

  Future<void> _signUp() async {
    // Si la validación falla (algún campo vacío o incorrecto), se detiene aquí
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'departamento': _departamentoController.text.trim(),
          'cargo': _cargoController.text.trim(),
          'rol': _selectedRole,
        },
      );

      if (res.user != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainTabScreen()),
              (Route<dynamic> route) => false,
        );
      }
    } on AuthException catch (error) {
      String mensajeError = 'Error al registrar la cuenta.';

      if (error.message.contains('User already registered')) {
        mensajeError = 'Este correo ya está registrado en el sistema.';
      } else if (error.message.contains('Password should be at least')) {
        mensajeError = 'La contraseña es demasiado débil.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(mensajeError),
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
    const colorFondo = Color(0xFFF3E8FF);
    const colorPrimario = Color(0xFF6D28D9);
    const colorTextoOscuro = Color(0xFF1E1B4B);

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: colorTextoOscuro),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear cuenta', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorTextoOscuro)),
                SizedBox(height: 8),
                Text('Registra tus datos para solicitar acceso a Bitácora de Red', style: TextStyle(color: colorTextoOscuro, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Datos personales', 'Información básica de identificación', colorTextoOscuro),
                      _buildInput(_nombreController, 'Nombre', Icons.person_outline, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      _buildInput(_apellidoController, 'Apellido', Icons.person_outline, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      _buildInput(_emailController, 'Correo electrónico', Icons.email_outlined, isEmail: true, validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (!v.contains('@')) return 'Correo no válido';
                        return null;
                      }),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Información laboral', 'Área en la que desempeñas tus actividades', colorTextoOscuro),
                      _buildInput(_departamentoController, 'Departamento', Icons.business_outlined, validator: (v) => v!.isEmpty ? 'Requerido' : null),
                      _buildInput(_cargoController, 'Cargo o puesto', Icons.work_outline, validator: (v) => v!.isEmpty ? 'Requerido' : null),

                      const SizedBox(height: 24),
                      _buildSectionTitle('Seguridad y acceso', 'Crea una contraseña y selecciona tu rol', colorTextoOscuro),
                      _buildInput(_passwordController, 'Contraseña', Icons.lock_outline, isPassword: true, validator: (v) {
                        if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                        return null;
                      }),
                      _buildInput(_confirmPasswordController, 'Confirmar contraseña', Icons.lock_outline, isPassword: true, validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                        return null;
                      }),

                      const SizedBox(height: 16),
                      const Text('Rol solicitado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      RadioListTile(
                        title: const Text('Técnico de red'),
                        value: 'tecnico',
                        groupValue: _selectedRole,
                        activeColor: colorPrimario,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _selectedRole = val.toString()),
                      ),
                      RadioListTile(
                        title: const Text('Administrador'),
                        value: 'admin',
                        groupValue: _selectedRole,
                        activeColor: colorPrimario,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => _selectedRole = val.toString()),
                      ),

                      const SizedBox(height: 32),
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
                          onPressed: _isLoading ? null : _signUp,
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Crear cuenta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tienes una cuenta? ', style: TextStyle(color: Colors.grey)),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text('Iniciar sesión', style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, Color colorTextoOscuro) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorTextoOscuro)),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, {bool isPassword = false, bool isEmail = false, String? Function(String?)? validator}) {
    const colorPrimario = Color(0xFF6D28D9);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: colorPrimario),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          )
              : null,
          filled: true,
          fillColor: const Color(0xFFF7FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: colorPrimario, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.redAccent, width: 2.0)),
        ),
      ),
    );
  }
}