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
    
    // Verificar si la base de datos existe
    final exists = await File(path).exists();
    
    if (!exists) {
      // Copiar desde assets
      try {
        final data = await rootBundle.load('assets/data/emcc_sistema.db');
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
      } catch (e) {
        // Si no existe el archivo, crear base de datos vacía
        return await openDatabase(path, version: 1, onCreate: _onCreate);
      }
    }
    
    return await openDatabase(path);
  }

  static Future<void> _onCreate(Database db, int version) async {
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
      CREATE TABLE IF NOT EXISTS directiva (
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
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alarma_config (
        id INTEGER PRIMARY KEY DEFAULT 1,
        limite_10mo INTEGER DEFAULT 15,
        limite_11no INTEGER DEFAULT 11,
        limite_12mo INTEGER DEFAULT 10
      )
    ''');
  }

  static Future<bool> initSession() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString('usuario');
    if (usuarioJson != null) {
      final Map<String, dynamic> userData = jsonDecode(usuarioJson);
      _usuarioActual = Usuario(
        id: userData['id'] ?? 0,
        nombre: userData['nombre'] ?? '',
        apellidos: userData['apellidos'] ?? '',
        ci: userData['ci'] ?? '',
        cargo: userData['cargo'] ?? 'estudiante',
        ocupacion: userData['ocupacion'],
        grado: userData['grado'],
        peloton: userData['peloton'],
      );
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
    final results = await db.query(
      cargo,
      where: 'nombre = ? AND apellidos = ? AND password = ? AND activo = 1',
      whereArgs: [nombre, apellidos, password],
      limit: 1,
    );
    
    if (results.isNotEmpty) {
      final userData = results.first;
      final usuario = Usuario(
        id: userData['id'] as int,
        nombre: userData['nombre'] as String,
        apellidos: userData['apellidos'] as String,
        ci: userData['ci'] as String,
        cargo: cargo,
        ocupacion: userData['ocupacion'] as String?,
        grado: userData['grado'] as String?,
        peloton: userData['peloton'] as int?,
      );
      await saveSession(usuario);
      return {'success': true, 'usuario': usuario};
    }
    return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    final db = await database;
    return await db.rawQuery(
      "SELECT e.*, "
      "COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end='estudiante_'||e.id AND tipo='merito'),0) as meritos, "
      "COALESCE((SELECT SUM(cantidad) FROM actividad WHERE id_end='estudiante_'||e.id AND tipo='demerito'),0) as demeritos "
      "FROM estudiante e WHERE e.nombre LIKE ? OR e.apellidos LIKE ? OR e.ci LIKE ? LIMIT 30",
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
    final idEnd = '${_usuarioActual!.cargo}_${_usuarioActual!.id}';
    final hoy = DateTime.now();
    final fechaInicio = DateTime(hoy.year, hoy.month, hoy.day - hoy.weekday + 1).toString().split(' ')[0];
    
    final meritos = await db.rawQuery(
      'SELECT COALESCE(SUM(cantidad),0) as total FROM actividad WHERE id_end=? AND tipo="merito" AND fecha>=?',
      [idEnd, fechaInicio]
    );
    
    final demeritos = await db.rawQuery(
      'SELECT COALESCE(SUM(cantidad),0) as total FROM actividad WHERE id_end=? AND tipo="demerito" AND fecha>=?',
      [idEnd, fechaInicio]
    );
    
    final actividades = await db.rawQuery(
      "SELECT a.*, 'Sistema' as notificador FROM actividad a WHERE a.id_end=? AND a.fecha>=? ORDER BY a.fecha DESC, a.hora DESC LIMIT 20",
      [idEnd, fechaInicio]
    );
    
    final meritosTotal = (meritos.first['total'] as int?) ?? 0;
    final demeritosTotal = (demeritos.first['total'] as int?) ?? 0;
    
    return {
      'success': true,
      'stats': {
        'meritos_semana': meritosTotal,
        'demeritos_semana': demeritosTotal,
        'balance_semana': meritosTotal - demeritosTotal,
      },
      'semana_actual': actividades,
      'alarma_activa': demeritosTotal >= 15,
    };
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    if (_usuarioActual == null) return {'success': false};
    
    final db = await database;
    final idEnd = '${_usuarioActual!.cargo}_${_usuarioActual!.id}';
    
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
    final db = await database;
    final String? idStar = data['id_star'] != null ? '${data['cargo_notificador']}_${data['id_star']}' : null;
    
    for (final dest in data['destinatarios'] as List) {
      for (final act in data['actividades'] as List) {
        await db.insert('actividad', {
          'id_star': idStar,
          'id_end': 'estudiante_${dest['id']}',
          'tipo': act['tipo'],
          'categoria': act['categoria'],
          'falta_causa': act['nombre'],
          'cantidad': act['cantidad'],
          'fecha': data['fecha'],
          'hora': data['hora'],
          'observaciones': data['observaciones'],
          'leido': 0,
          'sync_enviado': 0,
        });
      }
    }
    
    return {'success': true};
  }
}
