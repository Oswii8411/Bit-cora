import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'views/pantalla_principal.dart';
import 'views/login_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const BitacoraRedApp()); //
}

class BitacoraRedApp extends StatelessWidget {
  const BitacoraRedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bitácora de Red',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      // Validación de sesión para mostrar Login o Pantalla Principal
      home: Supabase.instance.client.auth.currentUser != null
          ? const MainTabScreen()
          : const LoginScreen(),
    );
  }
}