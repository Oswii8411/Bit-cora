class NetworkUtils {
  static int ipToLong(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return 0;
    return (int.parse(parts[0]) << 24) + (int.parse(parts[1]) << 16) + (int.parse(parts[2]) << 8) + int.parse(parts[3]);
  }
  static String longToIp(int longVal) {
    return '${(longVal >> 24) & 255}.${(longVal >> 16) & 255}.${(longVal >> 8) & 255}.${longVal & 255}';
  }
}