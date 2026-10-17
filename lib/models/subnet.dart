import '../controllers/network_utils.dart';

/// Segmento de red / VLAN de un edificio.
class Subnet {
  String id, networkId, name, baseIp;
  int size;

  // Datos de la VLAN (formulario de "Segmentos y VLAN")
  int? vlanNumber;
  String estado, mask, gateway, broadcast, ipStart, ipEnd, excluded;
  int? hosts;

  Subnet({
    required this.id,
    required this.networkId,
    required this.name,
    required this.baseIp,
    required this.size,
    this.vlanNumber,
    this.estado = 'Activo',
    this.mask = '',
    this.gateway = '',
    this.broadcast = '',
    this.ipStart = '',
    this.ipEnd = '',
    this.excluded = '',
    this.hosts,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'networkId': networkId,
    'name': name,
    'baseIp': baseIp,
    'size': size,
    'vlan_number': vlanNumber,
    'estado': estado,
    'mask': mask,
    'gateway': gateway,
    'broadcast': broadcast,
    'ip_start': ipStart,
    'ip_end': ipEnd,
    'excluded': excluded,
    'hosts': hosts,
  };

  factory Subnet.fromMap(Map<String, dynamic> map) => Subnet(
    id: map['id'] as String,
    networkId: map['networkId'] as String,
    name: map['name'] as String,
    baseIp: map['baseIp'] as String,
    size: map['size'] as int,
    vlanNumber: map['vlan_number'] as int?,
    estado: map['estado'] as String? ?? 'Activo',
    mask: map['mask'] as String? ?? '',
    gateway: map['gateway'] as String? ?? '',
    broadcast: map['broadcast'] as String? ?? '',
    ipStart: map['ip_start'] as String? ?? '',
    ipEnd: map['ip_end'] as String? ?? '',
    excluded: map['excluded'] as String? ?? '',
    hosts: map['hosts'] as int?,
  );

  int get networkLong => NetworkUtils.ipToLong(baseIp);
  String get firstUsable => NetworkUtils.longToIp(networkLong + 1);
  String get lastUsable => NetworkUtils.longToIp(networkLong + size - 2);
  bool isIpInUsableRange(String ip) {
    int ipLong = NetworkUtils.ipToLong(ip);
    return ipLong >= (networkLong + 1) && ipLong <= (networkLong + size - 2);
  }

  /// ¿La IP cae dentro del rango excluido ("a.b.c.d" o "a.b.c.d - e.f.g.h")?
  bool isIpExcluded(String ip) {
    if (excluded.trim().isEmpty) return false;
    final parts = excluded.split(RegExp(r'\s*[-–]\s*'));
    final v = NetworkUtils.ipToLong(ip);
    final from = NetworkUtils.ipToLong(parts.first);
    final to = NetworkUtils.ipToLong(parts.length > 1 ? parts[1] : parts.first);
    return v >= from && v <= to;
  }

  /// Etiqueta corta para listas: "VLAN 10 · Alumnos" o solo el nombre.
  String get label => vlanNumber != null ? 'VLAN $vlanNumber · $name' : name;

  /// Datos de red calculados a partir de la IP base y el tamaño.
  /// Se usan para completar los campos de las VLAN generadas automáticamente.
  void fillDerivedFields() {
    mask = NetworkUtils.maskFromSize(size);
    broadcast = NetworkUtils.longToIp(networkLong + size - 1);
    gateway = firstUsable;
    ipStart = NetworkUtils.longToIp(networkLong + 2);
    ipEnd = lastUsable;
    hosts = size - 2;
  }
}
