// lib/services/database_service.dart - Parte 1
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../models/actividad.dart';

class DatabaseService {
  static Database? _database;
  static Usuario? _usuarioActual;
  static const String _sessionKey = 'user_session';
  static const String _sessionCargoKey = 'user_cargo';
  static const String _sessionIdKey = 'user_id';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'emcc_sistema.db');
    
    // Verificar si la base de datos existe
    bool exists = await File(path).exists();
    
    if (!exists) {
      // Copiar desde assets
      ByteData data = await rootBundle.load('assets/data/emcc_sistema.db');
      List<int> bytes = data.buffer.asUint8List();
      await File(path).writeAsBytes(bytes);
    }
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Crear tablas si no existen
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
      CREATE TABLE IF NOT EXISTS asignaturas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT, abreviatura TEXT, color_default TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS pelotones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grado TEXT, numero_peloton INTEGER, año_escolar TEXT, activo INTEGER DEFAULT 1
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
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS horario_config (
        id INTEGER PRIMARY KEY DEFAULT 1,
        hora_inicio TEXT, duracion_turno_lunes_jueves INTEGER,
        duracion_turno_viernes INTEGER, descanso_entre_turnos INTEGER,
        merienda_despues_turno INTEGER, duracion_merienda INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS horario_asignaturas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        peloton_id INTEGER, dia_semana INTEGER, turno_inicio INTEGER,
        turnos_duracion INTEGER, asignatura_id INTEGER, tipo_evento TEXT,
        semana TEXT, FOREIGN KEY(peloton_id) REFERENCES pelotones(id),
        FOREIGN KEY(asignatura_id) REFERENCES asignaturas(id)
      )
    ''');
    
    // Insertar configuración por defecto
    await db.insert('alarma_config', {
      'limite_10mo': 15,
      'limite_11no': 11,
      'limite_12mo': 10,
    });
  }
}
