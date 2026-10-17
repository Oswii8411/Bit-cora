class NetworkGroup {
  String id, name, baseIp, estado, ubicacion;
  int colorValue;

  NetworkGroup({
    required this.id,
    required this.name,
    required this.baseIp,
    required this.colorValue,
    this.estado = 'Activo',
    this.ubicacion = '',
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'baseIp': baseIp,
    'colorValue': colorValue,
    'estado': estado,
    'ubicacion': ubicacion,
  };
  factory NetworkGroup.fromMap(Map<String, dynamic> map) => NetworkGroup(
    id: map['id'] as String,
    name: map['name'] as String,
    baseIp: map['baseIp'] as String,
    colorValue: map['colorValue'] as int,
    estado: map['estado'] as String? ?? 'Activo',
    ubicacion: map['ubicacion'] as String? ?? '',
  );
}
