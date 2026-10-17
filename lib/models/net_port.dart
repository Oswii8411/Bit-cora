class NetPort {
  String id, switchId, vlan, departamento, observaciones, estado;
  int number;
  String? subnetId; // segmentación de red a la que pertenece

  NetPort({
    required this.id,
    required this.switchId,
    required this.number,
    this.subnetId,
    this.vlan = '',
    this.departamento = '',
    this.observaciones = '',
    this.estado = 'Disponible',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'switch_id': switchId,
    'number': number,
    'subnet_id': subnetId,
    'vlan': vlan,
    'departamento': departamento,
    'observaciones': observaciones,
    'estado': estado,
  };

  factory NetPort.fromMap(Map<String, dynamic> map) => NetPort(
    id: map['id'] as String,
    switchId: map['switch_id'] as String,
    number: map['number'] as int,
    subnetId: map['subnet_id'] as String?,
    vlan: map['vlan'] as String? ?? '',
    departamento: map['departamento'] as String? ?? '',
    observaciones: map['observaciones'] as String? ?? '',
    estado: map['estado'] as String? ?? 'Disponible',
  );

  /// Un puerto cuenta como operativo si no está deshabilitado ni con incidencia.
  bool get operativo => estado == 'Disponible' || estado == 'En uso';
}
