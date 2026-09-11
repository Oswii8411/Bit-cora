import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/pantalla_principal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://axsepafjqmzwbegfeypv.supabase.co',
    anonKey: 'sb_publishable_kcBRDshFIwoO6-afhUXNyQ_EQ-1ldtz',
  );

  runApp(const BitacoraRedApp());
}

class BitacoraRedApp extends StatelessWidget {
  const BitacoraRedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NetControl ITSU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF8F9FA), elevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
          titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      home: const MainTabScreen(),
    );
  }
}