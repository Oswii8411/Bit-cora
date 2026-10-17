import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Colores de un tema (claro u oscuro).
class _Tokens {
  final Color primary, onPrimary, accent, onAccent, ink, inkMuted, background, surface, border, error;
  const _Tokens({
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.ink,
    required this.inkMuted,
    required this.background,
    required this.surface,
    required this.border,
    required this.error,
  });
}

/// Tokens visuales de la app. Solo presentación, sin lógica de negocio.
///
/// Los colores que cambian entre tema claro y oscuro son propiedades (no
/// constantes): se leen siempre dentro de `build`. `isDark` lo fija `main.dart`
/// según la preferencia del usuario.
///
/// Reglas de uso: el azul marino de la paleta es la base (navegación, títulos,
/// selección); el ámbar es el ACENTO y solo se usa para la acción principal
/// (crear) y para lo que requiere atención; el resto del color significa estado.
class AppColors {
  // Paleta de marca (de más clara a más oscura).
  static const palette1 = Color(0xFFDCE8FF);
  static const palette2 = Color(0xFF93C5FD);
  static const palette3 = Color(0xFF2563EB);
  static const palette4 = Color(0xFF1E3A8A);
  static const palette5 = Color(0xFF0F1F4D);

  static const _light = _Tokens(
    primary: palette4, // botones y énfasis (10:1 con blanco)
    onPrimary: Colors.white,
    accent: Color(0xFFF2A516),
    onAccent: Color(0xFF2B1B00),
    ink: palette5, // texto principal
    inkMuted: Color(0xFF4B5A82), // texto secundario (~6:1 sobre fondo)
    background: Color(0xFFF5F7FC),
    surface: Colors.white,
    border: Color(0xFFDCE3F2),
    error: Color(0xFFB91C1C),
  );

  static const _dark = _Tokens(
    primary: palette2, // sobre fondo oscuro se lee mejor el azul claro
    onPrimary: palette5,
    accent: Color(0xFFF5B83D),
    onAccent: Color(0xFF2B1B00),
    ink: Color(0xFFE6ECFA),
    inkMuted: Color(0xFF9AA8CC),
    background: Color(0xFF0A1226),
    surface: Color(0xFF111C3A),
    border: Color(0xFF22315C),
    error: Color(0xFFF87171),
  );

  static bool isDark = false;
  static _Tokens get _t => isDark ? _dark : _light;

  static Color get primary => _t.primary;
  static Color get onPrimary => _t.onPrimary;
  static Color get accent => _t.accent;
  static Color get onAccent => _t.onAccent;
  static Color get ink => _t.ink;
  static Color get inkMuted => _t.inkMuted;
  static Color get background => _t.background;
  static Color get surface => _t.surface;
  static Color get border => _t.border;
  static Color get error => _t.error;

  /// Colores de las gráficas (de más a menos intenso).
  static Color get chart1 => isDark ? const Color(0xFF93C5FD) : palette4;
  static Color get chart2 => isDark ? const Color(0xFF3B82F6) : palette3;
  static Color get chart3 => isDark ? const Color(0xFF2B4A8F) : palette2;

  /// Texto de acento legible sobre el fondo de la app (el ámbar puro no se lee
  /// sobre blanco).
  static Color get accentText => isDark ? const Color(0xFFF5B83D) : const Color(0xFF8A5600);

  /// Aclara un color "de estado" (verde, naranja, azul...) para que se lea
  /// sobre el fondo oscuro. En tema claro lo deja igual.
  static Color tint(Color c) => isDark ? Color.lerp(c, Colors.white, 0.5)! : c;

  /// Degradado de marca (solo se usa en la pantalla de acceso).
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [palette5, palette4],
  );
}

/// Estilos de texto reutilizables.
class AppText {
  /// Para IPs, MAC, máscaras y rangos: ancho fijo para compararlos de un vistazo.
  static TextStyle mono({double size = 13, Color? color, FontWeight weight = FontWeight.w500}) => TextStyle(
        fontFamily: 'monospace',
        fontFamilyFallback: const ['Consolas', 'Menlo', 'Courier New', 'Courier'],
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        letterSpacing: -0.2,
      );

  /// Etiqueta pequeña en mayúsculas para encabezar secciones.
  static TextStyle overline({Color? color}) => TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: color ?? AppColors.inkMuted,
      );
}

class AppTheme {
  static ThemeData get light => _build(AppColors._light, Brightness.light);
  static ThemeData get dark => _build(AppColors._dark, Brightness.dark);

  static const double radius = 10;

  static ThemeData _build(_Tokens t, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.palette4,
      brightness: brightness,
      primary: t.primary,
      onPrimary: t.onPrimary,
      surface: t.surface,
      onSurface: t.ink,
      error: t.error,
    );

    final textTheme = TextTheme(
      titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: t.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w600, color: t.ink),
      bodyLarge: TextStyle(color: t.ink),
      bodyMedium: TextStyle(color: t.ink),
      bodySmall: TextStyle(color: t.inkMuted),
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: t.ink),
        titleTextStyle: TextStyle(
          color: t.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: inputBorder(t.border),
        enabledBorder: inputBorder(t.border),
        focusedBorder: inputBorder(t.primary, width: 1.6),
        errorBorder: inputBorder(t.error),
        focusedErrorBorder: inputBorder(t.error, width: 1.6),
        labelStyle: TextStyle(color: t.inkMuted),
        hintStyle: TextStyle(color: t.inkMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: t.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.primary,
          side: BorderSide(color: t.border),
          minimumSize: const Size.fromHeight(46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        ),
      ),
      // El ámbar es el acento: solo el botón de crear lo usa.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.accent,
        foregroundColor: t.onAccent,
        elevation: 1,
        highlightElevation: 2,
        extendedTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.ink,
        unselectedLabelColor: t.inkMuted,
        indicatorColor: t.primary,
        dividerColor: t.border,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: t.surface,
        side: BorderSide(color: t.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: TextStyle(color: t.ink, fontSize: 13),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: t.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      dividerColor: t.border,
      dividerTheme: DividerThemeData(color: t.border, space: 1, thickness: 1),
    );
  }
}

double _contrastWithWhite(Color c) => 1.05 / (c.computeLuminance() + 0.05);

/// Oscurece un color de red guardado hasta que el texto blanco encima
/// alcance contraste AA (4.5:1). No modifica el dato guardado, solo cómo se pinta.
Color accessibleColor(Color color) {
  var hsl = HSLColor.fromColor(color);
  while (_contrastWithWhite(hsl.toColor()) < 4.5 && hsl.lightness > 0.1) {
    hsl = hsl.withLightness(hsl.lightness - 0.02);
  }
  return hsl.toColor();
}
