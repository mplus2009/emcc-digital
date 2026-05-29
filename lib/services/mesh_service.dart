// lib/services/mesh_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class MeshService {
  static bool _isRunning = false;
  static List<String> _peers = [];
  static final List<void Function()> _listeners = [];
  
  static bool get isRunning => _isRunning;
  static int get peersCount => _peers.length;
  static List<String> get peersList => List.unmodifiable(_peers);

  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('🟢 Mesh Service iniciado');
    _notifyListeners();
  }

  static void stop() {
    _isRunning = false;
    _peers.clear();
    _notifyListeners();
    debugPrint('🔴 Mesh Service detenido');
  }

  static Future<void> broadcast(Map<String, dynamic> actividad) async {
    debugPrint('📡 Transmitiendo actividad: ${actividad['falta_causa']}');
  }
}
