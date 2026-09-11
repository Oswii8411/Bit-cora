class NetworkGroup {
  String id, name, baseIp;
  int colorValue;

  NetworkGroup({
    required this.id,
    required this.name,
    required this.baseIp,
    required this.colorValue,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'baseIp': baseIp,
    'colorValue': colorValue,
  };
  factory NetworkGroup.fromMap(Map<String, dynamic> map) => NetworkGroup(
    id: map['id'] as String,
    name: map['name'] as String,
    baseIp: map['baseIp'] as String,
    colorValue: map['colorValue'] as int,
  );
}
