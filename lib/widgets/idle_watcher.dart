import 'dart:async';

import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/auth_controller.dart';
import 'package:bitacora_red/views/login_screen.dart';
import 'package:flutter/material.dart';

/// Cierra la sesión tras N minutos sin tocar la pantalla (Preferencias >
/// "Tiempo de protección de sesión").
class IdleWatcher extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  const IdleWatcher({super.key, required this.child, required this.navigatorKey});

  @override
  State<IdleWatcher> createState() => _IdleWatcherState();
}

class _IdleWatcherState extends State<IdleWatcher> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    AppSession.sessionMinutes.addListener(_reset);
    _reset();
  }

  @override
  void dispose() {
    AppSession.sessionMinutes.removeListener(_reset);
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    // Sin perfil cargado no hay sesión que proteger.
    _timer = Timer(Duration(minutes: AppSession.sessionMinutes.value), _expire);
  }

  Future<void> _expire() async {
    if (AppSession.profile == null) {
      _reset();
      return;
    }
    await AuthController().signOut();
    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(notice: 'Tu sesión se cerró por inactividad.'),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _reset(),
      onPointerMove: (_) => _reset(),
      onPointerSignal: (_) => _reset(),
      child: widget.child,
    );
  }
}
