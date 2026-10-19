import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import 'app_session.dart';
import 'database_helper.dart';

/// La cuenta existe pero todavía no puede entrar (pendiente o rechazada).
class AccountStatusException implements Exception {
  final String estado;
  AccountStatusException(this.estado);

  String get message => estado == 'rechazado'
      ? 'Tu solicitud fue rechazada por el administrador.'
      : 'Tu cuenta está pendiente de aprobación. El administrador debe aceptarla antes de que puedas entrar.';

  @override
  String toString() => message;
}

class AuthController {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  final DatabaseHelper _db = DatabaseHelper();

  /// Inicia sesión. Si la cuenta no está activa, cierra la sesión y lanza
  /// [AccountStatusException].
  Future<Profile> signIn({required String email, required String password}) async {
    final res = await _auth.signInWithPassword(email: email, password: password);
    final user = res.user;
    if (user == null) throw const AuthException('No se pudo iniciar sesión.');

    final profile = await _db.getProfile(user.id);
    if (profile == null) {
      await _auth.signOut();
      throw const AuthException('Tu perfil no existe. Pide al administrador que revise tu cuenta.');
    }
    if (!profile.isActive) {
      await _auth.signOut();
      throw AccountStatusException(profile.estado);
    }

    AppSession.apply(profile);
    _db.invalidateCache();
    await _db.logEvent('INICIO', 'SESION', 'Inició sesión');
    return profile;
  }

  /// Al abrir la app: si ya había sesión, recupera el perfil. Devuelve null
  /// si no hay sesión válida o la cuenta ya no está activa.
  Future<Profile?> restoreSession() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      // Con tiempo máximo: sin conexión la app debe llegar al login, no quedarse cargando.
      final profile = await _db.getProfile(user.id).timeout(const Duration(seconds: 15));
      if (profile == null || !profile.isActive) {
        await _auth.signOut();
        return null;
      }
      AppSession.apply(profile);
      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Crea la cuenta. El administrador la debe aprobar; el rol siempre es técnico.
  Future<void> signUp({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String departamento,
    required String cargo,
    String rolSolicitado = 'tecnico',
  }) async {
    await _auth.signUp(
      email: email,
      password: password,
      data: {
        'nombre': nombre,
        'apellido': apellido,
        'departamento': departamento,
        'cargo': cargo,
        // Solo es una solicitud: el administrador decide el rol al aprobar la cuenta.
        'rol_solicitado': rolSolicitado == 'admin' ? 'admin' : 'tecnico',
      },
    );
    // Si el proyecto no exige confirmar correo, signUp abre sesión: la cerramos
    // porque la cuenta aún no está aprobada.
    if (_auth.currentSession != null) await _auth.signOut();
  }

  Future<void> signOut() async {
    try {
      await _db.logEvent('CIERRE', 'SESION', 'Cerró sesión');
    } catch (_) {
      // Si falla el registro no debe impedir cerrar la sesión.
    }
    await _auth.signOut();
    AppSession.clear();
    _db.invalidateCache();
  }

  Future<void> sendPasswordRecovery(String email) => _auth.resetPasswordForEmail(email);

  Future<void> updatePassword(String newPassword) async {
    await _auth.updateUser(UserAttributes(password: newPassword));
    await _db.logEvent('EDITAR', 'USUARIO', 'Cambió su contraseña');
  }

  /// Supabase envía un correo de verificación a la dirección nueva.
  Future<void> updateEmail(String newEmail) async {
    await _auth.updateUser(UserAttributes(email: newEmail));
    await _db.logEvent('EDITAR', 'USUARIO', 'Solicitó cambiar su correo a $newEmail');
  }
}
