import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/models/device.dart';
import 'package:bitacora_red/models/history_log.dart';
import 'package:bitacora_red/models/net_port.dart';
import 'package:bitacora_red/models/net_switch.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/profile.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/incidencia.dart';

/// Resumen para las pantallas de inicio.
class DashboardStats {
  int buildings = 0,
      switches = 0,
      changes = 0,
      users = 0,
      pendingUsers = 0,
      portsTotal = 0,
      portsOperational = 0,
      portsIncident = 0,
      vlansActive = 0,
      vlansTotal = 0,
      myActivityToday = 0,
      pendingIncidents = 0,
      degradedInfra = 0;
  List<HistoryLog> recentActivity = [];
  /// "Switch · Puerto N" de cada puerto con incidencia.
  List<String> incidentPorts = [];
  /// Puertos por edificio (nombre, cantidad), de mayor a menor.
  List<MapEntry<String, int>> portsByBuilding = [];
  /// Movimientos de los últimos 7 días (el último es hoy).
  List<int> changesWeek = List.filled(7, 0);
  /// Los 7 días a los que corresponde `changesWeek` (admin: movimientos de todos; técnico: los suyos).
  List<DateTime> weekDays = [];
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // --- LOG DE AUDITORÍA (bitácora) ---
  Future<void> _logAction(
    String actionType,
    String entityType,
    String description, {
    String? entityId,
  }) async {
    final p = AppSession.profile;
    final authUser = _client.auth.currentUser;
    await _client.from('history_logs').insert({
      'action_type': actionType,
      'entity_type': entityType,
      'description': description,
      'entity_id': entityId,
      'user_id': p?.id ?? authUser?.id,
      'user_email': p?.email ?? authUser?.email,
      'user_name': p?.fullName,
      'user_role': p?.rol,
    });
  }

  /// Registra inicios y cierres de sesión, reportes, etc.
  Future<void> logEvent(String actionType, String entityType, String description) =>
      _logAction(actionType, entityType, description);

  /// Bitácora completa, o solo los movimientos de [userId].
  Future<List<HistoryLog>> getHistoryLogs({String? userId, int limit = 1000}) async {
    var query = _client.from('history_logs').select();
    if (userId != null) query = query.eq('user_id', userId);
    final response = await query.order('created_at', ascending: false).limit(limit);
    return (response as List<dynamic>).map((json) => HistoryLog.fromMap(json as Map<String, dynamic>)).toList();
  }

  /// Historial de un edificio, switch o puerto concreto.
  Future<List<HistoryLog>> getHistoryByEntity(String entityId) async {
    final response = await _client
        .from('history_logs')
        .select()
        .eq('entity_id', entityId)
        .order('created_at', ascending: false);
    return (response as List<dynamic>).map((json) => HistoryLog.fromMap(json as Map<String, dynamic>)).toList();
  }

  // --- PERFILES / USUARIOS ---
  Future<Profile?> getProfile(String id) async {
    final res = await _client.from('profiles').select().eq('id', id).maybeSingle();
    return res == null ? null : Profile.fromMap(res);
  }

  Future<List<Profile>> getProfiles() async {
    final res = await _client.from('profiles').select().order('created_at', ascending: false);
    return (res as List<dynamic>).map((j) => Profile.fromMap(j as Map<String, dynamic>)).toList();
  }

  Future<void> updateOwnProfile(Profile p) async {
    await _client.from('profiles').update(p.toProfileUpdate()).eq('id', p.id);
    await _logAction('EDITAR', 'USUARIO', 'Actualizó su información de perfil', entityId: p.id);
  }

  Future<void> updatePreferences(Profile p) async {
    await _client.from('profiles').update({'tema': p.tema, 'sesion_min': p.sesionMin}).eq('id', p.id);
  }

  /// Aprobar, rechazar o reactivar una cuenta (solo administrador).
  /// Con [rol] se aprueba la cuenta asignando ese rol (admin | tecnico).
  Future<void> setUserEstado(Profile target, String estado, {String? rol}) async {
    await _client.from('profiles').update({'estado': estado, 'rol': ?rol}).eq('id', target.id);
    final verbo = estado == 'activo' ? 'aprobó' : (estado == 'rechazado' ? 'rechazó' : 'marcó como pendiente');
    final comoRol = rol == null ? '' : ' como ${rol == 'admin' ? 'Administrador' : 'Técnico'}';
    await _logAction('EDITAR', 'USUARIO', 'Se $verbo la cuenta de ${target.fullName} (${target.email})$comoRol', entityId: target.id);
  }

