// lib/screens/dashboard_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/database_service.dart';
import '../services/debug_logger.dart';
import '../services/mesh_service.dart';
import '../models/usuario.dart';
import '../utils/role_checker.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';
import 'perfil_screen.dart';
import 'configuracion.dart';
import 'notificar_screen.dart';
import 'tabla_meritos_demeritos.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  Map<String, dynamic>? _data;
  final _bc = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final GlobalKey _qrKey = GlobalKey();
  bool _showDebug = false;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    DebugLogger.log("📱 Dashboard iniciado");
  }

  @override
  void dispose() {
    _bc.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await DatabaseService.getDashboard();
    if (!mounted) return;
    setState(() {
      _data = r;
      _loading = false;
    });
  }

  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }
    final r = await DatabaseService.buscarEstudiantes(q);
    setState(() => _results = r);
  }

  void _onWelcomeTap() {
    _tapCount++;
    if (_tapCount >= 5) {
      setState(() {
        _showDebug = !_showDebug;
        _tapCount = 0;
      });
      DebugLogger.log(_showDebug ? "🔍 Panel debug ACTIVADO" : "🔍 Panel debug DESACTIVADO");
    }
    Future.delayed(const Duration(seconds: 2), () => _tapCount = 0);
  }

  void _showQRModal() {
    final usuario = DatabaseService.usuario;
    if (usuario == null) return;
    
    final qrData = {
      'id': usuario.id,
      'nombre': usuario.nombre,
      'apellidos': usuario.apellidos,
      'ci': usuario.ci,
      'cargo': usuario.cargo,
      'grado': usuario.grado,
    };
    final qrString = Uri.encodeComponent(jsonEncode(qrData));
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 20),
            const Icon(Icons.qr_code, size: 50, color: Color(0xFF1E3C72)),
            const Text('Tu Código QR', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
              child: RepaintBoundary(
                key: _qrKey,
                child: Column(
                  children: [
                    QrImageView(data: qrString, version: QrVersions.auto, size: 200, backgroundColor: Colors.white, foregroundColor: const Color(0xFF1E3C72)),
                    Text(usuario.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3C72))),
                    Text('CI: ${usuario.ci}', style: TextStyle(color: Colors.grey[600])),
                    Text('Cargo: ${usuario.cargo}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('QR guardado'), backgroundColor: Colors.green)),
              icon: const Icon(Icons.download),
              label: const Text('Descargar QR'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
            ),
          ],
        ),
      ),
    );
  }

  void _go(String route) {
    Widget page;
    switch (route) {
      case 'perfil': page = const PerfilScreen(); break;
      case 'tabla': page = const TablaMeritosDemeritos(); break;
      case 'config': page = const ConfiguracionScreen(); break;
      default: return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    if (_loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: const Color(0xFF1E3C72))));
    }

    final u = DatabaseService.usuario;
    final esEstudiante = u?.cargo == 'estudiante';
    final puedeNotificar = RoleChecker.puedeNotificar(u);
    final stats = _data?['stats'] as Map<String, dynamic>?;
    final meritosSemana = stats?['meritos_semana'] ?? 0;
    final demeritosSemana = stats?['demeritos_semana'] ?? 0;
    final balanceSemana = meritosSemana - demeritosSemana;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(u?.nombre[0].toUpperCase() ?? 'U', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hola, ${u?.nombre ?? ""}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(u?.cargo?.toUpperCase() ?? '', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: Colors.white), onPressed: () => themeProvider.toggleTheme()),
          IconButton(icon: const Icon(Icons.qr_code, color: Colors.white), onPressed: _showQRModal),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (v) {
              if (v == 'logout') {
                DatabaseService.logout().then((_) => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())));
              } else {
                _go(v);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'perfil', child: Row(children: [Icon(Icons.person), SizedBox(width: 12), Text('Mi Perfil')])),
              const PopupMenuItem(value: 'tabla', child: Row(children: [Icon(Icons.list_alt), SizedBox(width: 12), Text('Méritos/Deméritos')])),
              const PopupMenuItem(value: 'config', child: Row(children: [Icon(Icons.settings), SizedBox(width: 12), Text('Configuración')])),
              const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout), SizedBox(width: 12), Text('Cerrar Sesión')])),
            ],
          ),
        ],
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _load,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GestureDetector(
                    onTap: _onWelcomeTap,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF1E3C72), Color(0xFF2A5298)]),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.celebration, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('¡Bienvenido!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('Sistema de Gestión Escolar', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                            child: Text(DateTime.now().toString().substring(0, 10), style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (esEstudiante) ...[
                    Row(
                      children: [
                        _buildStatCard('Méritos', meritosSemana, Colors.green, Icons.emoji_events),
                        const SizedBox(width: 12),
                        _buildStatCard('Deméritos', demeritosSemana, Colors.red, Icons.warning_amber),
                        const SizedBox(width: 12),
                        _buildStatCard('Balance', balanceSemana, Colors.blue, Icons.balance),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (puedeNotificar) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFF1E3C72).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                                child: const Icon(Icons.search, color: Color(0xFF1E3C72), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Text('Buscar Estudiante', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3C72))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _bc,
                            decoration: InputDecoration(
                              hintText: 'Nombre, apellidos o CI...',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA),
                            ),
                            onChanged: _search,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          ),
                          const SizedBox(height: 12),
                          ..._results.map((e) => _buildStudentCard(e, isDark)),
                          if (_results.isEmpty && _bc.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(child: Text('No se encontraron estudiantes', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey))),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                              child: const Icon(Icons.notifications_active, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Notificar Actividad', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                  Text('Registrar mérito o demérito', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_showDebug)
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bug_report, color: Colors.amber, size: 16),
                          const Text(" DEBUG PANEL", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          GestureDetector(onTap: () => setState(() => _showDebug = false), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                        ],
                      ),
                    ),
                    SizedBox(height: 250, child: DebugLogger.buildDebugPanel()),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: puedeNotificar
          ? FloatingActionButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificarScreen())),
              backgroundColor: const Color(0xFF10B981),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildStatCard(String title, int value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 24),
            ),
            Text(value.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> estudiante, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${estudiante['nombre']} ${estudiante['apellidos']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                Text('CI: ${estudiante['CI']}', style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificarScreen(destinatarioPrecargado: estudiante))),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3C72)),
            child: const Text('Notificar'),
          ),
        ],
      ),
    );
  }
}
