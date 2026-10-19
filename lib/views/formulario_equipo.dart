import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/controllers/validators.dart';
import 'package:bitacora_red/widgets/responsive.dart';
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

      // No se puede usar la dirección de red, el ruteador ni el broadcast.
      if (ip == selectedSubnet.gateway || ip == selectedSubnet.broadcast || ip == selectedSubnet.baseIp) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('La IP $ip está reservada en ${selectedSubnet.name} (red, ruteador o broadcast).'),
          backgroundColor: AppColors.error,
        ));
        return;
      }
      if (selectedSubnet.isIpExcluded(ip)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('La IP $ip está en el rango excluido de ${selectedSubnet.name} (${selectedSubnet.excluded})'),
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

      final isIpTaken = existingDevices.any((d) => d.ip == ip && (widget.device == null || d.id != widget.device!.id));
      if (isIpTaken) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: la IP $ip ya está asignada a otro equipo.'),
            backgroundColor: AppColors.error,
          ));
        }
        return;
      }

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
      body: Centered(child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Segmento / VLAN'),
              initialValue: selectedSubnetId,
              icon: const Icon(Icons.arrow_drop_down),
              // El texto es largo: el campo debe ocupar todo el ancho y recortar lo que no quepa.
              isExpanded: true,
              itemHeight: 64,
              // Ya elegido, solo se muestra el nombre (una línea).
              selectedItemBuilder: (context) => widget.subnets
                  .map((s) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              // En la lista: nombre arriba y rango abajo, cada uno en su línea.
              items: widget.subnets.map((s) {
                return DropdownMenuItem(
                  value: s.id,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${s.firstUsable} - ${s.lastUsable}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(size: 12, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedSubnetId = val),
              validator: (val) => val == null ? 'Requerido' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: ip, decoration: const InputDecoration(labelText: 'IP Asignada (Ej. 192.168.0.5)'),
              keyboardType: TextInputType.number,
              validator: (val) => Validators.ip(val),
              onSaved: (val) => ip = val!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: name, decoration: const InputDecoration(labelText: 'Nombre'),
              validator: (val) => Validators.text(val, campo: 'El nombre', min: 2, max: 60),
              onSaved: (val) => name = val!.trim(),
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
              validator: (val) => Validators.optional(val, campo: 'La marca', max: 60),
              onSaved: (val) => manufacturer = val!.trim(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: location, decoration: const InputDecoration(labelText: 'Ubicación'),
              validator: (val) => Validators.optional(val, campo: 'La ubicación', max: 80),
              onSaved: (val) => location = val!.trim(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: saveDevice, child: const Text('Guardar Configuración'))
          ],
        ),
      )),
    );
  }
}