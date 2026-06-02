// lib/screens/error_screen.dart
import 'package:flutter/material.dart';
import '../services/debug_logger.dart';
import 'splash_screen.dart';

class ErrorScreen extends StatelessWidget {
  final String errorMessage;
  final StackTrace? stackTrace;

  const ErrorScreen({
    super.key,
    required this.errorMessage,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    DebugLogger.error("Error mostrado en pantalla", errorMessage);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1E3C72),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Error en la aplicación',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Mensaje de error:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    DebugLogger.log("Usuario reiniciando app...");
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SplashScreen()),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar aplicación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1E3C72),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
