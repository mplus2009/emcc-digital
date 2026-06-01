// lib/services/database_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../models/actividad.dart';
import 'debug_logger.dart';

class DatabaseService {
  static Database? _db;
  static Usuario? _usuarioActual;
  
  static Usuario? get usuario => _usuarioActual;
  static bool get isLoggedIn => _usuarioActual != null;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    final documentsPath = await getDatabasesPath();
    final path = join(documentsPath, 'emcc_sistema.db');
    
    final exists = await File(path).exists();
    
    if (!exists) {
      try {
        final data = await rootBundle.load('assets/data/data.sqlite');
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
        DebugLogger.log("✅ Base de datos copiada desde assets");
      } catch (e) {
        DebugLogger.log("📁 Creando base de datos nueva...");
        final db = await openDatabase(path, version: 1, onCreate: _onCreate);
        return db;
      }
    }
    
    final db = await openDatabase(path);
    DebugLogger.log("✅ Base de datos abierta");
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS directiva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estudiante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        grado TEXT, peloton INTEGER, ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profesor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS oficial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS actividad (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_star TEXT, id_end TEXT, tipo TEXT, categoria TEXT,
        falta_causa TEXT, cantidad INTEGER, fecha TEXT, hora TEXT,
        leido INTEGER DEFAULT 0, alegacion TEXT, observaciones TEXT,
        notificador TEXT, sync_enviado INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria TEXT, subcategoria TEXT, causa TEXT, meritos INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS demeritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria TEXT, subcategoria TEXT, falta TEXT,
        demeritos_10mo INTEGER, demeritos_11_12 INTEGER
      )
    ''');
    
    await db.insert('directiva', {
      'nombre': 'admin', 'apellidos': 'admin',
      'ci': 'admin', 'password': 'admin123',
      'ocupacion': 'director', 'activo': 1,
    });
  }

  static Future<bool> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      _usuarioActual = Usuario.fromJson(jsonDecode(usuarioJson));
      return true;
    }
    return false;
  }

  static Future<void> saveSession(Usuario usuario) async {
    _usuarioActual = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(usuario.toJson()));
  }

  static Future<void> logout() async {
    _usuarioActual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> login(String nombre, String apellidos, String password, String cargo) async {
    final db = await database;
    
    final nom = nombre.trim().toLowerCase();
    final ape = apellidos.trim().toLowerCase();
    final pass = password.trim();
    
    final results = await db.query(
      cargo,
      where: 'LOWER(TRIM(nombre)) = ? AND LOWER(TRIM(apellidos)) = ? AND password = ? AND activo = 1',
      whereArgs: [nom, ape, pass],
    );
    
    if (results.isNotEmpty) {
      final userData = results.first;
      
      final idRaw = userData['id'];
      final int userId;
      if (idRaw is int) {
        userId = idRaw;
      } else if (idRaw is String) {
        userId = int.tryParse(idRaw) ?? 0;
      } else {
        userId = 0;
      }
      
      final pelotonRaw = userData['peloton'];
      final int? peloton;
      if (pelotonRaw is int) {
        peloton = pelotonRaw;
      } else if (pelotonRaw is String) {
        peloton = int.tryParse(pelotonRaw);
      } else {
        peloton = null;
      }
      
      final usuario = Usuario(
        id: userId,
        nombre: userData['nombre'] as String? ?? '',
        apellidos: userData['apellidos'] as String? ?? '',
        ci: userData['ci']?.toString() ?? '',
        cargo: cargo,
        ocupacion: userData['ocupacion'] as String?,
        grado: userData['grado'] as String?,
        peloton: peloton,
      );
      await saveSession(usuario);
      return {'success': true, 'usuario': usuario};
    }
    return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    final db = await database;
    return await db.rawQuery(
      "SELECT e.* FROM estudiante e WHERE e.nombre LIKE ? OR e.apellidos LIKE ? OR e.ci LIKE ? LIMIT 30",
      ['%$query%', '%$query%', '%$query%']
    );
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    final db = await database;
    final tabla = tipo == 'merito' ? 'meritos' : 'demeritos';
    return await db.query(tabla, orderBy: 'id');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    if (_usuarioActual == null) return {'success': false};
    
    final db = await database;
    final idEnd = 'estudiante_${_usuarioActual!.id}';
    final hoy = DateTime.now();
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1)).toString().split(' ')[0];
    
    final meritos = await db.rawQuery(
      'SELECT COALESCE(SUM(cantidad),0) as total FROM actividad WHERE id_end=? AND tipo="merito" AND fecha>=?',
      [idEnd, inicioSemana]
    );
    final demeritos = await db.rawQuery(
      'SELECT COALESCE(SUM(cantidad),0) as total FROM actividad WHERE id_end=? AND tipo="demerito" AND fecha>=?',
      [idEnd, inicioSemana]
    );
    
    return {
      'success': true,
      'stats': {
        'meritos_semana': (meritos.first['total'] as int?) ?? 0,
        'demeritos_semana': (demeritos.first['total'] as int?) ?? 0,
        'balance_semana': ((meritos.first['total'] as int?) ?? 0) - ((demeritos.first['total'] as int?) ?? 0),
      },
      'semana_actual': [],
      'alarma_activa': ((demeritos.first['total'] as int?) ?? 0) >= 15,
    };
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    if (_usuarioActual == null) return {'success': false};
    
    final db = await database;
    final idEnd = 'estudiante_${_usuarioActual!.id}';
    
    final meritos = await db.rawQuery(
      'SELECT COALESCE(SUM(cantidad),0) as total FROM actividad WHERE id_end=? AND tipo="merito"',
      [idEnd]
    );
    final demeritos = await db.rawQuery(
      'SELECT COALESCE(SUM(cantidad),0) as total FROM actividad WHERE id_end=? AND tipo="demerito"',
      [idEnd]
    );
    final ultimas = await db.rawQuery(
      "SELECT a.*, 'Sistema' as notificador FROM actividad a WHERE a.id_end=? ORDER BY a.fecha DESC, a.hora DESC LIMIT 20",
      [idEnd]
    );
    
    return {
      'success': true,
      'stats': {
        'meritos': (meritos.first['total'] as int?) ?? 0,
        'demeritos': (demeritos.first['total'] as int?) ?? 0,
      },
      'ultimas_actividades': ultimas,
    };
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    DebugLogger.log("📤 Iniciando envío de notificación...");
    try {
      final db = await database;
      final String? idStar = data['id_star'] != null ? '${data['cargo_notificador']}_${data['id_star']}' : null;
      
      int actividadesGuardadas = 0;
      
      for (final dest in data['destinatarios'] as List) {
        for (final act in data['actividades'] as List) {
          final idEnd = 'estudiante_${dest['id']}';
          
          int cantidad = act['cantidad'] as int;
          if (act['tipo'] == 'demerito' && data['rangos'] != null) {
            final grado = dest['grado'];
            if (grado == '10mo') {
              cantidad = (data['rangos']['10mo'] as int?) ?? cantidad;
            } else {
              cantidad = (data['rangos']['11_12'] as int?) ?? cantidad;
            }
          }
          
          await db.insert('actividad', {
            'id_star': idStar,
            'id_end': idEnd,
            'tipo': act['tipo'],
            'categoria': act['categoria'],
            'falta_causa': act['nombre'],
            'cantidad': cantidad,
            'fecha': data['fecha'],
            'hora': data['hora'],
            'observaciones': data['observaciones'],
            'leido': 0,
            'sync_enviado': 0,
          });
          actividadesGuardadas++;
          DebugLogger.log("✅ Actividad guardada: ${act['nombre']} para estudiante ${dest['id']} con cantidad $cantidad");
        }
      }
      
      DebugLogger.log("✅ Notificación completada: $actividadesGuardadas actividades guardadas");
      return {'success': true};
    } catch (e) {
      DebugLogger.error("Error en enviarNotificacion", e);
      return {'success': false, 'message': e.toString()};
    }
  }
}
