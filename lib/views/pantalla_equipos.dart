import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/motion.dart';
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
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: networks.length,
              itemBuilder: (context, netIndex) {
                final net = networks[netIndex];
                final netSubnets = subnets.where((s) => s.networkId == net.id).toList();
                final hasMatchingDevices = filteredDevices.any((d) => netSubnets.any((s) => s.id == d.subnetId));

                if (!hasMatchingDevices && filteredDevices.isNotEmpty) return const SizedBox.shrink();

                return FadeSlideIn(
                  index: netIndex,
                  child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    shape: const Border(),
                    collapsedShape: const Border(),
                    initiallyExpanded: searchQuery.isNotEmpty,
                    leading: Icon(Icons.hub, color: accessibleColor(Color(net.colorValue))),
                    title: Text(net.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Text(net.baseIp, style: const TextStyle(color: AppColors.inkMuted)),
                    children: netSubnets.map((subnet) {

                      final subDevices = filteredDevices.where((d) => d.subnetId == subnet.id).toList();
                      if (subDevices.isEmpty) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: ExpansionTile(
                          initiallyExpanded: searchQuery.isNotEmpty,
                          leading: const Icon(Icons.router, color: AppColors.inkMuted),
                          title: Text(subnet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          children: subDevices.map((device) {
                            return ListTile(
                              contentPadding: const EdgeInsets.only(left: 40, right: 16),
                              leading: const Icon(Icons.computer, color: AppColors.primary),
                              title: Text(device.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('IP: ${device.ip} | MAC: ${device.mac}', style: const TextStyle(color: AppColors.inkMuted)),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: AppColors.error, size: 22),
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
        icon: const Icon(Icons.add),
        label: const Text('Agregar equipo'),
      ),
    );
  }
}