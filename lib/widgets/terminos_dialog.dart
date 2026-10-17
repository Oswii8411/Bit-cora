import 'package:bitacora_red/app_theme.dart';
import 'package:flutter/material.dart';

/// Términos y condiciones de uso de la Bitácora de Red.
Future<void> showTerminosDialog(BuildContext context) {
  const secciones = <(String, String)>[
    ('1. Uso autorizado',
        'La Bitácora de Red es una herramienta para administrar la infraestructura de red del Instituto. Solo el personal autorizado puede usarla, y únicamente para tareas relacionadas con su función.'),
    ('2. Cuentas y aprobación',
        'Toda cuenta nueva queda pendiente hasta que un administrador la apruebe. El administrador puede aceptar, rechazar o desactivar cuentas, y cambiar el rol asignado.'),
    ('3. Credenciales',
        'Eres responsable de mantener en secreto tu contraseña y de las acciones realizadas con tu cuenta. Si sospechas un uso indebido, cámbiala de inmediato.'),
    ('4. Registro de actividad',
        'El sistema registra en la bitácora los inicios y cierres de sesión y cada cambio realizado (quién, qué, cuándo). Estos registros pueden ser consultados por el administrador y no se pueden modificar desde la aplicación.'),
    ('5. Información de la red',
        'Los datos de edificios, switches, puertos, VLAN y equipos son confidenciales. No deben compartirse fuera de la institución.'),
    ('6. Datos personales',
        'Se almacenan tu nombre, correo, departamento y cargo con el único fin de identificar a los usuarios del sistema.'),
    ('7. Cambios a estos términos',
        'Los términos pueden actualizarse. El uso continuo de la aplicación implica la aceptación de la versión vigente.'),
  ];

  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Términos y condiciones'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (titulo, texto) in secciones) ...[
                Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 4),
                Text(texto, style: TextStyle(color: AppColors.inkMuted, height: 1.4)),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    ),
  );
}
