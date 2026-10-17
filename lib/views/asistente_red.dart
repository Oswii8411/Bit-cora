import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/validators.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:bitacora_red/widgets/motion.dart';
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
    AppColors.palette4, AppColors.palette3, const Color(0xFF0F766E),
    const Color(0xFFB45309), const Color(0xFFB91C1C), const Color(0xFF475569)
  ];
  late Color selectedColor;

  @override
  void initState() {
    super.initState();
    selectedColor = availableColors[0];
  }

  void _error(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _generateSubnets() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final name = networkName.trim();
    final ip = baseIp.trim();
    final segmentSize = totalDevices ~/ segments;
    final net = NetworkUtils.ipToLong(ip);

    if (segmentSize < 4) {
      _error('Con $segments segmentos cada uno tendría menos de 4 direcciones. Usa menos segmentos o un tamaño total mayor.');
      return;
    }
    // La dirección de red debe ser la primera del bloque total.
    if (net % totalDevices != 0) {
      _error('La IP base debe ser la primera dirección de un bloque de $totalDevices. Prueba con ${NetworkUtils.longToIp(net - net % totalDevices)}.');
      return;
    }

    try {
      final existingNetworks = await dbHelper.getNetworks();
      if (Validators.duplicated(name, existingNetworks.map((n) => n.name))) {
        _error('Ya existe un edificio llamado "$name".');
        return;
      }
      if (existingNetworks.any((n) => n.baseIp == ip)) {
        _error('La red $ip ya existe.');
        return;
      }
      // El rango nuevo no debe traslaparse con ninguna VLAN existente.
      final subnets = await dbHelper.getSubnets();
      for (final sub in subnets) {
        final start = sub.networkLong;
        final end = start + sub.size - 1;
        if (net <= end && net + totalDevices - 1 >= start) {
          _error('Ese rango se traslapa con la VLAN "${sub.name}" (${sub.baseIp}).');
          return;
        }
      }

      final netId = DateTime.now().millisecondsSinceEpoch.toString();
      await dbHelper.insertNetwork(
        NetworkGroup(id: netId, name: name, baseIp: ip, colorValue: selectedColor.toARGB32()),
      );

      var current = net;
      for (var i = 0; i < segments; i++) {
        final newSubnet = Subnet(
          id: '${DateTime.now().millisecondsSinceEpoch}$i',
          networkId: netId,
          name: 'Segmento ${i + 1}',
          baseIp: NetworkUtils.longToIp(current),
          size: segmentSize,
          vlanNumber: (i + 1) * 10,
        )..fillDerivedFields();
        await dbHelper.insertSubnet(newSubnet);
        current += segmentSize;
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _error('No se pudo crear el edificio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo edificio')),
      body: Centered(child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nombre del edificio (Ej. Edificio A)'),
              validator: (val) => Validators.text(val, campo: 'El nombre', min: 2, max: 60),
              onSaved: (val) => networkName = val ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'IP Base (Ej. 192.168.0.0)'),
              keyboardType: TextInputType.number,
              validator: (val) => Validators.ip(val, campo: 'La IP base'),
              onSaved: (val) => baseIp = val ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Tamaño total'),
                    keyboardType: TextInputType.number, initialValue: '64',
                    validator: (val) =>
                        Validators.intRange(val, 8, 65536, 'El tamaño') ??
                        (Validators.isPowerOfTwo(int.parse(val!.trim())) ? null : 'Usa una potencia de 2 (8, 16, 32, 64...)'),
                    onSaved: (val) => totalDevices = int.tryParse(val?.trim() ?? '') ?? 64,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Segmentos'),
                    keyboardType: TextInputType.number, initialValue: '4',
                    validator: (val) =>
                        Validators.intRange(val, 1, 64, 'Los segmentos') ??
                        (Validators.isPowerOfTwo(int.parse(val!.trim())) ? null : 'Usa una potencia de 2 (1, 2, 4, 8...)'),
                    onSaved: (val) => segments = int.tryParse(val?.trim() ?? '') ?? 4,
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
                  child: AnimatedScale(
                    scale: selectedColor == color ? 1.12 : 1.0,
                    duration: const Duration(milliseconds: 160),
                    curve: kEaseOut,
                    child: CircleAvatar(
                      backgroundColor: color,
                      child: AnimatedOpacity(
                        opacity: selectedColor == color ? 1 : 0,
                        duration: const Duration(milliseconds: 160),
                        child: const Icon(Icons.check, color: Colors.white),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _generateSubnets,
              style: ElevatedButton.styleFrom(backgroundColor: selectedColor),
              child: const Text('Crear edificio', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      )),
    );
  }
}