import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Estados de edificios, switches y VLAN.
const List<String> kEstadosInfra = [
  'Activo',
  'En revisión',
  'Mantenimiento',
  'Fuera de servicio',
];

/// Estados de un puerto de switch.
const List<String> kEstadosPuerto = [
  'Disponible',
  'En uso',
  'Con incidencia',
  'Deshabilitado',
];

/// Módulos de la bitácora: valor guardado en BD -> nombre para mostrar.
const Map<String, String> kModulosBitacora = {
  'RED': 'Edificios',
  'SWITCH': 'Switches',
  'PUERTO': 'Puertos',
  'SEGMENTO': 'VLAN',
  'EQUIPO': 'Equipos',
  'INCIDENCIA': 'Incidencias',
  'USUARIO': 'Usuarios',
  'SESION': 'Sesión',
  'REPORTE': 'Reportes',
};

/// Acciones de la bitácora.
const List<String> kAccionesBitacora = [
  'CREAR',
  'EDITAR',
  'ELIMINAR',
  'INICIO',
  'CIERRE',
  'GENERAR',
];

/// Color asociado a cada estado (todos con contraste AA sobre fondo claro).
Color estadoColor(String estado) {
  switch (estado) {
    case 'Activo':
    case 'Disponible':
      return const Color(0xFF15803D);
    case 'En revisión':
      return const Color(0xFFB45309);
    case 'Mantenimiento':
      return const Color(0xFF1D4ED8);
    case 'En uso':
      return AppColors.primary;
    case 'Con incidencia':
      return const Color(0xFFC2410C);
    case 'Fuera de servicio':
    case 'Deshabilitado':
      return AppColors.error;
    default:
      return AppColors.inkMuted;
  }
}
