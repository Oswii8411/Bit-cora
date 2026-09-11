import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/device.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:bitacora_red/views/formulario_equipo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

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
                hintText: 'Buscar a nivel global...',
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
                                  await dbHelper.deleteDevice(device.id, device.name);
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