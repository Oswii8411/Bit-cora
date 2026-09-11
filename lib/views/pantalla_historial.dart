import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/models/history_log.dart';
import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dbHelper = DatabaseHelper();
  List<HistoryLog> logs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final data = await dbHelper.getHistoryLogs();
    setState(() {
      logs = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Auditoría'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : logs.isEmpty
          ? const Center(child: Text('El historial está vacío.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                Color iconColor;
                IconData iconShape;
                Color bgColor;

                switch (log.actionType) {
                  case 'CREAR':
                    iconColor = Colors.green.shade700;
                    bgColor = Colors.green.shade50;
                    iconShape = Icons.add_circle;
                    break;
                  case 'EDITAR':
                    iconColor = Colors.amber.shade700;
                    bgColor = Colors.amber.shade50;
                    iconShape = Icons.edit_note;
                    break;
                  case 'ELIMINAR':
                    iconColor = Colors.red.shade700;
                    bgColor = Colors.red.shade50;
                    iconShape = Icons.delete_forever;
                    break;
                  default:
                    iconColor = Colors.blueGrey;
                    bgColor = Colors.blueGrey.shade50;
                    iconShape = Icons.info;
                }

                String formattedDate = '';
                if (log.createdAt != null) {
                  formattedDate =
                      '${log.createdAt!.day}/${log.createdAt!.month}/${log.createdAt!.year} - ${log.createdAt!.hour}:${log.createdAt!.minute.toString().padLeft(2, '0')}';
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: iconColor.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: bgColor,
                      child: Icon(iconShape, color: iconColor),
                    ),
                    title: Text(
                      log.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '$formattedDate  •  Módulo: ${log.entityType}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
