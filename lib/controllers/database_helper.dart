import 'package:bitacora_red/models/device.dart';
import 'package:bitacora_red/models/history_log.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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