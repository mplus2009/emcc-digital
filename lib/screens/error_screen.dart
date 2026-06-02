// lib/screens/error_screen.dart
import 'package:flutter/material.dart';
import 'package:emcc_digital/services/debug_logger.dart';

class ErrorScreen extends StatelessWidget {
  final dynamic error;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const ErrorScreen({
    super.key,
    required this.error,
    this.stackTrace,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    // Guardar el error en los logs
    DebugLogger.error("Pantalla de error mostrada", error);
    if (stackTrace != null) {
      DebugLogger.error("Stack trace", stackTrace.toString());
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E3C72),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono de error
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 30),
                
                // Título
                const Text(
                  'ERROR CRÍTICO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Mensaje
                Text(
                  'La aplicación ha encontrado un error inesperado',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Tarjeta con detalles del error
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles del error:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          error.toString(),
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      if (stackTrace != null) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Stack trace:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              stackTrace.toString(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Reiniciar la app
                          DebugLogger.log("Usuario presionó REINICIAR");
                          // Limpiar sesión corrupta si existe
                          DatabaseService.logout().then((_) {
                            // Reiniciar la app
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const SplashScreen()),
                            );
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reiniciar App'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Salir de la app
                          DebugLogger.log("Usuario presionó SALIR");
                          // Mostrar diálogo de confirmación
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Salir'),
                              content: const Text('¿Deseas salir de la aplicación?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    // Salir de la app
                                    // En Android, esto cierra la app
                                    // En iOS, esto no funciona igual
                                    // Usamos exit(0) como último recurso
                                    // ignore: deprecated_member_use
                                    exit(0);
                                  },
                                  child: const Text('Salir', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.exit_to_app),
                        label: const Text('Salir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Botón para compartir el error
                OutlinedButton.icon(
                  onPressed: () {
                    DebugLogger.log("Usuario presionó COMPARTIR ERROR");
                    // Copiar error al portapapeles
                    final errorText = "Error EMCC Digital:\n${error.toString()}\n\nStack trace:\n${stackTrace?.toString() ?? 'No disponible'}";
                    Clipboard.setData(ClipboardData(text: errorText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error copiado al portapapeles'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir error'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white30),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Import necesario para exit
import 'dart:io';
import 'package:flutter/services.dart';
import 'database_service.dart';
import 'splash_screen.dart';
