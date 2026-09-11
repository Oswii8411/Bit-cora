import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/controllers/network_utils.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:flutter/material.dart';


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

      final existingNetworks = await dbHelper.getNetworks();
      if (existingNetworks.any((net) => net.baseIp == baseIp)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: La red $baseIp ya existe.'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      String netId = DateTime.now().millisecondsSinceEpoch.toString();
      NetworkGroup newNetwork = NetworkGroup(
          id: netId, name: networkName, baseIp: baseIp, colorValue: selectedColor.toARGB32()
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
              decoration: const InputDecoration(labelText: 'Nombre de la Red (Ej. Edificio A)'),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
              onSaved: (val) => networkName = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'IP Base (Ej. 192.168.0.0)'),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
              onSaved: (val) => baseIp = val!,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Tamaño total'),
                    keyboardType: TextInputType.number, initialValue: '64',
                    onSaved: (val) => totalDevices = int.parse(val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Segmentos'),
                    keyboardType: TextInputType.number, initialValue: '4',
                    onSaved: (val) => segments = int.parse(val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
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
              style: ElevatedButton.styleFrom(backgroundColor: selectedColor),
              child: const Text('Crear Red', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}