// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:emcc_digital/services/database_service.dart';
import 'package:emcc_digital/services/debug_logger.dart';
import 'dashboard_screen.dart';
import 'escaner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _passwordController = TextEditingController();
  String _cargo = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showDebug = false; // ← Desactivado por defecto (cambiar a true para activar)

  @override
  void initState() {
    super.initState();
    DebugLogger.log("📱 Pantalla de Login iniciada");
    // Para activar el panel de depuración, toca 5 veces el logo de la app
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método secreto para activar debug (tocar 5 veces el logo)
  void _onLogoPressed() {
    _tapCount++;
    if (_tapCount >= 5) {
      setState(() {
        _showDebug = !_showDebug;
        _tapCount = 0;
      });
      DebugLogger.log(_showDebug ? "🔍 Panel de depuración ACTIVADO" : "🔍 Panel de depuración DESACTIVADO");
    }
    Future.delayed(const Duration(seconds: 2), () {
      _tapCount = 0;
    });
  }
  int _tapCount = 0;

  Future<void> _loginConQR() async {
    DebugLogger.log("📷 Intentando login con QR...");
    final resultado = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(builder: (_) => const EscanerScreen()),
    );
    
    if (resultado == null || resultado.isEmpty) {
      DebugLogger.log("❌ QR cancelado o sin datos");
      return;
    }
    
    final datos = resultado.first;
    setState(() => _isLoading = true);
    
    final response = await DatabaseService.login(
      datos['nombre'] ?? '',
      datos['apellidos'] ?? '',
      datos['ci'] ?? '',
      datos['cargo'] ?? 'estudiante',
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (response['success'] == true) {
      DebugLogger.log("✅ Login con QR exitoso!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showSnackBar(response['message'] ?? 'Error en QR', Colors.red);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final response = await DatabaseService.login(
      _nombreController.text.trim(),
      _apellidosController.text.trim(),
      _passwordController.text,
      _cargo,
    );
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    
    if (response['success'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showSnackBar(response['message'] ?? 'Usuario o contraseña incorrectos', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 60,
                          offset: const Offset(0, 30),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _onLogoPressed,
                            child: const Column(
                              children: [
                                Icon(Icons.school, size: 50, color: Color(0xFF1E3C72)),
                                SizedBox(height: 8),
                                Text(
                                  'Acceso',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E3C72),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Inicia sesión en el sistema',
                                  style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 35),
                          Container(
                            padding: const EdgeInsets.only(bottom: 25),
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _loginConQR,
                                icon: const Icon(Icons.qr_code_scanner, size: 28),
                                label: const Text(
                                  'Escanear QR',
                                  style: TextStyle(fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3C72),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  elevation: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Row(
                            children: [
                              Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'o ingresa manualmente',
                                  style: TextStyle(color: Color(0xFF888888), fontSize: 14),
                                ),
                              ),
                              Expanded(child: Divider(color: Color(0xFFE0E0E0))),
                            ],
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              hintText: 'Ingresa tu nombre',
                              prefixIcon: Icon(Icons.person, color: Color(0xFF2A5298)),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _apellidosController,
                            decoration: const InputDecoration(
                              labelText: 'Apellidos',
                              hintText: 'Ingresa tus apellidos',
                              prefixIcon: Icon(Icons.people, color: Color(0xFF2A5298)),
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa tus apellidos' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              hintText: 'Ingresa tu contraseña',
                              prefixIcon: const Icon(Icons.lock, color: Color(0xFF2A5298)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF2A5298),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Ingresa tu contraseña' : null,
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            value: _cargo.isEmpty ? null : _cargo,
                            decoration: const InputDecoration(
                              labelText: 'Cargo',
                              prefixIcon: Icon(Icons.badge, color: Color(0xFF2A5298)),
                            ),
                            hint: const Text('Selecciona tu cargo'),
                            items: const [
                              DropdownMenuItem(value: 'directiva', child: Text('Directiva')),
                              DropdownMenuItem(value: 'oficial', child: Text('Oficial')),
                              DropdownMenuItem(value: 'profesor', child: Text('Profesor')),
                              DropdownMenuItem(value: 'estudiante', child: Text('Estudiante')),
                            ],
                            onChanged: (v) => setState(() => _cargo = v ?? ''),
                            validator: (v) => v == null || v.isEmpty ? 'Selecciona tu cargo' : null,
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E3C72),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(fontSize: 18),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Ingresa con tu nombre, apellidos y contraseña',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Panel de depuración (oculto por defecto, aparece al tocar 5 veces el logo)
          if (_showDebug)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bug_report, color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            "DEBUG PANEL",
                            style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _showDebug = false),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 250,
                      child: DebugLogger.buildDebugPanel(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
