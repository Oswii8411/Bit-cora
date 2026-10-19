import 'dart:async';

import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/models/device.dart';
import 'package:bitacora_red/models/history_log.dart';
import 'package:bitacora_red/models/net_port.dart';
import 'package:bitacora_red/models/net_switch.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/profile.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:intl/intl.dart';
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
  /// Fuentes que no se pudieron cargar ("nombre: motivo"). Si no está vacía, el
  /// resumen se muestra incompleto en lugar de quedarse cargando.
  List<String> failed = [];
  /// Los 7 días a los que corresponde `changesWeek` (admin: movimientos de todos; técnico: los suyos).
  List<DateTime> weekDays = [];
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // --- CACHÉ ---
  // Las listas se guardan unos segundos para que cambiar de pantalla sea
  // instantáneo y varias pantallas no pidan lo mismo a la vez. Cualquier
  // escritura vacía la caché, así que lo que se ve siempre está al día.
  final Map<String, (DateTime, Object)> _cache = {};
  final Map<String, (DateTime, Future<Object>)> _inflight = {};
  int _generation = 0;
  static const Duration _ttl = Duration(seconds: 45);
  // Si una consulta no responde en este tiempo se cancela con error (por ejemplo al
  // volver de segundo plano con la conexión cortada) para no dejar la app cargando.
  static const Duration _timeout = Duration(seconds: 20);

  Future<List<T>> _cachedList<T>(String key, Future<List<T>> Function() loader) async {
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.$1) < _ttl) {
      return List<T>.of(hit.$2 as List<T>);
    }
    // Se reutiliza una petición en curso solo si es reciente.
    final pending = _inflight[key];
    if (pending != null && DateTime.now().difference(pending.$1) < _timeout) {
      return List<T>.of((await pending.$2) as List<T>);
    }

    final generation = _generation;
    final future = loader().timeout(_timeout).then<Object>((value) {
      // Si hubo una escritura mientras cargaba, estos datos ya pueden estar viejos.
      if (generation == _generation) _cache[key] = (DateTime.now(), value);
      return value;
    });
    _inflight[key] = (DateTime.now(), future);
    // Pase lo que pase (éxito, error o tiempo agotado) se libera la petición pendiente.
    future.whenComplete(() {
      if (_inflight[key]?.$2 == future) _inflight.remove(key);
    }).ignore();
    return List<T>.of((await future) as List<T>);
  }

  /// Vacía la caché. No avisa a las pantallas (se usa al actualizar a mano).
  void invalidateCache() {
    _generation++;
    _cache.clear();
    _inflight.clear();
  }

  /// Descarta lo guardado y manda actualizar las pantallas abiertas (al volver
  /// de segundo plano, por ejemplo).
  void forceRefresh() {
    invalidateCache();
    changes.value++;
  }

  /// Sube cada vez que cambian los datos (crear, editar, eliminar...). Las
  /// pantallas abiertas lo escuchan y se actualizan solas, sin círculo de carga.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);
  Timer? _notifyTimer;

  /// Una escritura terminó: vacía la caché y avisa (una sola vez aunque haya
  /// varias escrituras seguidas, por ejemplo al crear un switch con sus puertos).
  void _markChanged() {
    invalidateCache();
    _notifyTimer?.cancel();
    _notifyTimer = Timer(const Duration(milliseconds: 350), () => changes.value++);
  }

  /// Calienta la caché con las listas principales (al iniciar sesión).
  Future<void> prefetch() async {
    try {
      await Future.wait([
        getNetworks(),
        getAllSwitches(),
        getAllPorts(),
        getSubnets(),
        getHistoryLogs(userId: AppSession.isAdmin ? null : AppSession.profile?.id),
        getIncidencias(),
      ]);
    } catch (_) {
      // Es solo una optimización: si falla, cada pantalla pedirá lo suyo.
    }
  }

  // --- LOG DE AUDITORÍA (bitácora) ---
  Future<void> _logAction(
    String actionType,
    String entityType,
    String description, {
    String? entityId,
  }) async {
    invalidateCache();
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
    _markChanged();
  }

  /// Registra inicios y cierres de sesión, reportes, etc.
  Future<void> logEvent(String actionType, String entityType, String description) =>
      _logAction(actionType, entityType, description);

  /// Bitácora completa, o solo los movimientos de [userId].
  Future<List<HistoryLog>> getHistoryLogs({String? userId, int limit = 500}) {
    return _cachedList('logs:${userId ?? 'all'}:$limit', () async {
      var query = _client.from('history_logs').select();
      if (userId != null) query = query.eq('user_id', userId);
      final response = await query.order('created_at', ascending: false).limit(limit);
      return (response as List<dynamic>).map((json) => HistoryLog.fromMap(json as Map<String, dynamic>)).toList();
    });
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

  Future<List<Profile>> getProfiles() {
    return _cachedList('profiles', () async {
      final res = await _client.from('profiles').select().order('created_at', ascending: false);
      return (res as List<dynamic>).map((j) => Profile.fromMap(j as Map<String, dynamic>)).toList();
    });
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

  Future<List<NetworkGroup>> getNetworks() {
    return _cachedList('networks', () async {
      final response = await _client.from('networks').select();
      final list = (response as List<dynamic>).map((json) => NetworkGroup.fromMap(json as Map<String, dynamic>)).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
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
    _markChanged();
    if (log) {
      await _logAction('CREAR', 'SEGMENTO', 'Se creó la VLAN "${subnet.name}" (${subnet.baseIp})', entityId: subnet.id);
    }
  }

  Future<List<Subnet>> getSubnets() {
    return _cachedList('subnets', () async {
      final response = await _client.from('subnets').select();
      return _subnets(response);
    });
  }

  Future<List<Subnet>> getSubnetsByNetwork(String networkId) async {
    final all = await getSubnets();
    return all.where((x) => x.networkId == networkId).toList();
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

  Future<List<Device>> getDevices() {
    return _cachedList('devices', () async {
      final response = await _client.from('devices').select();
      return (response as List<dynamic>).map((json) => Device.fromMap(json as Map<String, dynamic>)).toList();
    });
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
  Future<List<NetSwitch>> getAllSwitches() {
    return _cachedList('switches', () async {
      final response = await _client.from('switches').select().order('name', ascending: true);
      return (response as List<dynamic>).map((json) => NetSwitch.fromMap(json as Map<String, dynamic>)).toList();
    });
  }

  Future<List<NetSwitch>> getSwitchesByNetwork(String networkId) async {
    final all = await getAllSwitches();
    return all.where((x) => x.networkId == networkId).toList();
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

  Future<List<NetPort>> getAllPorts() {
    return _cachedList('ports', () async {
      final response = await _client.from('ports').select();
      return (response as List<dynamic>).map((json) => NetPort.fromMap(json as Map<String, dynamic>)).toList();
    });
  }

  Future<List<NetPort>> getPortsBySwitch(String switchId) async {
    final all = await getAllPorts();
    return all.where((x) => x.switchId == switchId).toList()..sort((a, b) => a.number.compareTo(b.number));
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

  String _actor() => AppSession.profile?.fullName ?? _client.auth.currentUser?.email ?? 'Usuario';

  /// Marca el puerto "Con incidencia" y crea la incidencia vinculada a él.
  /// La incidencia se guarda primero: si falla, el puerto no cambia.
  Future<void> reportPortIncident({
    required NetPort port,
    required String switchName,
    required String descripcion,
    String prioridad = 'Media',
  }) async {
    final actor = _actor();
    final stamp = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    await _client.from('incidencias').insert(
          Incidencia(
            dispositivoNombre: '$switchName · Puerto ${port.number}',
            descripcion: descripcion,
            accionRealizada: 'Pendiente de revisión',
            estado: 'Pendiente',
            prioridad: prioridad,
            responsable: actor,
            historialCambios: '[$stamp] $actor: Reportó la incidencia.',
            puertoId: port.id,
          ).toJson(),
        );
    port.estado = 'Con incidencia';
    await _client.from('ports').update(port.toMap()).eq('id', port.id);
    await _logAction(
      'CREAR',
      'INCIDENCIA',
      'Se reportó una incidencia en el puerto ${port.number} del switch "$switchName": $descripcion',
      entityId: port.id,
    );
  }

  /// Resuelve la incidencia del puerto: guarda quién, cuándo y cómo la resolvió, y
  /// deja el puerto en [estadoFinal]. Si el puerto no tenía una incidencia vinculada
  /// (por ejemplo, se marcó antes de existir esta función) se crea ya resuelta, para
  /// que quede constancia en Incidencias.
  Future<void> resolvePortIncident({
    required NetPort port,
    required String switchName,
    required String solucion,
    required String estadoFinal,
  }) async {
    final actor = _actor();
    final now = DateTime.now();
    final stamp = DateFormat('dd/MM/yyyy HH:mm').format(now);
    final entry = '[$stamp] $actor: Resolvió la incidencia. $solucion';

    final all = await getIncidencias();
    final open = all.where((i) => i.puertoId == port.id && !i.resuelta).toList();

    if (open.isEmpty) {
      await _client.from('incidencias').insert(
            Incidencia(
              dispositivoNombre: '$switchName · Puerto ${port.number}',
              descripcion: port.observaciones.isNotEmpty ? port.observaciones : 'Incidencia en el puerto ${port.number}',
              accionRealizada: solucion,
              estado: 'Resuelto',
              prioridad: 'Media',
              responsable: actor,
              historialCambios: entry,
              puertoId: port.id,
              solucion: solucion,
              resueltoPor: actor,
              resueltoEn: now,
            ).toJson(),
          );
    } else {
      for (final inc in open) {
        final historial = inc.historialCambios.isEmpty ? entry : '${inc.historialCambios}\n$entry';
        await _client.from('incidencias').update({
          'estado': 'Resuelto',
          'accion_realizada': solucion,
          'solucion': solucion,
          'resuelto_por': actor,
          'resuelto_en': now.toUtc().toIso8601String(),
          'historial_cambios': historial,
        }).eq('id', inc.id!);
      }
    }

    port.estado = estadoFinal;
    await _client.from('ports').update(port.toMap()).eq('id', port.id);
    await _logAction(
      'EDITAR',
      'INCIDENCIA',
      'Se resolvió la incidencia del puerto ${port.number} del switch "$switchName": $solucion',
      entityId: port.id,
    );
  }

  /// Al resolver una incidencia desde Incidencias, libera su puerto si seguía
  /// marcado "Con incidencia".
  Future<void> releasePortIfIncident(String portId) async {
    await _client.from('ports').update({'estado': 'Disponible'}).eq('id', portId).eq('estado', 'Con incidencia');
    _markChanged();
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
  Future<List<Incidencia>> getIncidencias() {
    return _cachedList('incidencias', () async {
      final response = await _client
          .from('incidencias')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((i) => Incidencia.fromJson(i)).toList();
    });
  }

  Future<void> insertIncidencia(Incidencia incidencia) async {
    await _client.from('incidencias').insert(incidencia.toJson());
    // Registramos la acción en el log de auditoría general
    await _logAction('CREAR', 'INCIDENCIA', 'Se reportó una incidencia para el equipo "${incidencia.dispositivoNombre}"');
  }

  /// Con [clearResolution] se borran los datos de resolución (al reabrir una incidencia).
  Future<void> updateIncidencia(Incidencia incidencia, {bool clearResolution = false}) async {
    final data = incidencia.toJson();
    if (clearResolution) {
      data['resuelto_por'] = null;
      data['resuelto_en'] = null;
      data['solucion'] = '';
    }
    await _client.from('incidencias').update(data).eq('id', incidencia.id!);
    await _logAction('EDITAR', 'INCIDENCIA', 'Se actualizó la incidencia del equipo "${incidencia.dispositivoNombre}"');
  }

  // --- ESTADÍSTICAS PARA EL INICIO ---
  Future<DashboardStats> getDashboardStats() async {
    final s = DashboardStats();
    final me = AppSession.profile;

    // Todas las consultas arrancan a la vez (antes se esperaba una por una).
    final fNetworks = getNetworks();
    final fSwitches = getAllSwitches();
    final fPorts = getAllPorts();
    final fVlans = getSubnets();
    final fLogs = getHistoryLogs();
    final fIncidents = getIncidencias().catchError((_) => <Incidencia>[]);
    final fProfiles = AppSession.isAdmin ? getProfiles() : null;

    // Cada fuente se espera por separado: si una falla, el Inicio se muestra con
    // lo demás y avisa cuál falló (antes una sola falla dejaba todo cargando).
    Future<T> guard<T>(String name, Future<T> f, T fallback) async {
      try {
        return await f;
      } catch (e) {
        final msg = e.toString().replaceAll('\n', ' ');
        s.failed.add('$name: ${msg.length > 140 ? '${msg.substring(0, 140)}…' : msg}');
        return fallback;
      }
    }

    final networks = await guard('edificios', fNetworks, <NetworkGroup>[]);
    final switches = await guard('switches', fSwitches, <NetSwitch>[]);
    final ports = await guard('puertos', fPorts, <NetPort>[]);
    final vlans = await guard('VLAN', fVlans, <Subnet>[]);

    s.buildings = networks.length;
    // Edificios o switches que no están activos (revisión, mantenimiento, fuera de servicio).
    s.degradedInfra = networks.where((n) => n.estado != 'Activo').length + switches.where((x) => x.estado != 'Activo').length;
    s.pendingIncidents = (await guard('incidencias', fIncidents, <Incidencia>[])).where((i) => i.estado != 'Resuelto').length;
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

    final logs = await guard('bitácora', fLogs, <HistoryLog>[]);
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
      final profiles = await guard('usuarios', fProfiles!, <Profile>[]);
      s.users = profiles.where((p) => p.isActive).length;
      s.pendingUsers = profiles.where((p) => p.isPending).length;
    }
    // Si casi todo falló no hay nada útil que mostrar: se reporta como error.
    if (s.failed.length >= 4) throw Exception(s.failed.join('\n'));
    return s;
  }
}
