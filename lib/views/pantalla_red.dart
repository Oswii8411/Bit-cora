import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/views/pantalla_switches.dart';
import 'package:bitacora_red/views/pantalla_vlan.dart';
import 'package:flutter/material.dart';

/// Red: switches y VLAN de todos los edificios.
/// El técnico solo ve los switches (puede cambiar su estado).
class RedScreen extends StatelessWidget {
  final int initialTab;
  const RedScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    if (!AppSession.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Red')),
        body: const SwitchesTab(),
      );
    }
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Red'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Switches'),
              Tab(text: 'VLAN'),
            ],
          ),
        ),
        body: const TabBarView(children: [SwitchesTab(), VlansTab()]),
      ),
    );
  }
}