  Future<void> setUserRole(Profile target, String rol) async {
    await _client.from('profiles').update({'rol': rol}).eq('id', target.id);
    await _logAction(
      'EDITAR',
      'USUARIO',
      'Se cambió el rol de ${target.fullName} a ${rol == 'admin' ? 'Administrador' : 'Técnico'}',
      entityId: target.id,
    );
  }

  // --- CRUD de Networks (edificios) ---
  Future<void> insertNetwork(NetworkGroup net) async {
    await _client.from('networks').upsert(net.toMap());
    await _logAction('CREAR', 'RED', 'Se creó el edificio "${net.name}" con IP base ${net.baseIp}', entityId: net.id);
  }

  Future<List<NetworkGroup>> getNetworks() async {
    final response = await _client.from('networks').select();
    final list = (response as List<dynamic>).map((json) => NetworkGroup.fromMap(json as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<void> updateNetwork(NetworkGroup net, {String? detalle}) async {
    await _client.from('networks').update(net.toMap()).eq('id', net.id);
    await _logAction('EDITAR', 'RED', detalle ?? 'Se actualizó el edificio "${net.name}"', entityId: net.id);
  }

  Future<void> deleteNetwork(String id, String name) async {
    await _client.from('networks').delete().eq('id', id);
    await _logAction('ELIMINAR', 'RED', 'Se eliminó el edificio "$name"', entityId: id);
  }

  // --- CRUD de Subnets (segmentos / VLAN) ---
  Future<void> insertSubnet(Subnet subnet, {bool log = false}) async {
    await _client.from('subnets').upsert(subnet.toMap());
    if (log) {
      await _logAction('CREAR', 'SEGMENTO', 'Se creó la VLAN "${subnet.name}" (${subnet.baseIp})', entityId: subnet.id);
    }
  }

  Future<List<Subnet>> getSubnets() async {
    final response = await _client.from('subnets').select();
    return _subnets(response);
  }

  Future<List<Subnet>> getSubnetsByNetwork(String networkId) async {
    final response = await _client.from('subnets').select().eq('networkId', networkId);
    return _subnets(response);
  }

  List<Subnet> _subnets(dynamic response) {
    final list = (response as List<dynamic>).map((json) => Subnet.fromMap(json as Map<String, dynamic>)).toList();
    // Las VLAN creadas antes de los campos nuevos se completan con los datos calculados.
    for (final s in list) {
      if (s.mask.isEmpty) s.fillDerivedFields();
    }
    list.sort((a, b) => (a.vlanNumber ?? 9999).compareTo(b.vlanNumber ?? 9999));
    return list;
  }

  Future<void> updateSubnet(Subnet subnet, {String? detalle}) async {
    await _client.from('subnets').update(subnet.toMap()).eq('id', subnet.id);
    await _logAction('EDITAR', 'SEGMENTO', detalle ?? 'Se actualizó la VLAN "${subnet.name}"', entityId: subnet.id);
  }

  Future<void> deleteSubnet(String id, String name) async {
    await _client.from('subnets').delete().eq('id', id);
    await _logAction('ELIMINAR', 'SEGMENTO', 'Se eliminó la VLAN "$name"', entityId: id);
  }

  // --- CRUD de Devices (equipos) ---
  Future<void> insertDevice(Device device) async {
    await _client.from('devices').upsert(device.toMap());
    await _logAction('CREAR', 'EQUIPO', 'Se registró el equipo "${device.name}" con IP ${device.ip}', entityId: device.id);
  }

  Future<List<Device>> getDevices() async {
    final response = await _client.from('devices').select();
    return (response as List<dynamic>).map((json) => Device.fromMap(json as Map<String, dynamic>)).toList();
  }

  Future<void> updateDevice(Device device) async {
    await _client.from('devices').update(device.toMap()).eq('id', device.id);
    await _logAction('EDITAR', 'EQUIPO', 'Se actualizó la información de "${device.name}" (IP: ${device.ip})', entityId: device.id);
  }

  Future<void> deleteDevice(String id, String name) async {
    await _client.from('devices').delete().eq('id', id);
    await _logAction('ELIMINAR', 'EQUIPO', 'Se eliminó el equipo "$name" de la red', entityId: id);
  }

  // --- CRUD de Switches ---
  Future<List<NetSwitch>> getAllSwitches() async {
    final response = await _client.from('switches').select().order('name', ascending: true);
    return (response as List<dynamic>).map((json) => NetSwitch.fromMap(json as Map<String, dynamic>)).toList();
  }

  Future<List<NetSwitch>> getSwitchesByNetwork(String networkId) async {
    final response = await _client.from('switches').select().eq('network_id', networkId).order('name', ascending: true);
    return (response as List<dynamic>).map((json) => NetSwitch.fromMap(json as Map<String, dynamic>)).toList();
  }

  /// Crea el switch y genera automáticamente sus [portCount] puertos.
  Future<void> insertSwitch(NetSwitch sw, {int portCount = 24}) async {
    await _client.from('switches').insert(sw.toMap());
    final ports = List.generate(
      portCount,
      (i) => NetPort(id: '${sw.id}p${i + 1}', switchId: sw.id, number: i + 1).toMap(),
    );
    if (ports.isNotEmpty) await _client.from('ports').insert(ports);
    await _logAction('CREAR', 'SWITCH', 'Se creó el switch "${sw.name}" con $portCount puertos', entityId: sw.id);
  }

  Future<void> updateSwitch(NetSwitch sw, {String? detalle}) async {
    await _client.from('switches').update(sw.toMap()).eq('id', sw.id);
    await _logAction('EDITAR', 'SWITCH', detalle ?? 'Se actualizó el switch "${sw.name}"', entityId: sw.id);
  }

  Future<void> deleteSwitch(NetSwitch sw) async {
    await _client.from('switches').delete().eq('id', sw.id);
    await _logAction('ELIMINAR', 'SWITCH', 'Se eliminó el switch "${sw.name}"', entityId: sw.id);
  }

  /// Deja todos los puertos del switch como nuevos (disponibles y sin datos).
  Future<void> resetSwitchPorts(NetSwitch sw) async {
    await _client.from('ports').update(_portReset).eq('switch_id', sw.id);
    await _logAction('EDITAR', 'SWITCH', 'Se restablecieron todos los puertos del switch "${sw.name}"', entityId: sw.id);
  }

  // --- CRUD de Puertos ---
  static const Map<String, dynamic> _portReset = {
    'subnet_id': null,
    'vlan': '',
    'departamento': '',
    'observaciones': '',
    'estado': 'Disponible',
  };

  Future<List<NetPort>> getAllPorts() async {
    final response = await _client.from('ports').select();
    return (response as List<dynamic>).map((json) => NetPort.fromMap(json as Map<String, dynamic>)).toList();
  }

  Future<List<NetPort>> getPortsBySwitch(String switchId) async {
    final response = await _client.from('ports').select().eq('switch_id', switchId).order('number', ascending: true);
    return (response as List<dynamic>).map((json) => NetPort.fromMap(json as Map<String, dynamic>)).toList();
  }

  Future<void> insertPort(NetPort port, String switchName) async {
    await _client.from('ports').insert(port.toMap());
    await _logAction('CREAR', 'PUERTO', 'Se agregó el puerto ${port.number} al switch "$switchName"', entityId: port.id);
  }

  Future<void> updatePort(NetPort port, String switchName, {String? detalle}) async {
    await _client.from('ports').update(port.toMap()).eq('id', port.id);
    await _logAction(
      'EDITAR',
      'PUERTO',
      detalle ?? 'Se actualizó el puerto ${port.number} del switch "$switchName"',
      entityId: port.id,
    );
  }

  Future<void> resetPort(NetPort port, String switchName) async {
    await _client.from('ports').update(_portReset).eq('id', port.id);
    await _logAction('EDITAR', 'PUERTO', 'Se restableció el puerto ${port.number} del switch "$switchName"', entityId: port.id);
  }

  Future<void> deletePort(NetPort port, String switchName) async {
    await _client.from('ports').delete().eq('id', port.id);
    await _logAction('ELIMINAR', 'PUERTO', 'Se eliminó el puerto ${port.number} del switch "$switchName"', entityId: port.id);
  }

  // --- CRUD de Incidencias ---
  Future<List<Incidencia>> getIncidencias() async {
    final response = await _client
        .from('incidencias')
        .select()
        .order('created_at', ascending: false);

    return (response as List).map((i) => Incidencia.fromJson(i)).toList();
  }

  Future<void> insertIncidencia(Incidencia incidencia) async {
    await _client.from('incidencias').insert(incidencia.toJson());
    // Registramos la acción en el log de auditoría general
    await _logAction('CREAR', 'INCIDENCIA', 'Se reportó una incidencia para el equipo "${incidencia.dispositivoNombre}"');
  }

  Future<void> updateIncidencia(Incidencia incidencia) async {
    await _client.from('incidencias').update(incidencia.toJson()).eq('id', incidencia.id!);
    await _logAction('EDITAR', 'INCIDENCIA', 'Se actualizó la incidencia del equipo "${incidencia.dispositivoNombre}"');
  }

  // --- ESTADÍSTICAS PARA EL INICIO ---
  Future<DashboardStats> getDashboardStats() async {
    final s = DashboardStats();
    final me = AppSession.profile;

    final networks = await getNetworks();
    final switches = await getAllSwitches();
    final ports = await getAllPorts();
    final vlans = await getSubnets();

    s.buildings = networks.length;
    // Edificios o switches que no están activos (revisión, mantenimiento, fuera de servicio).
    s.degradedInfra = networks.where((n) => n.estado != 'Activo').length + switches.where((x) => x.estado != 'Activo').length;
    try {
      s.pendingIncidents = (await getIncidencias()).where((i) => i.estado != 'Resuelto').length;
    } catch (_) {
      s.pendingIncidents = 0;
    }
    s.switches = switches.length;
    s.portsTotal = ports.length;
    s.portsOperational = ports.where((p) => p.operativo).length;
    final incident = ports.where((p) => p.estado == 'Con incidencia').toList();
    s.portsIncident = incident.length;
    final switchNames = {for (final sw in switches) sw.id: sw.name};
    final networkOfSwitch = {for (final sw in switches) sw.id: sw.networkId};
    final networkNames = {for (final n in networks) n.id: n.name};
    final byBuilding = <String, int>{};
    for (final p in ports) {
      final name = networkNames[networkOfSwitch[p.switchId]] ?? '-';
      byBuilding[name] = (byBuilding[name] ?? 0) + 1;
    }
    s.portsByBuilding = byBuilding.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    s.incidentPorts = incident.map((p) => '${switchNames[p.switchId] ?? 'Switch'} · Puerto ${p.number}').toList();
    s.vlansTotal = vlans.length;
    s.vlansActive = vlans.where((v) => v.estado == 'Activo').length;

    final logs = await getHistoryLogs(limit: 1000);
    s.changes = logs.where((l) => l.entityType != 'SESION').length;

    final startOfDay = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
    final mine = logs.where((l) => l.userId == me?.id).toList();
    final today = mine.where((l) => l.createdAt != null && l.createdAt!.isAfter(startOfDay)).toList();
    s.myActivityToday = today.length;
    final visible = AppSession.isAdmin ? logs : mine;
    s.recentActivity = visible.take(5).toList();
    final today0 = DateTime(startOfDay.year, startOfDay.month, startOfDay.day);
    s.weekDays = [for (var i = 6; i >= 0; i--) today0.subtract(Duration(days: i))];
    for (final l in visible) {
      if (l.createdAt == null) continue;
      final d = DateTime(l.createdAt!.year, l.createdAt!.month, l.createdAt!.day);
      final diff = today0.difference(d).inDays;
      if (diff >= 0 && diff < 7) s.changesWeek[6 - diff]++;
    }

    if (AppSession.isAdmin) {
      final profiles = await getProfiles();
      s.users = profiles.where((p) => p.isActive).length;
      s.pendingUsers = profiles.where((p) => p.isPending).length;
    }
    return s;
  }
}
