// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'debug_logger.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static Timer? _checkTimer;
  
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(initSettings);
    DebugLogger.log("🔔 Servicio de notificaciones inicializado");
    
    // Iniciar verificación periódica
    _startPeriodicCheck();
  }
  
  static void _startPeriodicCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _checkNewActivities();
    });
    DebugLogger.log("🔔 Verificación periódica iniciada (cada 30 segundos)");
  }
  
  static Future<void> _checkNewActivities() async {
    try {
      final usuario = DatabaseService.usuario;
      if (usuario == null) return;
      
      final db = await DatabaseService.database;
      final idEnd = 'estudiante_${usuario.id}';
      
      // Buscar actividades no leídas
      final nuevas = await db.query(
        'actividad',
        where: 'id_end = ? AND leido = 0',
        whereArgs: [idEnd],
        orderBy: 'id DESC',
      );
      
      if (nuevas.isNotEmpty) {
        for (final act in nuevas) {
          // Marcar como leída
          await db.update(
            'actividad',
            {'leido': 1},
            where: 'id = ?',
            whereArgs: [act['id']],
          );
          
          // Mostrar notificación
          await _showNotification(act);
        }
        DebugLogger.log("🔔 ${nuevas.length} nuevas notificaciones mostradas");
      }
    } catch (e) {
      DebugLogger.error("Error verificando nuevas actividades", e);
    }
  }
  
  static Future<void> _showNotification(Map<String, dynamic> actividad) async {
    final esMerito = actividad['tipo'] == 'merito';
    final titulo = esMerito ? '🎉 Nuevo Mérito' : '⚠️ Nuevo Demérito';
    final cuerpo = '${actividad['falta_causa']} - ${esMerito ? "+" : "-"}${actividad['cantidad']} puntos';
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emcc_channel',
      'EMCC Digital',
      channelDescription: 'Notificaciones de méritos y deméritos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      actividad['id'] as int,
      titulo,
      cuerpo,
      details,
    );
  }
  
  static void stop() {
    _checkTimer?.cancel();
    _checkTimer = null;
    DebugLogger.log("🔔 Servicio de notificaciones detenido");
  }
}
