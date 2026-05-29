import 'package:emcc_digital/services/database_service.dart';
// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../config/app_strings.dart';
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

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidosController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginConQR() async {
    final resultado = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(builder: (_) => const EscanerScreen()),
    );
    
    if (resultado == null || resultado.isEmpty || !mounted) return;
    
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      _showSnackBar(AppStrings.qrInvalid, Colors.red);
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
      _showSnackBar(response['message'] ?? AppStrings.loginError, Colors.red);
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
      body: Container(
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
                      const Column(
                        children: [
                          Icon(Icons.school, size: 50, color: Color(0xFF1E3C72)),
                          SizedBox(height: 8),
                          Text(
                            AppStrings.login,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3C72),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppStrings.loginSubtitle,
                            style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
                          ),
                        ],
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
                              AppStrings.scanQR,
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
                              AppStrings.manualLogin,
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
                          labelText: AppStrings.nameLabel,
                          hintText: AppStrings.nameHint,
                          prefixIcon: Icon(Icons.person, color: Color(0xFF2A5298)),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fillName : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _apellidosController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.lastNameLabel,
                          hintText: AppStrings.lastNameHint,
                          prefixIcon: Icon(Icons.people, color: Color(0xFF2A5298)),
                        ),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => v == null || v.trim().isEmpty ? AppStrings.fillLastName : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: AppStrings.passwordLabel,
                          hintText: AppStrings.passwordHint,
                          prefixIcon: const Icon(Icons.lock, color: Color(0xFF2A5298)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFF2A5298),
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? AppStrings.fillPassword : null,
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _cargo.isEmpty ? null : _cargo,
                        decoration: const InputDecoration(
                          labelText: AppStrings.roleLabel,
                          prefixIcon: Icon(Icons.badge, color: Color(0xFF2A5298)),
                        ),
                        hint: const Text(AppStrings.roleHint),
                        items: AppStrings.roles.map((c) => DropdownMenuItem(
                          value: c['value'],
                          child: Text(c['label']!),
                        )).toList(),
                        onChanged: (v) => setState(() => _cargo = v ?? ''),
                        validator: (v) => v == null || v.isEmpty ? AppStrings.fillRole : null,
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
                                  AppStrings.loginButton,
                                  style: TextStyle(fontSize: 18),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        AppStrings.loginFooter,
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
    );
  }
}
