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
    
    final exists = await File(path).exists();
    
    if (!exists) {
      // Crear base de datos desde cero si no existe
      final db = await openDatabase(path, version: 1, onCreate: _onCreate);
      return db;
    }
    
    return await openDatabase(path);
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tablas existentes...
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
    
    // Insertar usuario admin por defecto
    await db.insert('directiva', {
      'nombre': 'admin',
      'apellidos': 'admin',
      'ci': 'admin',
      'password': 'admin123',
      'ocupacion': 'director',
      'activo': 1,
    });
  }

  static Future<bool> initSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioJson = prefs.getString('usuario');
      if (usuarioJson != null) {
        final Map<String, dynamic> userData = jsonDecode(usuarioJson);
        _usuarioActual = Usuario.fromJson(userData);
        return true;
      }
      return false;
    } catch (e) {
      print("Error initSession: $e");
      return false;
    }
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
    try {
      final db = await database;
      
      // Normalizar entradas: eliminar espacios, convertir a minúsculas y eliminar acentos (versión simple)
      String normalizar(String texto) {
        return texto.trim().toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('é', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ü', 'u')
            .replaceAll('ñ', 'n');
      }
      
      final nom = normalizar(nombre);
      final ape = normalizar(apellidos);
      final pass = password.trim(); // La contraseña se compara exacta (sensible)
      
      // Consultar en la tabla correspondiente
      final results = await db.query(
        cargo,
        where: 'LOWER(TRIM(nombre)) = ? AND LOWER(TRIM(apellidos)) = ? AND password = ? AND activo = 1',
        whereArgs: [nom, ape, pass],
      );
      
      if (results.isNotEmpty) {
        final userData = results.first;
        // Convertir id a int
        final id = userData['id'] is int ? userData['id'] : int.tryParse(userData['id'].toString()) ?? 0;
        final peloton = userData['peloton'] is int ? userData['peloton'] : int.tryParse(userData['peloton'].toString());
        
        final usuario = Usuario(
          id: id,
          nombre: userData['nombre'] as String? ?? '',
          apellidos: userData['apellidos'] as String? ?? '',
          ci: userData['ci']?.toString() ?? '',
          cargo: cargo,
          ocupacion: userData['ocupacion'] as String?,
          grado: userData['grado'] as String?,
          peloton: peloton,
          activo: userData['activo'] as int? ?? 1,
        );
        await saveSession(usuario);
        return {'success': true, 'usuario': usuario};
      }
      return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
    } catch (e) {
      print("Error en login: $e");
      return {'success': false, 'message': 'Error interno: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    final db = await database;
    return await db.rawQuery(
      "SELECT * FROM estudiante WHERE nombre LIKE ? OR apellidos LIKE ? OR ci LIKE ? LIMIT 30",
      ['%$query%', '%$query%', '%$query%']
    );
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    final db = await database;
    final tabla = tipo == 'merito' ? 'meritos' : 'demeritos';
    return await db.query(tabla, orderBy: 'id');
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    if (_usuarioActual == null) return {'success': false, 'stats': {}, 'semana_actual': []};
    return {
      'success': true,
      'stats': {'meritos_semana': 0, 'demeritos_semana': 0, 'balance_semana': 0},
      'semana_actual': [],
      'alarma_activa': false,
    };
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    if (_usuarioActual == null) return {'success': false};
    return {
      'success': true,
      'stats': {'meritos': 0, 'demeritos': 0},
      'ultimas_actividades': [],
    };
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    final db = await database;
    for (final dest in data['destinatarios'] as List) {
      for (final act in data['actividades'] as List) {
        final idEnd = 'estudiante_${dest['id']}';
        await db.insert('actividad', {
          'id_star': data['cargo_notificador'],
          'id_end': idEnd,
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
