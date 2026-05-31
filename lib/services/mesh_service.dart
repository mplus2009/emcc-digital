// lib/services/mesh_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'database_service.dart';
import 'debug_logger.dart';

class MeshService {
  static bool _isRunning = false;
  static bool _isScanning = false;
  static final List<String> _peers = [];
  static final List<void Function()> _listeners = [];
  
  // Bluetooth
  static BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  static FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  static List<BluetoothDevice> _discoveredDevices = [];
  static BluetoothConnection? _connection;
  
  // WiFi Direct
  static HttpServer? _server;
  static const int _port = 8888;
  static String? _localIp;
  
  static bool get isRunning => _isRunning;
  static bool get isScanning => _isScanning;
  static int get peersCount => _peers.length;
  static List<String> get peersList => List.unmodifiable(_peers);
  static List<BluetoothDevice> get discoveredDevices => _discoveredDevices;
  static BluetoothState get bluetoothState => _bluetoothState;

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
    
    DebugLogger.log("🟢 Iniciando Mesh Service...");
    
    // Inicializar Bluetooth
    await _initBluetooth();
    
    // Inicializar WiFi Direct
    await _initWiFiDirect();
    
    // Escanear dispositivos periódicamente
    _startPeriodicScan();
    
    _notifyListeners();
    DebugLogger.log("✅ Mesh Service iniciado");
  }

  static Future<void> _initBluetooth() async {
    try {
      _bluetoothState = await _bluetooth.state;
      DebugLogger.log("📡 Estado Bluetooth: ${_bluetoothState.toString()}");
      
      _bluetooth.onStateChanged().listen((state) {
        _bluetoothState = state;
        DebugLogger.log("📡 Bluetooth cambió a: $state");
        _notifyListeners();
      });
      
      if (_bluetoothState.isEnabled) {
        await _startBluetoothDiscovery();
      }
    } catch (e) {
      DebugLogger.error("Error inicializando Bluetooth", e);
    }
  }

  static Future<void> _startBluetoothDiscovery() async {
    if (!_bluetoothState.isEnabled) {
      DebugLogger.log("⚠️ Bluetooth no está habilitado");
      return;
    }
    
    _isScanning = true;
    _notifyListeners();
    DebugLogger.log("🔍 Escaneando dispositivos Bluetooth...");
    
    try {
      _discoveredDevices = await _bluetooth.getBondedDevices();
      for (var device in _discoveredDevices) {
        if (!_peers.contains(device.address)) {
          _peers.add(device.address);
          DebugLogger.log("🔵 Dispositivo Bluetooth encontrado: ${device.name} (${device.address})");
        }
      }
    } catch (e) {
      DebugLogger.error("Error escaneando Bluetooth", e);
    }
    
    _isScanning = false;
    _notifyListeners();
  }

  static Future<void> _initWiFiDirect() async {
    try {
      // Obtener IP local
      final info = NetworkInfoPlus();
      _localIp = await info.getWifiIP();
      DebugLogger.log("📶 IP local: $_localIp");
      
      // Iniciar servidor HTTP
      await _startHttpServer();
    } catch (e) {
      DebugLogger.error("Error inicializando WiFi Direct", e);
    }
  }

  static Future<void> _startHttpServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      DebugLogger.log("🟢 Servidor HTTP iniciado en puerto $_port");
      
      _server!.listen((HttpRequest request) async {
        try {
          if (request.method == 'POST' && request.uri.path == '/sync') {
            final body = await utf8.decodeStream(request);
            final data = jsonDecode(body);
            await _receiveData(data);
            request.response.statusCode = 200;
            request.response.write('{"status":"ok"}');
          } else if (request.uri.path == '/ping') {
            request.response.statusCode = 200;
            request.response.write('{"device":"EMCC","status":"online"}');
          } else {
            request.response.statusCode = 404;
          }
          await request.response.close();
        } catch (e) {
          DebugLogger.error("Error en servidor HTTP", e);
          request.response.statusCode = 500;
          await request.response.close();
        }
      });
    } catch (e) {
      DebugLogger.error("Error iniciando servidor HTTP", e);
    }
  }

  static void _startPeriodicScan() {
    Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_isRunning) {
        await _startBluetoothDiscovery();
        await _discoverWiFiPeers();
      }
    });
  }

  static Future<void> _discoverWiFiPeers() async {
    if (_localIp == null) return;
    
    try {
      final subnet = _localIp!.substring(0, _localIp!.lastIndexOf('.'));
      for (int i = 1; i <= 254; i++) {
        final peerIp = '$subnet.$i';
        if (peerIp == _localIp) continue;
        
        try {
          final client = http.Client();
          final response = await client.get(
            Uri.parse('http://$peerIp:$_port/ping'),
            timeout: Duration(milliseconds: 500),
          );
          if (response.statusCode == 200 && !_peers.contains(peerIp)) {
            _peers.add(peerIp);
            _notifyListeners();
            DebugLogger.log("🌐 Peer WiFi encontrado: $peerIp");
          }
          client.close();
        } catch (_) {}
      }
    } catch (e) {
      DebugLogger.error("Error descubriendo peers WiFi", e);
    }
  }

  static Future<void> _receiveData(Map<String, dynamic> data) async {
    try {
      DebugLogger.log("📥 Datos recibidos: ${data['type']}");
      
      if (data['type'] == 'activity') {
        final db = await DatabaseService.database;
        final actividad = data['activity'];
        
        // Verificar si ya existe
        final exists = await db.query(
          'actividad',
          where: 'id = ?',
          whereArgs: [actividad['id']],
        );
        
        if (exists.isEmpty) {
          await db.insert('actividad', actividad);
          DebugLogger.log("✅ Actividad sincronizada: ${actividad['falta_causa']}");
        }
      }
    } catch (e) {
      DebugLogger.error("Error recibiendo datos", e);
    }
  }

  static Future<void> broadcastActivity(Map<String, dynamic> actividad) async {
    DebugLogger.log("📡 Transmitiendo actividad a ${_peers.length} dispositivos...");
    
    final data = {
      'type': 'activity',
      'activity': actividad,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Enviar por Bluetooth
    for (var peer in _peers) {
      // Aquí iría la conexión Bluetooth real
      DebugLogger.log("📡 Enviando a $peer");
    }
    
    // Enviar por HTTP a peers WiFi
    for (var peer in _peers) {
      if (peer.contains('.')) { // Es IP
        try {
          final client = http.Client();
          await client.post(
            Uri.parse('http://$peer:$_port/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          ).timeout(Duration(seconds: 3));
          client.close();
          DebugLogger.log("✅ Enviado a $peer");
        } catch (e) {
          DebugLogger.error("Error enviando a $peer", e);
        }
      }
    }
  }

  static void stop() {
    _isRunning = false;
    _server?.close();
    _peers.clear();
    _discoveredDevices.clear();
    _notifyListeners();
    DebugLogger.log("🔴 Mesh Service detenido");
  }
}
