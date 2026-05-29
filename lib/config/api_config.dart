// lib/config/api_config.dart
class ApiConfig {
  // Configuración local - No se usa servidor central
  static const String appName = 'EMCC Digital';
  static const int versionCode = 1;
  
  // Colores de la app
  static const int colorPrimary = 0xFF1E3C72;
  static const int colorPrimaryDark = 0xFF152C54;
  static const int colorAccent = 0xFF2A5298;
  static const int colorMerito = 0xFF10B981;
  static const int colorDemerito = 0xFFEF4444;
  static const int colorBackground = 0xFFF5F7FA;
  static const int colorCard = 0xFFFFFFFF;
  
  // Configuración de red P2P
  static const int wifiDirectPort = 8080;
  static const String wifiDirectPingEndpoint = '/ping';
  static const String wifiDirectSyncEndpoint = '/sync';
  static const String pingResponse = 'EMCC_OK';
  
  // Tiempos de espera
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration syncInterval = Duration(minutes: 5);
}
