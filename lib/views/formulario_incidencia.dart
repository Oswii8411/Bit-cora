import 'package:bitacora_red/app_theme.dart';
import 'package:bitacora_red/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/incidencia.dart';
import '../controllers/app_session.dart';
import '../controllers/database_helper.dart';

class FormularioIncidencia extends StatefulWidget {
  final Incidencia? incidenciaActual; // Si es nulo, estamos creando. Si tiene datos, estamos editando.

  const FormularioIncidencia({super.key, this.incidenciaActual});

  @override
  State<FormularioIncidencia> createState() => _FormularioIncidenciaState();
}

class _FormularioIncidenciaState extends State<FormularioIncidencia> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  final _accionController = TextEditingController();
  final _nuevoDispositivoController = TextEditingController();

  String? _dispositivoSeleccionado;
  bool _mostrarCampoNuevoEquipo = false;
  String _estadoSeleccionado = 'Pendiente';
  String _prioridadSeleccionada = 'Media';
  bool _isLoading = false;

  List<String> _opcionesEquipos = ['Cargando...'];

  @override
  void initState() {
    super.initState();
    _cargarEquipos();

    // Si estamos en MODO EDICIÓN, llenamos los campos con los datos actuales
    if (widget.incidenciaActual != null) {
      _descripcionController.text = widget.incidenciaActual!.descripcion;
      _accionController.text = widget.incidenciaActual!.accionRealizada;
      _estadoSeleccionado = widget.incidenciaActual!.estado;
      _prioridadSeleccionada = widget.incidenciaActual!.prioridad;
    }
  }

  Future<void> _cargarEquipos() async {
    final dispositivos = await DatabaseHelper().getDevices();
    setState(() {
      _opcionesEquipos = dispositivos.map((d) => d.name).toList();

      // Si estamos editando y el nombre del equipo no está en la lista actual, lo agregamos para que no marque error
      if (widget.incidenciaActual != null && !_opcionesEquipos.contains(widget.incidenciaActual!.dispositivoNombre)) {
        _opcionesEquipos.insert(0, widget.incidenciaActual!.dispositivoNombre);
      }

      _opcionesEquipos.add('Otro (Escribir manualmente)'); // Opción especial

      if (widget.incidenciaActual != null) {
        _dispositivoSeleccionado = widget.incidenciaActual!.dispositivoNombre;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dispositivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selecciona un dispositivo'), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final nombreResponsable = AppSession.profile?.fullName ?? user?.email ?? 'Técnico';

      final nombreDispositivo = _mostrarCampoNuevoEquipo ? _nuevoDispositivoController.text.trim() : _dispositivoSeleccionado!;

      // Armamos el registro de qué técnico hizo qué en este momento
      String fechaActual = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      String accionRegistro = widget.incidenciaActual == null ? "Creó el reporte" : "Actualizó el estado a '$_estadoSeleccionado'";
      String nuevoLog = "[$fechaActual] $nombreResponsable: $accionRegistro.";

      String historialCompleto = widget.incidenciaActual?.historialCambios ?? '';
      historialCompleto = historialCompleto.isEmpty ? nuevoLog : '$historialCompleto\n$nuevoLog';

      final incidenciaData = Incidencia(
        id: widget.incidenciaActual?.id, // Conserva el ID si estamos editando
        dispositivoNombre: nombreDispositivo,
        descripcion: _descripcionController.text.trim(),
        accionRealizada: _accionController.text.trim(),
        estado: _estadoSeleccionado,
        prioridad: _prioridadSeleccionada,
        responsable: nombreResponsable, // Se queda como el último en tocarlo
        historialCambios: historialCompleto,
      );

      if (widget.incidenciaActual == null) {
        await DatabaseHelper().insertIncidencia(incidenciaData);
      } else {
        await DatabaseHelper().updateIncidencia(incidenciaData);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool esEdicion = widget.incidenciaActual != null;

    return Scaffold(
      appBar: AppBar(title: Text(esEdicion ? 'Actualizar incidencia' : 'Nueva incidencia')),
      body: Centered(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selector de Dispositivo
              DropdownButtonFormField<String>(
                initialValue: _dispositivoSeleccionado,
                decoration: _buildDecoration('Dispositivo afectado', Icons.devices),
                items: _opcionesEquipos.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: esEdicion ? null : (val) { // Si edita, no se puede cambiar el dispositivo
                  setState(() {
                    _dispositivoSeleccionado = val;
                    _mostrarCampoNuevoEquipo = val == 'Otro (Escribir manualmente)';
                  });
                },
              ),
              if (_mostrarCampoNuevoEquipo) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nuevoDispositivoController,
                  decoration: _buildDecoration('Nombre del nuevo dispositivo', Icons.add),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _prioridadSeleccionada,
                decoration: _buildDecoration('Prioridad', Icons.flag),
                items: ['Baja', 'Media', 'Alta'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => _prioridadSeleccionada = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _estadoSeleccionado,
                decoration: _buildDecoration('Estado actual', Icons.info_outline),
                items: ['Pendiente', 'En revisión', 'Resuelto'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _estadoSeleccionado = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                maxLines: 2,
                decoration: _buildDecoration('Descripción del problema', Icons.description),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accionController,
                maxLines: 2,
                decoration: _buildDecoration('Acción realizada o seguimiento', Icons.build),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),

              // Historial de intervenciones visual (Solo en modo edición)
              if (esEdicion && widget.incidenciaActual!.historialCambios.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('HISTORIAL DE INTERVENCIONES', style: AppText.overline()),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(widget.incidenciaActual!.historialCambios, style: AppText.mono(size: 12.5, color: AppColors.inkMuted)),
                ),
              ],

              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: _isLoading ? null : _guardar,
                child: _isLoading
                    ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onPrimary))
                    : Text(esEdicion ? 'Actualizar registro' : 'Guardar registro'),
              ),
            ],
          ),
        ),
      )),
    );
  }

  InputDecoration _buildDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 21, color: AppColors.inkMuted),
    );
  }
}
