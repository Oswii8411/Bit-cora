class Incidencia {
  final String? id; // Necesitamos el ID para poder actualizarla
  final DateTime? createdAt;
  final String dispositivoNombre;
  final String descripcion;
  final String accionRealizada;
  final String estado;
  final String prioridad;
  final String responsable;
  final String historialCambios;

  /// Puerto al que está vinculada (si se reportó desde un puerto).
  final String? puertoId;

  /// Resumen de qué se hizo y cómo se resolvió.
  final String solucion;

  /// Quién la resolvió y cuándo (solo cuando está resuelta).
  final String? resueltoPor;
  final DateTime? resueltoEn;

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
    this.puertoId,
    this.solucion = '',
    this.resueltoPor,
    this.resueltoEn,
  });

  bool get resuelta => estado == 'Resuelto';

  factory Incidencia.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
    return Incidencia(
      id: json['id']?.toString(),
      createdAt: parse(json['created_at']),
      dispositivoNombre: json['dispositivo_nombre'] ?? 'Desconocido',
      descripcion: json['descripcion'] ?? '',
      accionRealizada: json['accion_realizada'] ?? '',
      estado: json['estado'] ?? 'Pendiente',
      prioridad: json['prioridad'] ?? 'Media',
      responsable: json['responsable'] ?? 'Desconocido',
      historialCambios: json['historial_cambios'] ?? '',
      puertoId: json['puerto_id'] as String?,
      solucion: json['solucion'] as String? ?? '',
      resueltoPor: json['resuelto_por'] as String?,
      resueltoEn: parse(json['resuelto_en']),
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
      // Los campos de resolución solo se envían cuando existen: así la app sigue
      // funcionando aunque la base de datos aún no tenga esas columnas.
      if (puertoId != null) 'puerto_id': puertoId,
      if (solucion.isNotEmpty) 'solucion': solucion,
      if (resueltoPor != null) 'resuelto_por': resueltoPor,
      if (resueltoEn != null) 'resuelto_en': resueltoEn!.toUtc().toIso8601String(),
    };
  }
}
