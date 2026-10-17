import 'package:flutter/material.dart';
import '../models/profile.dart';

/// Estado global de la sesión: perfil del usuario actual y preferencias.
class AppSession {
  static Profile? profile;

  static bool get isAdmin => profile?.isAdmin ?? false;

  /// Tema elegido en Preferencias (se guarda en el perfil).
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  /// Minutos de inactividad antes de cerrar la sesión.
  static final ValueNotifier<int> sessionMinutes = ValueNotifier(30);

  /// Se llama al iniciar sesión o al editar preferencias.
  static void apply(Profile p) {
    profile = p;
    themeMode.value = p.tema == 'oscuro' ? ThemeMode.dark : ThemeMode.light;
    sessionMinutes.value = p.sesionMin;
  }

  static void clear() {
    profile = null;
    themeMode.value = ThemeMode.light;
  }
}
