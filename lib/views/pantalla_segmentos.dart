import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/network_group.dart';
import 'package:bitacora_red/models/subnet.dart';
import 'package:flutter/material.dart';


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
  void initState() {
    super.initState();
    _loadData();
  }

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(widget.network.colorValue)
                    .withValues(alpha: 0.2),
                child: Icon(
                  Icons.router,
                  color: Color(widget.network.colorValue),
                ),
              ),
              title: Text(
                subnet.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Rango: ${subnet.firstUsable} - ${subnet.lastUsable}',
              ),
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
                      await dbHelper.deleteSubnet(subnet.id, subnet.name);
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
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              subnet.name = ctrl.text;
              await dbHelper.updateSubnet(subnet);
              if (context.mounted) Navigator.pop(context);
              _loadData();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
