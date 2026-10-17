import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/terminos_dialog.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _cargoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthController _authController = AuthController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _termsError = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _departamentoController.dispose();
    _cargoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: AppColors.error,
    ));
  }

  Future<void> _signUp() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _termsError = !_acceptedTerms);
    if (!valid || !_acceptedTerms) return;

    setState(() => _isLoading = true);
    try {
      await _authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        departamento: _departamentoController.text.trim(),
        cargo: _cargoController.text.trim(),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.hourglass_top_rounded, size: 40, color: AppColors.palette4),
          title: const Text('Solicitud enviada'),
          content: const Text(
            'Tu cuenta quedó pendiente de aprobación. Cuando un administrador la acepte podrás iniciar sesión.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on AuthException catch (error) {
      String mensajeError = 'Error al registrar la cuenta.';
      if (error.message.contains('already registered')) {
        mensajeError = 'Este correo ya está registrado en el sistema.';
      } else if (error.message.contains('Password should be at least')) {
        mensajeError = 'La contraseña es demasiado débil.';
      }
      _snack(mensajeError);
    } catch (_) {
      _snack('No se pudo completar el registro. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimario = AppColors.primary;
    final colorTextoOscuro = AppColors.ink;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Solicitar acceso')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Un administrador revisará tu solicitud antes de que puedas entrar.',
                        style: TextStyle(color: AppColors.inkMuted, fontSize: 14.5)),
                    const SizedBox(height: 22),
                          _buildSectionTitle('Datos personales', 'Información básica de identificación', colorTextoOscuro),
                          _buildInput(_nombreController, 'Nombre', Icons.person_outline,
                              validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
                          _buildInput(_apellidoController, 'Apellido', Icons.person_outline,
                              validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
                          _buildInput(_emailController, 'Correo electrónico', Icons.email_outlined, isEmail: true,
                              validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (!v.contains('@')) return 'Correo no válido';
                            return null;
                          }),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Información laboral', 'Área en la que desempeñas tus actividades', colorTextoOscuro),
                          _buildInput(_departamentoController, 'Departamento', Icons.business_outlined,
                              validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
                          _buildInput(_cargoController, 'Cargo o puesto', Icons.work_outline,
                              validator: (v) => v!.trim().isEmpty ? 'Requerido' : null),
                          const SizedBox(height: 24),
                          _buildSectionTitle('Seguridad', 'Crea una contraseña para tu cuenta', colorTextoOscuro),
                          _buildInput(_passwordController, 'Contraseña', Icons.lock_outline, isPassword: true,
                              validator: (v) {
                            if (v == null || v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          }),
                          _buildInput(_confirmPasswordController, 'Confirmar contraseña', Icons.lock_outline,
                              isPassword: true, validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                            return null;
                          }),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                activeColor: colorPrimario,
                                isError: _termsError,
                                onChanged: (v) => setState(() {
                                  _acceptedTerms = v ?? false;
                                  _termsError = false;
                                }),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Wrap(
                                    children: [
                                      Text('Acepto los ', style: TextStyle(color: AppColors.ink)),
                                      GestureDetector(
                                        onTap: () => showTerminosDialog(context),
                                        child: Text('términos y condiciones',
                                            style: TextStyle(
                                                color: colorPrimario,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.underline)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_termsError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, bottom: 4),
                              child: Text('Debes aceptar los términos para continuar',
                                  style: TextStyle(color: AppColors.error, fontSize: 12)),
                            ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorPrimario,
                                foregroundColor: AppColors.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                elevation: 0,
                              ),
                              onPressed: _isLoading ? null : _signUp,
                              child: _isLoading
                                  ? CircularProgressIndicator(color: AppColors.onPrimary)
                                  : const Text('Enviar solicitud',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('¿Ya tienes una cuenta? ', style: TextStyle(color: AppColors.inkMuted)),
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Text('Iniciar sesión',
                                    style: TextStyle(color: colorPrimario, fontWeight: FontWeight.bold)),
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
          Text(subtitle, style: TextStyle(color: AppColors.inkMuted, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, bool isEmail = false, String? Function(String?)? validator}) {
    final colorPrimario = AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppColors.inkMuted),
          prefixIcon: Icon(icon, color: colorPrimario),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppColors.inkMuted),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: colorPrimario, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.error, width: 1.5)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: AppColors.error, width: 2.0)),
        ),
      ),
    );
  }
}
