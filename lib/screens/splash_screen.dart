// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _error = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    try {
      // Inicializar base de datos
      await DatabaseService.database;
      
      // Restaurar sesión
      await DatabaseService.initSession();
      
      if (!mounted) return;
      
      // Navegar según sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DatabaseService.isLoggedIn 
              ? const DashboardScreen() 
              : const LoginScreen(),
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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
        child: Center(
          child: _isLoading
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    Text(
                      'Iniciando EMCC Digital...',
                      style: TextStyle(color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 60, color: Colors.red),
                    const SizedBox(height: 20),
                    Text(
                      'Error al iniciar',
                      style: const TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _inicializar(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
