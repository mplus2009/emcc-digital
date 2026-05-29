// lib/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
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
    for (final status in statuses.values) {
      if (!status.isGranted) allGranted = false;
    }
    return allGranted;
  }

  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }
}
