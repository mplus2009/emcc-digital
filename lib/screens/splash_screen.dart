// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:emcc_digital/services/database_service.dart';
import 'package:emcc_digital/services/debug_logger.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _status = "Iniciando...";
  bool _hasError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    DebugLogger.log("🚀 SplashScreen iniciada");
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    try {
      setState(() => _status = "Verificando base de datos...");
      DebugLogger.log("📁 Inicializando base de datos...");
      await DatabaseService.database;
      DebugLogger.log("✅ Base de datos lista");
      
      setState(() => _status = "Restaurando sesión...");
      DebugLogger.log("🔐 Restaurando sesión...");
      await DatabaseService.initSession();
      DebugLogger.log("✅ Sesión restaurada: ${DatabaseService.isLoggedIn}");
      
      setState(() => _status = "Iniciando servicios...");
      DebugLogger.log("🌐 Iniciando servicios...");
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      DebugLogger.log("✅ App inicializada correctamente");
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DatabaseService.isLoggedIn 
              ? const DashboardScreen() 
              : const LoginScreen(),
        ),
      );
    } catch (e, stackTrace) {
      DebugLogger.error("Error en inicialización", e);
      DebugLogger.error("Stack trace", stackTrace.toString());
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _status = "Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'EMCC DIGITAL',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Sistema de Gestión Escolar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 50),
                      if (!_hasError) ...[
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.8),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _status,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (_hasError) ...[
                        const Icon(Icons.error, color: Colors.red, size: 50),
                        const SizedBox(height: 16),
                        Text(
                          'Error al iniciar',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => _inicializarApp(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1E3C72),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
  // Asegurar que todo esté envuelto en try-catch
  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: _buildContent(context),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    // contenido actual del build
  }
