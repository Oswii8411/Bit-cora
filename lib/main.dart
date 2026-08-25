import 'package:flutter/material.dart';
import 'database_helper.dart'; // <-- Enlazamos nuestra base de datos y modelos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BitacoraRedApp());
}

class BitacoraRedApp extends StatelessWidget {
  const BitacoraRedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetControl ITSU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA), // Fondo claro
        primaryColor: const Color(0xFF1D4ED8), // Azul vibrante
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA),
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D4ED8),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

// ==========================================
// NAVEGACIÓN PRINCIPAL (LOS DOS APARTADOS)
// ==========================================

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const NetworksScreen(),
    const DevicesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF1D4ED8),
          unselectedItemColor: const Color(0xFF64748B),
          showUnselectedLabels: true,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.hub_outlined), activeIcon: Icon(Icons.hub), label: 'Segmentación'),
            BottomNavigationBarItem(icon: Icon(Icons.devices_outlined), activeIcon: Icon(Icons.devices), label: 'Equipos'),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// APARTADO 1: GESTIÓN DE REDES (CRUD)
// ==========================================

class NetworksScreen extends StatefulWidget {
  const NetworksScreen({super.key});

  @override
  State<NetworksScreen> createState() => _NetworksScreenState();
}

class _NetworksScreenState extends State<NetworksScreen> {
  final dbHelper = DatabaseHelper();
  List<Subnet> subnets = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await dbHelper.getSubnets();
    setState(() => subnets = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segmentación de red')),
      body: subnets.isEmpty
          ? const Center(child: Text('No hay redes configuradas.', style: TextStyle(color: Color(0xFF64748B))))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subnets.length,
        itemBuilder: (context, index) {
          final subnet = subnets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.router, color: Color(0xFF1D4ED8)),
                ),
                title: Text(
                  subnet.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Red: ${subnet.networkIp}\nRango: ${subnet.firstUsable} - ${subnet.lastUsable}',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _editSubnetName(context, subnet);
                      _loadData();
                    } else if (value == 'delete') {
                      await dbHelper.deleteSubnet(subnet.id);
                      _loadData();
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar información')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar segmento', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => const NetworkWizardScreen()));
          _loadData();
        },
        backgroundColor: const Color(0xFF1D4ED8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar red', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _editSubnetName(BuildContext context, Subnet subnet) async {
    TextEditingController ctrl = TextEditingController(text: subnet.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Nombre'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'Nuevo nombre (Ej. Sistemas)')
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B)))
          ),
          ElevatedButton(
            onPressed: () async {
              subnet.name = ctrl.text;
              await dbHelper.updateSubnet(subnet);
              if(context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class NetworkWizardScreen extends StatefulWidget {
  const NetworkWizardScreen({super.key});

  @override
  State<NetworkWizardScreen> createState() => _NetworkWizardScreenState();
}

class _NetworkWizardScreenState extends State<NetworkWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();
  String baseIp = '';
  int totalDevices = 64;
  int segments = 4;

  Future<void> _generateSubnets() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      int segmentSize = totalDevices ~/ segments;
      int currentIpLong = NetworkUtils.ipToLong(baseIp);

      for (int i = 0; i < segments; i++) {
        Subnet newSubnet = Subnet(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          name: 'Segmento ${i + 1}',
          baseIp: NetworkUtils.longToIp(currentIpLong),
          size: segmentSize,
        );
        await dbHelper.insertSubnet(newSubnet);
        currentIpLong += segmentSize;
      }
      if(mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistente de red')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text('Configuración inicial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'IP Base (Ej. 192.168.0.0)', prefixIcon: Icon(Icons.numbers)),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
              onSaved: (val) => baseIp = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Tamaño total de la red', prefixIcon: Icon(Icons.group_work)),
              keyboardType: TextInputType.number,
              initialValue: '64',
              onSaved: (val) => totalDevices = int.parse(val!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Cantidad de segmentos', prefixIcon: Icon(Icons.pie_chart)),
              keyboardType: TextInputType.number,
              initialValue: '4',
              onSaved: (val) => segments = int.parse(val!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _generateSubnets,
              child: const Text('Generar Segmentos'),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// APARTADO 2: GESTIÓN DE DISPOSITIVOS (CRUD)
// ==========================================

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final dbHelper = DatabaseHelper();
  List<Device> devices = [];
  List<Subnet> subnets = [];
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final devs = await dbHelper.getDevices();
    final subs = await dbHelper.getSubnets();
    setState(() {
      devices = devs;
      subnets = subs;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = devices.where((d) => d.name.toLowerCase().contains(searchQuery.toLowerCase()) || d.ip.contains(searchQuery)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de equipos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o IP...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final device = filtered[index];
                final subnet = subnets.firstWhere(
                        (s) => s.id == device.subnetId,
                    orElse: () => Subnet(id: '', name: 'Desconocida', baseIp: '', size: 0)
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.computer, color: Color(0xFF1D4ED8)),
                      ),
                      title: Text(
                        device.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'IP: ${device.ip}\nMAC: ${device.mac}\nRed: ${subnet.name}',
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        ),
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceFormScreen(device: device, subnets: subnets)));
                            _loadData();
                          } else if (value == 'delete') {
                            await dbHelper.deleteDevice(device.id);
                            _loadData();
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Editar información')),
                          const PopupMenuItem(value: 'delete', child: Text('Eliminar equipo', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceFormScreen(subnets: subnets)));
          _loadData();
        },
        backgroundColor: const Color(0xFF1D4ED8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar equipo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class DeviceFormScreen extends StatefulWidget {
  final Device? device;
  final List<Subnet> subnets;
  const DeviceFormScreen({super.key, this.device, required this.subnets});

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();

  late String name, mac, manufacturer, location, ip;
  String? selectedSubnetId;

  @override
  void initState() {
    super.initState();
    name = widget.device?.name ?? '';
    mac = widget.device?.mac ?? '';
    manufacturer = widget.device?.manufacturer ?? '';
    location = widget.device?.location ?? '';
    ip = widget.device?.ip ?? '';
    selectedSubnetId = widget.device?.subnetId;
  }

  Future<void> saveDevice() async {
    if (_formKey.currentState!.validate()) {
      if (selectedSubnetId == null) return;
      _formKey.currentState!.save();

      Subnet selectedSubnet = widget.subnets.firstWhere((s) => s.id == selectedSubnetId);
      if (!selectedSubnet.isIpInUsableRange(ip)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('La IP $ip NO pertenece a ${selectedSubnet.name} (${selectedSubnet.firstUsable} - ${selectedSubnet.lastUsable})'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ));
        return;
      }

      Device newDevice = Device(
        id: widget.device?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name, mac: mac, manufacturer: manufacturer, location: location, ip: ip, subnetId: selectedSubnetId!,
      );

      if (widget.device == null) {
        await dbHelper.insertDevice(newDevice);
      } else {
        await dbHelper.updateDevice(newDevice);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device == null ? 'Nuevo Equipo' : 'Editar Equipo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Segmento de Red'),
              value: selectedSubnetId,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              items: widget.subnets.map((s) {
                return DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.firstUsable} - ${s.lastUsable})'));
              }).toList(),
              onChanged: (val) => setState(() => selectedSubnetId = val),
              validator: (val) => val == null ? 'Seleccione un segmento' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: ip,
              decoration: const InputDecoration(labelText: 'IP Asignada (Ej. 192.168.0.5)'),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
              onSaved: (val) => ip = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Nombre del dispositivo'),
              onSaved: (val) => name = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: mac,
              decoration: const InputDecoration(labelText: 'MAC Address'),
              onSaved: (val) => mac = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: manufacturer,
              decoration: const InputDecoration(labelText: 'Marca / Fabricante'),
              onSaved: (val) => manufacturer = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: location,
              decoration: const InputDecoration(labelText: 'Ubicación'),
              onSaved: (val) => location = val!,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
                onPressed: saveDevice,
                child: const Text('Guardar Configuración')
            )
          ],
        ),
      ),
    );
  }
}