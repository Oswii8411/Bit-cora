import 'network_utils.dart';

/// Validaciones reutilizables para los formularios. Todas devuelven el
/// mensaje de error, o null si el valor es válido (como pide `validator`).
class Validators {
  static final RegExp _email = RegExp(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$");
  static final RegExp _personName = RegExp(r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ][A-Za-zÁÉÍÓÚÜÑáéíóúüñ .'\-]*$");

  static String? required(String? v, [String campo = 'Este campo']) =>
      (v == null || v.trim().isEmpty) ? '$campo es obligatorio' : null;

  /// Texto libre obligatorio con longitud mínima y máxima.
  static String? text(String? v, {String campo = 'Este campo', int min = 1, int max = 120}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$campo es obligatorio';
    if (t.length < min) return '$campo debe tener al menos $min caracteres';
    if (t.length > max) return '$campo no puede pasar de $max caracteres';
    return null;
  }

  /// Texto opcional con longitud máxima.
  static String? optional(String? v, {String campo = 'Este campo', int max = 120}) {
    final t = v?.trim() ?? '';
    return t.length > max ? '$campo no puede pasar de $max caracteres' : null;
  }

  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'El correo es obligatorio';
    if (t.length > 120) return 'El correo es demasiado largo';
    if (!_email.hasMatch(t)) return 'Escribe un correo válido (nombre@dominio.com)';
    return null;
  }

  /// Nombre o apellido de persona: letras, espacios, punto, apóstrofe y guion.
  static String? personName(String? v, [String campo = 'El nombre']) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$campo es obligatorio';
    if (t.length < 2) return '$campo debe tener al menos 2 letras';
    if (t.length > 60) return '$campo no puede pasar de 60 caracteres';
    if (!_personName.hasMatch(t)) return '$campo solo puede tener letras';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'La contraseña es obligatoria';
    if (v.length < 6) return 'Mínimo 6 caracteres';
    if (v.length > 72) return 'Máximo 72 caracteres';
    if (v.trim().isEmpty) return 'La contraseña no puede ser solo espacios';
    return null;
  }

  static String? ip(String? v, {bool required = true, String campo = 'La IP'}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return required ? '$campo es obligatoria' : null;
    if (!NetworkUtils.isValidIp(t)) return '$campo no es válida (Ej. 192.168.1.10)';
    if (t == '0.0.0.0' || t == '255.255.255.255') return '$campo no es una dirección utilizable';
    return null;
  }

  /// Entero entre [min] y [max].
  static String? intRange(String? v, int min, int max, [String campo = 'El valor']) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return '$campo debe ser un número entero';
    if (n < min || n > max) return '$campo debe estar entre $min y $max';
    return null;
  }

  static bool isPowerOfTwo(int n) => n > 0 && (n & (n - 1)) == 0;

  /// ¿Ya existe [valor] (sin distinguir mayúsculas ni espacios) en [existentes]?
  static bool duplicated(String valor, Iterable<String> existentes) {
    final v = valor.trim().toLowerCase();
    return existentes.any((e) => e.trim().toLowerCase() == v);
  }
}
