class Device {
  String id, name, mac, manufacturer, location, ip, subnetId;
  Device({
    required this.id,
    required this.name,
    required this.mac,
    required this.manufacturer,
    required this.location,
    required this.ip,
    required this.subnetId,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'mac': mac,
    'manufacturer': manufacturer,
    'location': location,
    'ip': ip,
    'subnetId': subnetId,
  };
  factory Device.fromMap(Map<String, dynamic> map) => Device(
    id: map['id'] as String,
    name: map['name'] as String,
    mac: map['mac'] as String,
    manufacturer: map['manufacturer'] as String,
    location: map['location'] as String,
    ip: map['ip'] as String,
    subnetId: map['subnetId'] as String,
  );
}
