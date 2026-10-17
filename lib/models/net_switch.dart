class NetSwitch {
  String id, networkId, name, model, ip, location, estado;

  NetSwitch({
    required this.id,
    required this.networkId,
    required this.name,
    this.model = '',
    this.ip = '',
    this.location = '',
    this.estado = 'Activo',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'network_id': networkId,
    'name': name,
    'model': model,
    'ip': ip,
    'location': location,
    'estado': estado,
  };

  factory NetSwitch.fromMap(Map<String, dynamic> map) => NetSwitch(
    id: map['id'] as String,
    networkId: map['network_id'] as String,
    name: map['name'] as String,
    model: map['model'] as String? ?? '',
    ip: map['ip'] as String? ?? '',
    location: map['location'] as String? ?? '',
    estado: map['estado'] as String? ?? 'Activo',
  );
}
