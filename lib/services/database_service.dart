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
    DebugLogger.log("📁 Obteniendo instancia de database...");
    if (_db != null) {
      DebugLogger.log("✅ Database ya inicializada");
      return _db!;
    }
    _db = await _initDatabase();
    return _db!;
  }

  static Future<Database> _initDatabase() async {
    DebugLogger.log("📁 Inicializando base de datos...");
    
    final documentsPath = await getDatabasesPath();
    final path = join(documentsPath, 'emcc_sistema.db');
    
    DebugLogger.log("📁 Ruta: $path");
    
    final exists = await File(path).exists();
    DebugLogger.log("📁 ¿Existe? $exists");
    
    if (!exists) {
      DebugLogger.log("📁 Base de datos no existe, intentando copiar desde assets...");
      try {
        final data = await rootBundle.load('assets/data/data.sqlite');
        final bytes = data.buffer.asUint8List();
        await File(path).writeAsBytes(bytes);
        DebugLogger.log("✅ Base de datos copiada exitosamente. Tamaño: ${bytes.length} bytes");
      } catch (e) {
        DebugLogger.error("Error copiando base de datos", e);
        DebugLogger.log("📁 Creando base de datos nueva...");
        final db = await openDatabase(path, version: 1, onCreate: _onCreate);
        DebugLogger.log("✅ Base de datos nueva creada");
        return db;
      }
    }
    
    final db = await openDatabase(path);
    DebugLogger.log("✅ Base de datos abierta correctamente");
    
    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM directiva');
      final count = result.first['count'] as int? ?? 0;
      DebugLogger.log("📊 Tabla directiva tiene $count registros");
    } catch (e) {
      DebugLogger.error("Error verificando tabla directiva", e);
    }
    
    return db;
  }

  static Future<void> _onCreate(Database db, int version) async {
    DebugLogger.log("🆕 Creando base de datos nueva desde cero...");
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS directiva (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    DebugLogger.log("✅ Tabla directiva creada");
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS estudiante (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        grado TEXT, peloton INTEGER, ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    DebugLogger.log("✅ Tabla estudiante creada");
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS profesor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    DebugLogger.log("✅ Tabla profesor creada");
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS oficial (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, apellidos TEXT, ci TEXT, password TEXT,
        ocupacion TEXT, activo INTEGER DEFAULT 1
      )
    ''');
    DebugLogger.log("✅ Tabla oficial creada");
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS actividad (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_star TEXT, id_end TEXT, tipo TEXT, categoria TEXT,
        falta_causa TEXT, cantidad INTEGER, fecha TEXT, hora TEXT,
        leido INTEGER DEFAULT 0, alegacion TEXT, observaciones TEXT,
        notificador TEXT, sync_enviado INTEGER DEFAULT 0
      )
    ''');
    DebugLogger.log("✅ Tabla actividad creada");
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria TEXT, subcategoria TEXT, causa TEXT, meritos INTEGER
      )
    ''');
    DebugLogger.log("✅ Tabla meritos creada");
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS demeritos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        categoria TEXT, subcategoria TEXT, falta TEXT,
        demeritos_10mo INTEGER, demeritos_11_12 INTEGER
      )
    ''');
    DebugLogger.log("✅ Tabla demeritos creada");
    
    await db.insert('directiva', {
      'nombre': 'admin',
      'apellidos': 'admin',
      'ci': 'admin',
      'password': 'admin123',
      'ocupacion': 'director',
      'activo': 1,
    });
    DebugLogger.log("✅ Usuario admin insertado");
    
    await db.insert('meritos', {
      'categoria': 'Académico',
      'subcategoria': 'Participación',
      'causa': 'Participación activa en clase',
      'meritos': 2,
    });
    await db.insert('meritos', {
      'categoria': 'Conducta',
      'subcategoria': 'Compañerismo',
      'causa': 'Ayudar a un compañero',
      'meritos': 3,
    });
    DebugLogger.log("✅ Méritos de ejemplo insertados");
    
    await db.insert('demeritos', {
      'categoria': 'Conducta',
      'subcategoria': 'Disciplina',
      'falta': 'Llegar tarde a clase',
      'demeritos_10mo': 1,
      'demeritos_11_12': 1,
    });
    await db.insert('demeritos', {
      'categoria': 'Académico',
      'subcategoria': 'Tareas',
      'falta': 'No entregar tarea',
      'demeritos_10mo': 2,
      'demeritos_11_12': 2,
    });
    DebugLogger.log("✅ Deméritos de ejemplo insertados");
    
    DebugLogger.log("🎉 Base de datos creada exitosamente");
  }

  static Future<bool> initSession() async {
    DebugLogger.log("🔐 Inicializando sesión...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioJson = prefs.getString('usuario');
      if (usuarioJson != null) {
        final Map<String, dynamic> userData = jsonDecode(usuarioJson);
        _usuarioActual = Usuario.fromJson(userData);
        DebugLogger.log("✅ Sesión restaurada: ${_usuarioActual?.nombre} ${_usuarioActual?.apellidos}");
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
    DebugLogger.log("✅ Sesión guardada: ${usuario.nombre} ${usuario.apellidos}");
  }

  static Future<void> logout() async {
    _usuarioActual = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    DebugLogger.log("✅ Sesión cerrada");
  }

  static Future<Map<String, dynamic>> login(String nombre, String apellidos, String password, String cargo) async {
    DebugLogger.log("🔐 ===== INICIO DE LOGIN =====");
    DebugLogger.log("📝 Datos ingresados:");
    DebugLogger.log("   - Nombre: '$nombre'");
    DebugLogger.log("   - Apellidos: '$apellidos'");
    DebugLogger.log("   - Password: '${password.length} caracteres'");
    DebugLogger.log("   - Cargo: '$cargo'");
    
    try {
      final db = await database;
      
      final nom = nombre.trim().toLowerCase();
      final ape = apellidos.trim().toLowerCase();
      final pass = password.trim();
      
      DebugLogger.log("🔍 Buscando en tabla: $cargo");
      
      final results = await db.query(
        cargo,
        where: 'LOWER(TRIM(nombre)) = ? AND LOWER(TRIM(apellidos)) = ? AND password = ? AND activo = 1',
        whereArgs: [nom, ape, pass],
      );
      
      DebugLogger.log("📊 Resultados encontrados: ${results.length}");
      
      if (results.isNotEmpty) {
        final userData = results.first;
        
        // Extraer valores de forma segura
        final idValue = userData['id'];
        final userId = idValue is int ? idValue : (idValue is String ? int.tryParse(idValue) ?? 0 : 0);
        
        final nombreValue = userData['nombre'] as String? ?? '';
        final apellidosValue = userData['apellidos'] as String? ?? '';
        final ciValue = userData['ci']?.toString() ?? '';
        final ocupacionValue = userData['ocupacion'] as String?;
        final gradoValue = userData['grado'] as String?;
        
        int? pelotonValue;
        final pelotonRaw = userData['peloton'];
        if (pelotonRaw is int) {
          pelotonValue = pelotonRaw;
        } else if (pelotonRaw is String) {
          pelotonValue = int.tryParse(pelotonRaw);
        }
        
        DebugLogger.log("✅ Usuario encontrado!");
        DebugLogger.log("   - ID: $userId");
        DebugLogger.log("   - Nombre: $nombreValue");
        DebugLogger.log("   - Apellidos: $apellidosValue");
        
        final usuario = Usuario(
          id: userId,
          nombre: nombreValue,
          apellidos: apellidosValue,
          ci: ciValue,
          cargo: cargo,
          ocupacion: ocupacionValue,
          grado: gradoValue,
          peloton: pelotonValue,
        );
        await saveSession(usuario);
        DebugLogger.log("🎉 LOGIN EXITOSO!");
        return {'success': true, 'usuario': usuario};
      }
      
      DebugLogger.log("❌ LOGIN FALLIDO: Usuario no encontrado");
      return {'success': false, 'message': 'Usuario o contraseña incorrectos'};
      
    } catch (e, stackTrace) {
      DebugLogger.error("Error en login", e);
      DebugLogger.error("Stack trace", stackTrace.toString());
      return {'success': false, 'message': 'Error interno: $e'};
    }
  }

  static Future<List<Map<String, dynamic>>> buscarEstudiantes(String query) async {
    DebugLogger.log("🔍 Buscando estudiantes: '$query'");
    final db = await database;
    final results = await db.rawQuery(
      "SELECT e.* FROM estudiante e WHERE e.nombre LIKE ? OR e.apellidos LIKE ? OR e.ci LIKE ? LIMIT 30",
      ['%$query%', '%$query%', '%$query%']
    );
    DebugLogger.log("📊 Encontrados ${results.length} estudiantes");
    return results;
  }

  static Future<List<Map<String, dynamic>>> getCatalogo(String tipo) async {
    DebugLogger.log("📚 Obteniendo catálogo: $tipo");
    final db = await database;
    final tabla = tipo == 'merito' ? 'meritos' : 'demeritos';
    final results = await db.query(tabla, orderBy: 'id');
    DebugLogger.log("📊 Catálogo $tipo: ${results.length} elementos");
    return results;
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    DebugLogger.log("📊 Obteniendo dashboard");
    if (_usuarioActual == null) {
      DebugLogger.log("❌ No hay usuario logueado");
      return {'success': false, 'stats': {}, 'semana_actual': []};
    }
    return {'success': true, 'stats': {'meritos_semana': 0, 'demeritos_semana': 0, 'balance_semana': 0}, 'semana_actual': [], 'alarma_activa': false};
  }

  static Future<Map<String, dynamic>> getPerfil() async {
    DebugLogger.log("👤 Obteniendo perfil");
    if (_usuarioActual == null) return {'success': false};
    return {'success': true, 'stats': {'meritos': 0, 'demeritos': 0}, 'ultimas_actividades': []};
  }

  static Future<Map<String, dynamic>> enviarNotificacion(Map<String, dynamic> data) async {
    DebugLogger.log("📤 Enviando notificación");
    return {'success': true};
  }
}
