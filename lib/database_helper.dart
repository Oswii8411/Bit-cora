import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // <-- El alias 'p' evita la colisión de 'context'

// ==========================================
// LÓGICA DE RED Y MATEMÁTICAS IP
// ==========================================
class NetworkUtils {
  static int ipToLong(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return 0;
    return (int.parse(parts[0]) << 24) +
        (int.parse(parts[1]) << 16) +
        (int.parse(parts[2]) << 8) +
        int.parse(parts[3]);
  }

  static String longToIp(int longVal) {
    return '${(longVal >> 24) & 255}.${(longVal >> 16) & 255}.${(longVal >> 8) & 255}.${longVal & 255}';
  }
}

// ==========================================
// MODELOS DE DATOS
// ==========================================
class Subnet {
  String id;
  String name;
  String baseIp;
  int size;

  Subnet({required this.id, required this.name, required this.baseIp, required this.size});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'baseIp': baseIp, 'size': size};

  factory Subnet.fromMap(Map<String, dynamic> map) {
    return Subnet(id: map['id'], name: map['name'], baseIp: map['baseIp'], size: map['size']);
  }

  int get networkLong => NetworkUtils.ipToLong(baseIp);
  String get firstUsable => NetworkUtils.longToIp(networkLong + 1);
  String get lastUsable => NetworkUtils.longToIp(networkLong + size - 2);
  String get broadcastIp => NetworkUtils.longToIp(networkLong + size - 1);
  String get networkIp => baseIp;

  bool isIpInUsableRange(String ip) {
    int ipLong = NetworkUtils.ipToLong(ip);
    return ipLong >= (networkLong + 1) && ipLong <= (networkLong + size - 2);
  }
}

class Device {
  String id, name, mac, manufacturer, location, ip, subnetId;

  Device({
    required this.id, required this.name, required this.mac,
    required this.manufacturer, required this.location,
    required this.ip, required this.subnetId,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'mac': mac, 'manufacturer': manufacturer,
    'location': location, 'ip': ip, 'subnetId': subnetId,
  };

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      id: map['id'], name: map['name'], mac: map['mac'],
      manufacturer: map['manufacturer'], location: map['location'],
      ip: map['ip'], subnetId: map['subnetId'],
    );
  }
}

// ==========================================
// CAPA DE BASE DE DATOS (SQLITE)
// ==========================================
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Aquí usamos el alias 'p' para usar el método join del paquete path
    String dbPath = p.join(await getDatabasesPath(), 'bitacora_red.db');
    
      print('\n=============================================');
      print('📂 RUTA DE LA BASE DE DATOS: $dbPath');
      print('=============================================\n');

    return await openDatabase(
      dbPath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON'); // Reglas de integridad activadas
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE subnets(
            id TEXT PRIMARY KEY,
            name TEXT,
            baseIp TEXT,
            size INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE devices(
            id TEXT PRIMARY KEY,
            name TEXT,
            mac TEXT,
            manufacturer TEXT,
            location TEXT,
            ip TEXT,
            subnetId TEXT,
            FOREIGN KEY (subnetId) REFERENCES subnets (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // --- Consultas ---
  Future<void> insertSubnet(Subnet subnet) async {
    final db = await database;
    await db.insert('subnets', subnet.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Subnet>> getSubnets() async {
    final db = await database;
    final maps = await db.query('subnets');
    return List.generate(maps.length, (i) => Subnet.fromMap(maps[i]));
  }

  Future<void> updateSubnet(Subnet subnet) async {
    final db = await database;
    await db.update('subnets', subnet.toMap(), where: 'id = ?', whereArgs: [subnet.id]);
  }

  Future<void> deleteSubnet(String id) async {
    final db = await database;
    await db.delete('subnets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertDevice(Device device) async {
    final db = await database;
    await db.insert('devices', device.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Device>> getDevices() async {
    final db = await database;
    final maps = await db.query('devices');
    return List.generate(maps.length, (i) => Device.fromMap(maps[i]));
  }

  Future<void> updateDevice(Device device) async {
    final db = await database;
    await db.update('devices', device.toMap(), where: 'id = ?', whereArgs: [device.id]);
  }

  Future<void> deleteDevice(String id) async {
    final db = await database;
    await db.delete('devices', where: 'id = ?', whereArgs: [id]);
  }
}