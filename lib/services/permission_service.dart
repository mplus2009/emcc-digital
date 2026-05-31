// lib/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';
import 'debug_logger.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
    DebugLogger.log("🔐 Solicitando permisos...");
    
    final permissions = [
      Permission.camera,
      Permission.storage,
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.nearbyWifiDevices,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = true;
    for (final entry in statuses.entries) {
      if (!entry.value.isGranted) {
        DebugLogger.log("⚠️ Permiso denegado: ${entry.key}");
        allGranted = false;
      } else {
        DebugLogger.log("✅ Permiso concedido: ${entry.key}");
      }
    }
    
    if (allGranted) {
      DebugLogger.log("🎉 Todos los permisos concedidos");
    } else {
      DebugLogger.log("⚠️ Algunos permisos fueron denegados");
    }
    
    return allGranted;
  }

  static Future<bool> requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.location,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }
}
