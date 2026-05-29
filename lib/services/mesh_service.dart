// lib/services/mesh_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';

class MeshService {
  static bool _isRunning = false;
  static bool _isScanning = false;
  static HttpServer? _server;
  static Timer? _discoveryTimer;
  static Timer? _syncTimer;
  static final List<String> _peers = [];
  static final List<void Function()> _listeners = [];
  static const int _port = 8888;
  static String _mode = 'none';
  static StreamSubscription<ConnectivityResult>? _connectivitySub;

  static bool get isRunning => _isRunning;
  static bool get isScanning => _isScanning;
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
    await _startServer();
    _monitorConnectivity();
    _discoveryTimer = Timer.periodic(const Duration(seconds: 15), (_) => _discoverPeers());
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => _syncWithPeers());
    debugPrint('🟢 Mesh Service iniciado');
  }

  static void stop() {
    _isRunning = false;
    _server?.close();
    _discoveryTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySub?.cancel();
    _peers.clear();
    _notifyListeners();
    debugPrint('🔴 Mesh Service detenido');
  }

  static void _monitorConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.wifi) {
        _mode = 'wifi';
        debugPrint('📶 Modo WiFi activado');
        _discoverPeers();
      } else if (result == ConnectivityResult.bluetooth) {
        _mode = 'bluetooth';
        debugPrint('🔵 Modo Bluetooth activado');
      } else {
        _mode = 'none';
        _peers.clear();
        _notifyListeners();
      }
    });
  }

  static Future<void> _startServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      debugPrint('🟢 Servidor Mesh en puerto $_port');
      _server!.listen(_handleRequest);
    } catch (e) {
      debugPrint('🔴 Error iniciando servidor: $e');
    }
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'POST' && request.uri.path == '/sync') {
        final body = await utf8.decodeStream(request);
        final data = jsonDecode(body);
        await _receiveData(data);
        request.response.statusCode = 200;
        request.response.write('{"status":"ok"}');
      } else if (request.uri.path == '/ping') {
        request.response.statusCode = 200;
        request.response.write('{"device":"EMCC","mode":"$_mode"}');
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    } catch (e) {
      debugPrint('Error en request: $e');
      try {
        request.response.statusCode = 500;
        await request.response.close();
      } catch (_) {}
    }
  }

  static Future<void> _discoverPeers() async {
    if (_mode != 'wifi') return;
    _isScanning = true;
    _notifyListeners();
    
    try {
      final interfaces = await NetworkInterface.list();
      if (interfaces.isEmpty) return;
      
      final localIP = interfaces.first.addresses.first.address;
      final subnet = localIP.substring(0, localIP.lastIndexOf('.'));
      final List<Future> scans = [];
      
      for (int i = 1; i <= 254; i++) {
        final host = '$subnet.$i';
        if (host == localIP) continue;
        scans.add(_checkPeer(host));
      }
      
      await Future.wait(scans);
    } catch (e) {
      debugPrint('Error en descubrimiento: $e');
    }
    
    _isScanning = false;
    _notifyListeners();
  }

  static Future<void> _checkPeer(String host) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(milliseconds: 500);
      final request = await client.getUrl(Uri.parse('http://$host:$_port/ping'));
      final response = await request.close();
      if (response.statusCode == 200 && !_peers.contains(host)) {
        _peers.add(host);
        _notifyListeners();
        debugPrint('🔵 Peer encontrado: $host');
      }
      client.close();
    } catch (_) {}
  }

  static Future<void> _syncWithPeers() async {
    if (_peers.isEmpty) return;
    
    for (final peer in _peers.toList()) {
      try {
        final db = await DatabaseService.database;
        final localActs = await db.query(
          'actividad',
          where: 'sync_enviado = 0',
          orderBy: 'id DESC',
          limit: 50,
        );
        
        if (localActs.isEmpty) continue;
        
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        final request = await client.postUrl(Uri.parse('http://$peer:$_port/sync'));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'actividades': localActs}));
        final response = await request.close();
        
        if (response.statusCode == 200) {
          for (final act in localActs) {
            await db.update('actividad', {'sync_enviado': 1}, where: 'id = ?', whereArgs: [act['id']]);
          }
          debugPrint('✅ Sincronizado con $peer');
        }
        client.close();
      } catch (e) {
        _peers.remove(peer);
        _notifyListeners();
        debugPrint('❌ Peer perdido: $peer');
      }
    }
  }

  static Future<void> _receiveData(Map<String, dynamic> data) async {
    try {
      final db = await DatabaseService.database;
      final acts = (data['actividades'] as List<dynamic>?) ?? [];
      
      for (final act in acts) {
        final exists = await db.query(
          'actividad',
          where: 'id = ?',
          whereArgs: [act['id']],
        );
        
        if (exists.isEmpty) {
          await db.insert('actividad', Map<String, dynamic>.from(act));
          debugPrint('📥 Actividad recibida: ${act['falta_causa']}');
        }
      }
    } catch (e) {
      debugPrint('Error recibiendo datos: $e');
    }
  }

  static Future<void> broadcast(Map<String, dynamic> actividad) async {
    if (_peers.isEmpty) return;
    
    for (final peer in _peers) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 3);
        final request = await client.postUrl(Uri.parse('http://$peer:$_port/sync'));
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode({'actividades': [actividad]}));
        await request.close();
        client.close();
      } catch (e) {
        debugPrint('Error broadcasting a $peer: $e');
      }
    }
  }
}
