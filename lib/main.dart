import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://axsepafjqmzwbegfeypv.supabase.co', // URL corregida
    anonKey: 'sb_publishable_kcBRDshFIwoO6-afhUXNyQ_EQ-1ldtz',
  );

  runApp(const BitacoraRedApp());
}

class BitacoraRedApp extends StatelessWidget {
  const BitacoraRedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitacora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA), elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});
  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const NetworksScreen(), const DevicesScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF1D4ED8),
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.hub_outlined), activeIcon: Icon(Icons.hub), label: 'Redes'),
          BottomNavigationBarItem(icon: Icon(Icons.devices_outlined), activeIcon: Icon(Icons.devices), label: 'Equipos'),
        ],
      ),
    );
  }
}

// ==========================================
// APARTADO 1: REDES (ESTILO CLASSROOM)
// ==========================================
class NetworksScreen extends StatefulWidget {
  const NetworksScreen({super.key});
  @override
  State<NetworksScreen> createState() => _NetworksScreenState();
}

class _NetworksScreenState extends State<NetworksScreen> {
  final dbHelper = DatabaseHelper();
  List<NetworkGroup> networks = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final data = await dbHelper.getNetworks();
    setState(() => networks = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Infraestructura Global')),
      body: networks.isEmpty
          ? const Center(child: Text('Sin redes configuradas...'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: networks.length,
        itemBuilder: (context, index) {
          final net = networks[index];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SegmentsScreen(network: net)));
              _loadData();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 140,
              decoration: BoxDecoration(
                color: Color(net.colorValue),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(net.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) async {
                          if (value == 'delete') {
                            await dbHelper.deleteNetwork(net.id);
                            _loadData();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'delete', child: Text('Eliminar red', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text('IP Inicial: ${net.baseIp}', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                ],
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
        label: const Text('Agregar red', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ==========================================
// PANTALLA ANIDADA: SEGMENTOS DE LA RED
// ==========================================
class SegmentsScreen extends StatefulWidget {
  final NetworkGroup network;
  const SegmentsScreen({super.key, required this.network});
  @override
  State<SegmentsScreen> createState() => _SegmentsScreenState();
}

class _SegmentsScreenState extends State<SegmentsScreen> {
  final dbHelper = DatabaseHelper();
  List<Subnet> subnets = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final data = await dbHelper.getSubnetsByNetwork(widget.network.id);
    setState(() => subnets = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.network.name),
        backgroundColor: Color(widget.network.colorValue),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subnets.length,
        itemBuilder: (context, index) {
          final subnet = subnets[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: Color(widget.network.colorValue).withOpacity(0.2), child: Icon(Icons.router, color: Color(widget.network.colorValue))),
              title: Text(subnet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Rango: ${subnet.firstUsable} - ${subnet.lastUsable}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editSubnetName(context, subnet),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await dbHelper.deleteSubnet(subnet.id);
                      _loadData();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _editSubnetName(BuildContext context, Subnet subnet) async {
    TextEditingController ctrl = TextEditingController(text: subnet.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Segmento'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Nuevo nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              subnet.name = ctrl.text;
              await dbHelper.updateSubnet(subnet);
              if(context.mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ASISTENTE DE RED CON VALIDACIÓN DE IP
// ==========================================
class NetworkWizardScreen extends StatefulWidget {
  const NetworkWizardScreen({super.key});
  @override
  State<NetworkWizardScreen> createState() => _NetworkWizardScreenState();
}

class _NetworkWizardScreenState extends State<NetworkWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper();
  String networkName = '';
  String baseIp = '';
  int totalDevices = 64;
  int segments = 4;

  final List<Color> availableColors = [
    const Color(0xFF1D4ED8), const Color(0xFF047857), const Color(0xFFB91C1C),
    const Color(0xFFD97706), const Color(0xFF4338CA), const Color(0xFFBE185D)
  ];
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = availableColors[0];
  }

  Future<void> _generateSubnets() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // VALIDACIÓN: Evitar redes duplicadas
      final existingNetworks = await dbHelper.getNetworks();
      if (existingNetworks.any((net) => net.baseIp == baseIp)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: La red $baseIp ya existe. Elige otra IP Base.'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      String netId = DateTime.now().millisecondsSinceEpoch.toString();
      NetworkGroup newNetwork = NetworkGroup(
          id: netId, name: networkName, baseIp: baseIp, colorValue: selectedColor.value
      );
      await dbHelper.insertNetwork(newNetwork);

      int segmentSize = totalDevices ~/ segments;
      int currentIpLong = NetworkUtils.ipToLong(baseIp);

      for (int i = 0; i < segments; i++) {
        Subnet newSubnet = Subnet(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          networkId: netId, name: 'Segmento ${i + 1}',
          baseIp: NetworkUtils.longToIp(currentIpLong), size: segmentSize,
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
      appBar: AppBar(title: const Text('Nueva Red')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre de la Red', border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
              onSaved: (val) => networkName = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'IP Base (Ej. 192.168.0.0)', border: OutlineInputBorder()),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
              onSaved: (val) => baseIp = val!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Tamaño total', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number, initialValue: '64',
                    onSaved: (val) => totalDevices = int.parse(val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Segmentos', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number, initialValue: '4',
                    onSaved: (val) => segments = int.parse(val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Color de la tarjeta', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: availableColors.map((color) {
                return GestureDetector(
                  onTap: () => setState(() => selectedColor = color),
                  child: CircleAvatar(
                    backgroundColor: color,
                    child: selectedColor == color ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _generateSubnets,
              style: ElevatedButton.styleFrom(backgroundColor: selectedColor, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Crear Red', style: TextStyle(color: Colors.white, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

// ==========================================
// APARTADO 2: DISPOSITIVOS (AGRUPADOS Y BUSCADOR GLOBAL)
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
  List<NetworkGroup> networks = [];
  String searchQuery = '';

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final devs = await dbHelper.getDevices();
    final subs = await dbHelper.getSubnets();
    final nets = await dbHelper.getNetworks();
    setState(() { devices = devs; subnets = subs; networks = nets; });
  }

  @override
  Widget build(BuildContext context) {
    // Aplicamos el filtro global a todos los dispositivos
    final filteredDevices = devices.where((d) {
      final query = searchQuery.toLowerCase();
      return d.name.toLowerCase().contains(query) ||
          d.ip.toLowerCase().contains(query) ||
          d.mac.toLowerCase().contains(query) ||
          d.manufacturer.toLowerCase().contains(query) ||
          d.location.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventario de equipos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: networks.length,
              itemBuilder: (context, netIndex) {
                final net = networks[netIndex];

                final netSubnets = subnets.where((s) => s.networkId == net.id).toList();
                final hasMatchingDevices = filteredDevices.any((d) => netSubnets.any((s) => s.id == d.subnetId));

                if (!hasMatchingDevices && filteredDevices.isNotEmpty) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0))),
                  child: ExpansionTile(
                    initiallyExpanded: searchQuery.isNotEmpty,
                    leading: Icon(Icons.hub, color: Color(net.colorValue)),
                    title: Text(net.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(net.baseIp),
                    children: netSubnets.map((subnet) {

                      final subDevices = filteredDevices.where((d) => d.subnetId == subnet.id).toList();
                      if (subDevices.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ExpansionTile(
                          initiallyExpanded: searchQuery.isNotEmpty,
                          leading: const Icon(Icons.router, color: Colors.blueGrey),
                          title: Text(subnet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: subDevices.map((device) {
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 40, right: 16),
                              leading: const Icon(Icons.computer, color: Color(0xFF1D4ED8)),
                              title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('IP: ${device.ip} | MAC: ${device.mac}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () async {
                                  await dbHelper.deleteDevice(device.id);
                                  _loadData();
                                },
                              ),
                              onTap: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (context) => DeviceFormScreen(device: device, subnets: subnets)));
                                _loadData();
                              },
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
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
        label: const Text('Agregar equipo', style: TextStyle(color: Colors.white)),
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