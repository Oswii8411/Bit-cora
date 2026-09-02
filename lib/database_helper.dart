import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// LÓGICA DE RED Y MATEMÁTICAS IP
// ==========================================
class NetworkUtils {
  static int ipToLong(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return 0;
    return (int.parse(parts[0]) << 24) + (int.parse(parts[1]) << 16) + (int.parse(parts[2]) << 8) + int.parse(parts[3]);
  }
  static String longToIp(int longVal) {
    return '${(longVal >> 24) & 255}.${(longVal >> 16) & 255}.${(longVal >> 8) & 255}.${longVal & 255}';
  }
}

// ==========================================
// MODELOS DE DATOS
// ==========================================
class NetworkGroup {
  String id, name, baseIp;
  int colorValue;
  NetworkGroup({required this.id, required this.name, required this.baseIp, required this.colorValue});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'baseIp': baseIp, 'colorValue': colorValue};
  factory NetworkGroup.fromMap(Map<String, dynamic> map) => NetworkGroup(
      id: map['id'] as String, name: map['name'] as String, baseIp: map['baseIp'] as String, colorValue: map['colorValue'] as int);
}

class Subnet {
  String id, networkId, name, baseIp;
  int size;
  Subnet({required this.id, required this.networkId, required this.name, required this.baseIp, required this.size});
  Map<String, dynamic> toMap() => {'id': id, 'networkId': networkId, 'name': name, 'baseIp': baseIp, 'size': size};
  factory Subnet.fromMap(Map<String, dynamic> map) => Subnet(
      id: map['id'] as String, networkId: map['networkId'] as String, name: map['name'] as String, baseIp: map['baseIp'] as String, size: map['size'] as int);
  int get networkLong => NetworkUtils.ipToLong(baseIp);
  String get firstUsable => NetworkUtils.longToIp(networkLong + 1);
  String get lastUsable => NetworkUtils.longToIp(networkLong + size - 2);
  bool isIpInUsableRange(String ip) {
    int ipLong = NetworkUtils.ipToLong(ip);
    return ipLong >= (networkLong + 1) && ipLong <= (networkLong + size - 2);
  }
}

class Device {
  String id, name, mac, manufacturer, location, ip, subnetId;
  Device({required this.id, required this.name, required this.mac, required this.manufacturer, required this.location, required this.ip, required this.subnetId});
  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'mac': mac, 'manufacturer': manufacturer, 'location': location, 'ip': ip, 'subnetId': subnetId};
  factory Device.fromMap(Map<String, dynamic> map) => Device(
      id: map['id'] as String, name: map['name'] as String, mac: map['mac'] as String, manufacturer: map['manufacturer'] as String, location: map['location'] as String, ip: map['ip'] as String, subnetId: map['subnetId'] as String);
}

// Nuevo modelo para el Historial
class HistoryLog {
  String? id;
  String actionType;
  String entityType;
  String description;
  DateTime? createdAt;

  HistoryLog({this.id, required this.actionType, required this.entityType, required this.description, this.createdAt});

  factory HistoryLog.fromMap(Map<String, dynamic> map) {
    return HistoryLog(
      id: map['id'],
      actionType: map['action_type'],
      entityType: map['entity_type'],
      description: map['description'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']).toLocal() : null,
    );
  }
}

// ==========================================
// CAPA DE BASE DE DATOS (SUPABASE)
// ==========================================
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // --- LOG DE AUDITORÍA ---
  Future<void> _logAction(String actionType, String entityType, String description) async {
    await _client.from('history_logs').insert({
      'action_type': actionType,
      'entity_type': entityType,
      'description': description,
    });
  }

  Future<List<HistoryLog>> getHistoryLogs() async {
    final response = await _client.from('history_logs').select().order('created_at', ascending: false);
    return (response as List<dynamic>).map((json) => HistoryLog.fromMap(json as Map<String, dynamic>)).toList();
  }

  // --- CRUD de Networks ---
  Future<void> insertNetwork(NetworkGroup net) async {
    await _client.from('networks').upsert(net.toMap());
    await _logAction('CREAR', 'RED', 'Se creó la red "${net.name}" con IP base ${net.baseIp}');
  }
  Future<List<NetworkGroup>> getNetworks() async {
    final response = await _client.from('networks').select();
    return (response as List<dynamic>).map((json) => NetworkGroup.fromMap(json as Map<String, dynamic>)).toList();
  }
  Future<void> updateNetwork(NetworkGroup net) async {
    await _client.from('networks').update(net.toMap()).eq('id', net.id);
    await _logAction('EDITAR', 'RED', 'Se actualizó la red "${net.name}"');
  }
  Future<void> deleteNetwork(String id, String name) async {
    await _client.from('networks').delete().eq('id', id);
    await _logAction('ELIMINAR', 'RED', 'Se eliminó la red completa "$name"');
  }

  // --- CRUD de Subnets ---
  Future<void> insertSubnet(Subnet subnet) async {
    await _client.from('subnets').upsert(subnet.toMap());
  }
  Future<List<Subnet>> getSubnets() async {
    final response = await _client.from('subnets').select();
    return (response as List<dynamic>).map((json) => Subnet.fromMap(json as Map<String, dynamic>)).toList();
  }
  Future<List<Subnet>> getSubnetsByNetwork(String networkId) async {
    final response = await _client.from('subnets').select().eq('networkId', networkId);
    return (response as List<dynamic>).map((json) => Subnet.fromMap(json as Map<String, dynamic>)).toList();
  }
  Future<void> updateSubnet(Subnet subnet) async {
    await _client.from('subnets').update(subnet.toMap()).eq('id', subnet.id);
    await _logAction('EDITAR', 'SEGMENTO', 'Se cambió el nombre del segmento a "${subnet.name}"');
  }
  Future<void> deleteSubnet(String id, String name) async {
    await _client.from('subnets').delete().eq('id', id);
    await _logAction('ELIMINAR', 'SEGMENTO', 'Se eliminó el segmento "$name"');
  }

  // --- CRUD de Devices ---
  Future<void> insertDevice(Device device) async {
    await _client.from('devices').upsert(device.toMap());
    await _logAction('CREAR', 'EQUIPO', 'Se registró el equipo "${device.name}" con IP ${device.ip}');
  }
  Future<List<Device>> getDevices() async {
    final response = await _client.from('devices').select();
    return (response as List<dynamic>).map((json) => Device.fromMap(json as Map<String, dynamic>)).toList();
  }
  Future<void> updateDevice(Device device) async {
    await _client.from('devices').update(device.toMap()).eq('id', device.id);
    await _logAction('EDITAR', 'EQUIPO', 'Se actualizó la información de "${device.name}" (IP: ${device.ip})');
  }
  Future<void> deleteDevice(String id, String name) async {
    await _client.from('devices').delete().eq('id', id);
    await _logAction('ELIMINAR', 'EQUIPO', 'Se eliminó el equipo "$name" de la red');
  }
}