/// Perfil de un usuario de la app (tabla `profiles`).
class Profile {
  final String id;
  String email;
  String rol; // 'admin' | 'tecnico'
  String estado; // 'pendiente' | 'activo' | 'rechazado'
  String nombre, apellido, departamento, cargo;
  String tema; // 'claro' | 'oscuro'
  int sesionMin;
  DateTime? createdAt;

  Profile({
    required this.id,
    required this.email,
    this.rol = 'tecnico',
    this.estado = 'pendiente',
    this.nombre = '',
    this.apellido = '',
    this.departamento = '',
    this.cargo = '',
    this.tema = 'claro',
    this.sesionMin = 30,
    this.createdAt,
  });

  bool get isAdmin => rol == 'admin' || rol == 'administrador';
  bool get isActive => estado == 'activo';
  bool get isPending => estado == 'pendiente';

  String get fullName {
    final n = '$nombre $apellido'.trim();
    return n.isEmpty ? email : n;
  }

  String get roleLabel => isAdmin ? 'Administrador' : 'Técnico';

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        email: map['email'] as String? ?? '',
        rol: map['rol'] as String? ?? 'tecnico',
        estado: map['estado'] as String? ?? 'pendiente',
        nombre: map['nombre'] as String? ?? '',
        apellido: map['apellido'] as String? ?? '',
        departamento: map['departamento'] as String? ?? '',
        cargo: map['cargo'] as String? ?? '',
        tema: map['tema'] as String? ?? 'claro',
        sesionMin: map['sesion_min'] as int? ?? 30,
        createdAt: map['created_at'] != null
            ? DateTime.tryParse(map['created_at'] as String)?.toLocal()
            : null,
      );

  /// Campos que el propio usuario puede editar en su perfil.
  Map<String, dynamic> toProfileUpdate() => {
        'nombre': nombre,
        'apellido': apellido,
        'departamento': departamento,
        'cargo': cargo,
      };
}
