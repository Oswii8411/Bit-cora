import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/views/asistente_red.dart';
import 'package:bitacora_red/views/pantalla_equipos.dart';
import 'package:bitacora_red/views/pantalla_historial.dart';
import 'package:bitacora_red/views/pantalla_segmentos.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class NetworksScreen extends StatefulWidget {
  const NetworksScreen({super.key});
  @override
  State<NetworksScreen> createState() => _NetworksScreenState();
}

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
    const HistoryScreen()
  ];

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
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}

class _NetworksScreenState extends State<NetworksScreen> {
  final dbHelper = DatabaseHelper();
  List<NetworkGroup> networks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

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
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SegmentsScreen(network: net),
                      ),
                    );
                    _loadData();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    height: 140,
                    decoration: BoxDecoration(
                      color: Color(net.colorValue),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                net.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                              ),
                              onSelected: (value) async {
                                if (value == 'delete') {
                                  await dbHelper.deleteNetwork(
                                    net.id,
                                    net.name,
                                  );
                                  _loadData();
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Eliminar red',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          'IP Inicial: ${net.baseIp}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NetworkWizardScreen(),
            ),
          );
          _loadData();
        },
        backgroundColor: const Color(0xFF1D4ED8),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Agregar red', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
