import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/controllers/mac_address_formatter.dart';
import 'package:bitacora_red/models/device.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


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

      final existingDevices = await dbHelper.getDevices();
      bool isMacTaken = existingDevices.any((d) =>
      d.mac.toLowerCase() == mac.toLowerCase() &&
          (widget.device == null || d.id != widget.device!.id)
      );

      if (isMacTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: La MAC $mac ya está registrada.'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ));
        }
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
              initialValue: selectedSubnetId,
              icon: const Icon(Icons.arrow_drop_down),
              items: widget.subnets.map((s) {
                return DropdownMenuItem(value: s.id, child: Text('${s.name} (${s.firstUsable} - ${s.lastUsable})'));
              }).toList(),
              onChanged: (val) => setState(() => selectedSubnetId = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: ip, decoration: const InputDecoration(labelText: 'IP Asignada (Ej. 192.168.0.5)'),
              validator: (val) => val!.isEmpty ? 'Requerido' : null, onSaved: (val) => ip = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: name, decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (val) => val!.isEmpty ? 'Requerido' : null,
              onSaved: (val) => name = val!,
            ),
            const SizedBox(height: 16),

            // SECCIÓN ACTUALIZADA DE LA MAC (FORMATEADOR APLICADO)
            TextFormField(
              initialValue: mac,
              decoration: const InputDecoration(labelText: 'MAC Address'),
              inputFormatters: [
                MacAddressFormatter(),
                LengthLimitingTextInputFormatter(17), // Limita a 12 caracteres + 5 ':'
              ],
              validator: (val) {
                if (val == null || val.isEmpty) return 'Requerido';
                if (!RegExp(r'^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$').hasMatch(val)) {
                  return 'Formato de MAC inválido';
                }
                return null;
              },
              onSaved: (val) => mac = val!,
            ),

            const SizedBox(height: 16),
            TextFormField(
              initialValue: manufacturer, decoration: const InputDecoration(labelText: 'Marca / Fabricante'),
              onSaved: (val) => manufacturer = val!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: location, decoration: const InputDecoration(labelText: 'Ubicación'),
              onSaved: (val) => location = val!,
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: saveDevice, child: const Text('Guardar Configuración'))
          ],
        ),
      ),
    );
  }
}