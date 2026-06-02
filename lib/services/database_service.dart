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
    DebugLogger.log("📁 Iniciando _initDatabase...");
    
    final documentsPath = await getDatabasesPath();
    final path = join(documentsPath, 'emcc_sistema.db');
    
    DebugLogger.log("📁 Ruta: $path");
    
    final exists = await File(path).exists();
    DebugLogger.log("📁 ¿Existe? $exists");
    
    if (!exists) {
      DebugLogger.log("📁 Base de datos no existe, creando nueva...");
      try {
        // Intentar copiar desde assets
        final data = await rootBundle.load('assets/data/data.sqlite');
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
        DebugLogger.log("✅ Base de datos copiada desde assets. Tamaño: ${bytes.length}");
      } catch (e) {
        DebugLogger.log("⚠️ No se pudo copiar desde assets: $e");
        DebugLogger.log("📁 Creando base de datos desde cero...");
        final db = await openDatabase(path, version: 1, onCreate: _onCreate);
        DebugLogger.log("✅ Base de datos nueva creada");
        return db;
      }
    }
    
    final db = await openDatabase(path);
    DebugLogger.log("✅ Base de datos abierta correctamente");
    
    // Verificar que hay datos
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM directiva');
      final count = result.first['count'] as int? ?? 0;
      DebugLogger.log("📊 Tabla directiva tiene $count registros");
      
      if (count == 0) {
        DebugLogger.log("⚠️ No hay usuarios, insertando admin...");
        await db.insert('directiva', {
          'nombre': 'admin', 'apellidos': 'admin',
          'ci': 'admin', 'password': 'admin123',
          'ocupacion': 'director', 'activo': 1,
        });
        DebugLogger.log("✅ Usuario admin insertado");
      }
    } catch (e) {
      DebugLogger.error("Error verificando datos", e);
    }
    
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    DebugLogger.log("🆕 Creando esquema de base de datos...");
    
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
    
    // Insertar datos de ejemplo en méritos
    await db.insert('meritos', {
      'categoria': 'Académico', 'subcategoria': 'Participación',
      'causa': 'Participación activa en clase', 'meritos': 2,
    });
    await db.insert('meritos', {
      'categoria': 'Conducta', 'subcategoria': 'Compañerismo',
      'causa': 'Ayudar a un compañero', 'meritos': 3,
    });
    
    // Insertar datos de ejemplo en deméritos
    await db.insert('demeritos', {
      'categoria': 'Conducta', 'subcategoria': 'Disciplina',
      'falta': 'Llegar tarde a clase', 'demeritos_10mo': 1, 'demeritos_11_12': 1,
    });
    await db.insert('demeritos', {
      'categoria': 'Académico', 'subcategoria': 'Tareas',
      'falta': 'No entregar tarea', 'demeritos_10mo': 2, 'demeritos_11_12': 2,
    });
    
    DebugLogger.log("✅ Esquema creado y datos insertados");
  }

  static Future<bool> initSession() async {
    DebugLogger.log("🔐 initSession...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioJson = prefs.getString('usuario');
      if (usuarioJson != null) {
        final Map<String, dynamic> userData = jsonDecode(usuarioJson);
        _usuarioActual = Usuario.fromJson(userData);
        DebugLogger.log("✅ Sesión restaurada: ${_usuarioActual?.nombre}");
        return true;
      }
      DebugLogger.log("ℹ️ No hay sesión guardada");
      return false;
    } catch (e) {
      DebugLogger.error("Error restaurando sesión", e);
      return false;
    }
  }

  static Future<void> saveSession(Usuario usuario) async {
    _usuarioActual = usuario;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usuario', jsonEncode(usuario.toJson()));
    DebugLogger.log("✅ Sesión guardada: ${usuario.nombre}");
  }

  static Future<void> logout() async {
    _usuarioActual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    DebugLogger.log("✅ Sesión cerrada");
  }

  static Future<Map<String, dynamic>> login(String nombre, String apellidos, String password, String cargo) async {
    DebugLogger.log("🔐 Login: $nombre $apellidos - $cargo");
    try {
      final db = await database;
      
      final nom = nombre.trim().toLowerCase();
      final ape = apellidos.trim().toLowerCase();
      final pass = password.trim();
      
      final results = await db.query(
        cargo,
        where: 'LOWER(TRIM(nombre)) = ? AND LOWER(TRIM(apellidos)) = ? AND password = ? AND activo = 1',
        whereArgs: [nom, ape, pass],
      );
      
      DebugLogger.log("📊 Resultados: ${results.length}");
      
      if (results.isNotEmpty) {
        final userData = results.first;
        
        final idRaw = userData['id'];
        final int userId = idRaw is int ? idRaw : (idRaw is String ? int.tryParse(idRaw) ?? 0 : 0);
        
        final pelotonRaw = userData['peloton'];
        final int? peloton = pelotonRaw is int ? pelotonRaw : (pelotonRaw is String ? int.tryParse(pelotonRaw) : null);
        
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
    } catch (e) {
      DebugLogger.error("Error en login", e);
      return {'success': false, 'message': 'Error: $e'};
    }
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
    DebugLogger.log("📤 Enviando notificación...");
    try {
      final db = await database;
      final String? idStar = data['id_star'] != null ? '${data['cargo_notificador']}_${data['id_star']}' : null;
      
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
          DebugLogger.log("✅ Actividad guardada: ${act['nombre']}");
        }
      }
      return {'success': true};
    } catch (e) {
      DebugLogger.error("Error en enviarNotificacion", e);
      return {'success': false, 'message': e.toString()};
    }
  }
}
