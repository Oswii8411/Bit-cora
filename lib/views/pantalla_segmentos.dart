import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/device.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:bitacora_red/views/formulario_equipo.dart';
import 'package:bitacora_red/views/pantalla_switches.dart';
import 'package:bitacora_red/views/pantalla_vlan.dart';
import 'package:bitacora_red/widgets/estado_widgets.dart';
import 'package:flutter/material.dart';

/// Detalle de un edificio: sus switches, sus VLAN y sus equipos.
class SegmentsScreen extends StatelessWidget {
  final NetworkGroup network;
  const SegmentsScreen({super.key, required this.network});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(network.name),
          backgroundColor: accessibleColor(Color(network.colorValue)),
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(icon: Icon(Icons.dns), text: 'Switches'),
              Tab(icon: Icon(Icons.lan), text: 'VLAN'),
              Tab(icon: Icon(Icons.devices), text: 'Equipos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            SwitchesTab(network: network),
            VlansTab(network: network),
            _BuildingDevicesTab(network: network),
          ],
        ),
      ),
    );
  }
}

/// Equipos registrados en las VLAN de un edificio.
class _BuildingDevicesTab extends StatefulWidget {
  final NetworkGroup network;
  const _BuildingDevicesTab({required this.network});

  @override
  State<_BuildingDevicesTab> createState() => _BuildingDevicesTabState();
}

class _BuildingDevicesTabState extends State<_BuildingDevicesTab> {
  final db = DatabaseHelper();
  List<Device> devices = [];
  List<Subnet> subnets = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final subs = await db.getSubnetsByNetwork(widget.network.id);
      final all = await db.getDevices();
      final ids = subs.map((s) => s.id).toSet();
      if (mounted) {
        setState(() {
          subnets = subs;
          devices = all.where((d) => ids.contains(d.subnetId)).toList()..sort((a, b) => a.name.compareTo(b.name));
        });
      }
    } catch (e) {
      if (mounted) showMsg(context, 'No se pudieron cargar los equipos: $e', error: true);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = AppSession.isAdmin;
    return Stack(
      children: [
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (devices.isEmpty)
          const EmptyState(
            icon: Icons.devices_other,
            title: 'Sin equipos en este edificio',
            hint: 'Los equipos se registran dentro de una VLAN.',
          )
        else
          ResponsiveList(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: devices.length,
            itemBuilder: (context, i) {
              final d = devices[i];
              final vlan = subnets.firstWhere((s) => s.id == d.subnetId, orElse: () => subnets.first);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                    child: Icon(Icons.computer, color: AppColors.primary),
                  ),
                  title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${d.ip} · ${vlan.label}\nMAC ${d.mac}', style: TextStyle(color: AppColors.inkMuted)),
                  isThreeLine: true,
                  onTap: admin
                      ? () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DeviceFormScreen(device: d, subnets: subnets)),
                          );
                          _load();
                        }
                      : null,
                ),
              );
            },
          ),
        if (admin && subnets.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'add_device_${widget.network.id}',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeviceFormScreen(subnets: subnets)),
                );
                _load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar equipo'),
            ),
          ),
      ],
    );
  }
}
