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
      try {
        final data = await rootBundle.load('assets/data/data.sqlite');
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
        print("Base de datos copiada desde assets");
      } catch (e) {
        print("Error copiando BD: $e");
        return await openDatabase(path, version: 1, onCreate: _onCreate);
      }
    }
    
    return await openDatabase(path);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS directiva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    
    await db.insert('directiva', {
      'nombre': 'admin',
      'apellidos': 'admin',
      'ci': 'admin',
      'password': 'admin123',
      'ocupacion': 'director',
      'activo': 1,
    });
    print("Base de datos creada con usuario admin");
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
        cargo: userData['cargo'] ?? 'directiva',
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
    
    // Limpiar espacios y normalizar a minúsculas
    final nom = nombre.trim().toLowerCase();
    final ape = apellidos.trim().toLowerCase();
    final pass = password.trim();
    
    print("Login - Nombre: '$nom', Apellidos: '$ape', Password: '$pass', Cargo: '$cargo'");
    
    // Primero intentar con LOWER() para comparación insensible a mayúsculas
    var results = await db.query(
      cargo,
      where: 'LOWER(TRIM(nombre)) = ? AND LOWER(TRIM(apellidos)) = ? AND password = ? AND activo = 1',
      whereArgs: [nom, ape, pass],
    );
    
    print("Resultados con LOWER: ${results.length}");
    
    // Si no encuentra, intentar con comparación exacta (por si acaso)
    if (results.isEmpty) {
      results = await db.query(
        cargo,
        where: 'nombre = ? AND apellidos = ? AND password = ? AND activo = 1',
        whereArgs: [nombre, apellidos, password],
      );
      print("Resultados con exacta: ${results.length}");
    }
    
    if (results.isNotEmpty) {
      final userData = results.first;
      print("Usuario encontrado: ${userData['nombre']} ${userData['apellidos']}");
      
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
    return {'success': true, 'stats': {'meritos_semana': 0, 'demeritos_semana': 0, 'balance_semana': 0}, 'semana_actual': [], 'alarma_activa': false};
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    if (_usuarioActual == null) return {'success': false};
    return {'success': true, 'stats': {'meritos': 0, 'demeritos': 0}, 'ultimas_actividades': []};
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    return {'success': true};
  }
}
