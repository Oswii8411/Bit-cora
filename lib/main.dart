import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'controllers/app_session.dart';
import 'controllers/auth_controller.dart';
import 'views/pantalla_principal.dart';
import 'views/login_screen.dart';
import 'views/restablecer_password_screen.dart';
import 'widgets/idle_watcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Marca todo el árbol de widgets para redibujarse una vez. Conserva el estado
/// (textos escritos, scroll, pantallas abiertas); solo vuelve a ejecutar los `build`.
void _rebuildEverything() {
  void rebuild(Element element) {
    element.markNeedsBuild();
    element.visitChildren(rebuild);
  }

  WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const BitacoraRedApp());
}

class BitacoraRedApp extends StatefulWidget {
  const BitacoraRedApp({super.key});

  @override
  State<BitacoraRedApp> createState() => _BitacoraRedAppState();
}

class _BitacoraRedAppState extends State<BitacoraRedApp> {
  late final Future<bool> _restore;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _restore = AuthController().restoreSession().then((p) => p != null);

    // Enlace de "recuperar contraseña" recibido por correo.
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const RestablecerPasswordScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSession.themeMode,
      builder: (context, mode, _) {
        final dark = mode == ThemeMode.dark;
        if (AppColors.isDark != dark) {
          AppColors.isDark = dark;
          // Muchos widgets leen AppColors directamente y Flutter no sabe que deben
          // redibujarse al cambiar el tema (la barra inferior, por ejemplo, se quedaba
          // con los colores viejos hasta tocarla). Se fuerza un redibujado completo.
          WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildEverything());
        }
        return MaterialApp(
          title: 'Bitácora de Red',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          locale: const Locale('es'),
          supportedLocales: const [Locale('es'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          builder: (context, child) => IdleWatcher(navigatorKey: navigatorKey, child: child ?? const SizedBox()),
          home: FutureBuilder<bool>(
            future: _restore,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              return snapshot.data == true ? const MainTabScreen() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
