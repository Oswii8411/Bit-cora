import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/database_helper.dart';
import '../models/history_log.dart';
import '../models/incidencia.dart';
import 'formulario_incidencia.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dbHelper = DatabaseHelper();
  List<HistoryLog> logs = [];
  List<Incidencia> incidencias = [];
  bool isLoading = true;

  // Colores de la paleta
  final Color colorFondo = const Color(0xFFFFF0FF);
  final Color colorPrimarioOscuro = const Color(0xFF4B1C71);
  final Color colorPrimario = const Color(0xFF7F4CA5);
  final Color colorAcento = const Color(0xFFB57EDC);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => isLoading = true);

    // Cargamos ambos historiales al mismo tiempo
    final auditData = await dbHelper.getHistoryLogs();
    final incidenciasData = await dbHelper.getIncidencias();

    setState(() {
      logs = auditData;
      incidencias = incidenciasData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // DefaultTabController nos permite manejar pestañas fácilmente
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorFondo,
        appBar: AppBar(
          title: const Text('Historial y Bitácora', style: TextStyle(color: Colors.white)),
          backgroundColor: colorPrimarioOscuro,
          elevation: 0,
          actions: [
            IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _cargarDatos
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.list_alt), text: 'Incidencias'),
              Tab(icon: Icon(Icons.security), text: 'Auditoría'),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: colorPrimarioOscuro))
            : TabBarView(
          children: [
            _buildPestanaIncidencias(),
            _buildPestanaAuditoria(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: colorPrimario,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Reportar', style: TextStyle(color: Colors.white)),
          onPressed: () async {
            // Abre el formulario en modo "Creación" (incidenciaActual es nulo por defecto)
            final recargar = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FormularioIncidencia()),
            );
            if (recargar == true) {
              _cargarDatos();
            }
          },
        ),
      ),
    );
  }

  // --- WIDGET PARA LA PESTAÑA DE INCIDENCIAS ---
  Widget _buildPestanaIncidencias() {
    if (incidencias.isEmpty) {
      return const Center(child: Text('No hay incidencias registradas.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80), // Espacio para que no lo tape el FAB
      itemCount: incidencias.length,
      itemBuilder: (context, index) {
        final item = incidencias[index];
        final fecha = item.createdAt != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt!)
            : 'Sin fecha';

        // Color dinámico según el estado y prioridad
        Color colorEstado = Colors.orange;
        if (item.estado == 'Resuelto') colorEstado = Colors.green;
        if (item.estado == 'Alta' || item.prioridad == 'Alta') colorEstado = Colors.red;

        // InkWell hace que toda la tarjeta sea cliqueable
        return InkWell(
          onTap: () async {
            // Abre el formulario en modo "Edición" pasando el objeto actual
            final recargar = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FormularioIncidencia(incidenciaActual: item),
              ),
            );
            if (recargar == true) {
              _cargarDatos(); // Refresca la lista si se guardó un cambio
            }
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.dispositivoNombre,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorPrimarioOscuro),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Chip(
                        label: Text(item.estado, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        backgroundColor: colorEstado,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Falla: ${item.descripcion}', style: const TextStyle(fontSize: 15)),
                  Text('Acción: ${item.accionRealizada}', style: const TextStyle(fontSize: 15, color: Colors.grey)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: colorAcento),
                          const SizedBox(width: 4),
                          Text(item.responsable, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(fecha, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET PARA LA PESTAÑA DE AUDITORÍA ---
  Widget _buildPestanaAuditoria() {
    if (logs.isEmpty) {
      return const Center(child: Text('El historial de auditoría está vacío.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
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
            iconColor = colorPrimario;
            bgColor = colorFondo;
            iconShape = Icons.info;
        }

        String formattedDate = '';
        if (log.createdAt != null) {
          formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(log.createdAt!);
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '$formattedDate  •  Módulo: ${log.entityType}',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ),
          ),
        );
      },
    );
  }
}