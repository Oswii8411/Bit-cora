class Incidencia {
  final String? id; // Necesitamos el ID para poder actualizarla
  final DateTime? createdAt;
  final String dispositivoNombre;
  final String descripcion;
  final String accionRealizada;
  final String estado;
  final String prioridad;
  final String responsable;
  final String historialCambios; // Nuevo campo

  Incidencia({
    this.id,
    this.createdAt,
    required this.dispositivoNombre,
    required this.descripcion,
    required this.accionRealizada,
    required this.estado,
    required this.prioridad,
    required this.responsable,
    this.historialCambios = '',
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    return Incidencia(
      id: json['id']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      dispositivoNombre: json['dispositivo_nombre'] ?? 'Desconocido',
      descripcion: json['descripcion'] ?? '',
      accionRealizada: json['accion_realizada'] ?? '',
      estado: json['estado'] ?? 'Pendiente',
      prioridad: json['prioridad'] ?? 'Media',
      responsable: json['responsable'] ?? 'Desconocido',
      historialCambios: json['historial_cambios'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dispositivo_nombre': dispositivoNombre,
      'descripcion': descripcion,
      'accion_realizada': accionRealizada,
      'estado': estado,
      'prioridad': prioridad,
      'responsable': responsable,
      'historial_cambios': historialCambios,
    };
  }
}