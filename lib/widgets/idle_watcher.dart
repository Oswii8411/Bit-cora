import 'dart:async';

import 'package:bitacora_red/controllers/app_session.dart';
import 'package:bitacora_red/controllers/auth_controller.dart';
import 'package:bitacora_red/controllers/database_helper.dart';
import 'package:bitacora_red/views/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Protege la sesión y mantiene la app sana al volver de segundo plano:
///  - Cierra la sesión tras N minutos sin tocar la pantalla (Preferencias >
///    "Tiempo de protección de sesión"), incluso si la app estuvo en segundo plano
///    (los temporizadores no corren ahí, por eso se compara contra la última actividad).
///  - Al volver a la app renueva la sesión de Supabase (el token vence a la hora) y
///    manda actualizar las pantallas abiertas, para que no se queden cargando.
class IdleWatcher extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  const IdleWatcher({super.key, required this.child, required this.navigatorKey});

  @override
  State<IdleWatcher> createState() => _IdleWatcherState();
}

class _IdleWatcherState extends State<IdleWatcher> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();

  Duration get _limit => Duration(minutes: AppSession.sessionMinutes.value);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppSession.sessionMinutes.addListener(_reset);
    _reset();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppSession.sessionMinutes.removeListener(_reset);
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _lastActivity = DateTime.now();
    _timer?.cancel();
    _timer = Timer(_limit, _expire);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _onResume();
  }

  Future<void> _onResume() async {
    if (AppSession.profile == null) return;

    // ¿Pasó más tiempo del permitido mientras la app estaba en segundo plano?
    if (DateTime.now().difference(_lastActivity) >= _limit) {
      await _expire();
      return;
    }

    // Renueva la sesión si el token ya venció. Si no se puede, hay que volver a entrar.
    try {
      final auth = Supabase.instance.client.auth;
      final session = auth.currentSession;
      if (session == null) {
        await _logout('Tu sesión expiró. Inicia sesión de nuevo.');
        return;
      }
      if (session.isExpired) {
        await auth.refreshSession().timeout(const Duration(seconds: 12));
      }
    } on AuthException {
      await _logout('Tu sesión expiró. Inicia sesión de nuevo.');
      return;
    } catch (_) {
      // Sin conexión por ahora: las pantallas mostrarán el aviso y se podrá reintentar.
    }

    // Descarta lo guardado (puede estar viejo o tener una petición colgada) y
    // pide a las pantallas abiertas que se actualicen en silencio.
    DatabaseHelper().forceRefresh();
  }

  Future<void> _expire() async {
    if (AppSession.profile == null) {
      _reset();
      return;
    }
    await _logout('Tu sesión se cerró por inactividad.');
  }

  Future<void> _logout(String notice) async {
    try {
      await AuthController().signOut();
    } catch (_) {
      // Aunque falle el registro del cierre, se debe salir.
    }
    widget.navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(notice: notice)),
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
