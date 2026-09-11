import '../controllers/network_utils.dart';

class Subnet {
  String id, networkId, name, baseIp;
  int size;
  Subnet({
    required this.id,
    required this.networkId,
    required this.name,
    required this.baseIp,
    required this.size,
  });
  Map<String, dynamic> toMap() => {
    'id': id,
    'networkId': networkId,
    'name': name,
    'baseIp': baseIp,
    'size': size,
  };
  factory Subnet.fromMap(Map<String, dynamic> map) => Subnet(
    id: map['id'] as String,
    networkId: map['networkId'] as String,
    name: map['name'] as String,
    baseIp: map['baseIp'] as String,
    size: map['size'] as int,
  );
  int get networkLong => NetworkUtils.ipToLong(baseIp);
  String get firstUsable => NetworkUtils.longToIp(networkLong + 1);
  String get lastUsable => NetworkUtils.longToIp(networkLong + size - 2);
  bool isIpInUsableRange(String ip) {
    int ipLong = NetworkUtils.ipToLong(ip);
    return ipLong >= (networkLong + 1) && ipLong <= (networkLong + size - 2);
  }
}
