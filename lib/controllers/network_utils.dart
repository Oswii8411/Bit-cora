class NetworkUtils {
  static int ipToLong(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return 0;
    return (int.parse(parts[0]) << 24) + (int.parse(parts[1]) << 16) + (int.parse(parts[2]) << 8) + int.parse(parts[3]);
  }
  static String longToIp(int longVal) {
    return '${(longVal >> 24) & 255}.${(longVal >> 16) & 255}.${(longVal >> 8) & 255}.${longVal & 255}';
  }

  static final RegExp _ipRegex =
      RegExp(r'^((25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(25[0-5]|2[0-4]\d|1?\d?\d)$');

  static bool isValidIp(String ip) => _ipRegex.hasMatch(ip.trim());

  /// Máscara en formato punteado para un bloque de [size] direcciones
  /// (potencia de 2). Si no lo es, se redondea hacia arriba.
  static String maskFromSize(int size) {
    if (size < 4) size = 4;
    int bits = 0;
    while ((1 << bits) < size && bits < 32) {
      bits++;
    }
    return prefixToMask(32 - bits);
  }

  static String prefixToMask(int prefix) {
    if (prefix < 0 || prefix > 32) return '';
    final mask = prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
    return longToIp(mask);
  }

  /// Acepta "24", "/24" o "255.255.255.0" y devuelve la máscara punteada
  /// o null si no es válida.
  static String? parseMask(String input) {
    final t = input.trim().replaceAll('/', '');
    if (t.isEmpty) return null;
    final prefix = int.tryParse(t);
    if (prefix != null) {
      if (prefix < 8 || prefix > 30) return null;
      return prefixToMask(prefix);
    }
    if (!isValidIp(t)) return null;
    final m = ipToLong(t);
    // Una máscara válida son unos seguidos de ceros.
    final inv = (~m) & 0xFFFFFFFF;
    if ((inv & (inv + 1)) != 0) return null;
    return t;
  }

  /// Tamaño del bloque (con red y broadcast) que define la máscara punteada.
  static int sizeFromMask(String mask) => ((~ipToLong(mask)) & 0xFFFFFFFF) + 1;
}
