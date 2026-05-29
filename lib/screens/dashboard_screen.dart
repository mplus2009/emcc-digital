// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/mesh_status_indicator.dart';
import '../models/usuario.dart';
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

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;
  final _bc = TextEditingController();
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bc.dispose();
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

  void _go(String route) {
    Widget page;
    switch (route) {
      case 'perfil':
        page = const PerfilScreen();
        break;
      case 'tabla':
        page = const TablaMeritosDemeritos();
        break;
      case 'config':
        page = const ConfiguracionScreen();
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final u = DatabaseService.usuario;
    final stats = _data?['stats'] as Map<String, dynamic>?;
    final esEst = u?.cargo == 'estudiante';
    final puedeNotificar = ['directiva', 'oficial', 'profesor'].contains(u?.cargo);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${u?.nombre ?? ""}'),
        actions: [
          const MeshStatusIndicator(),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'logout') {
                DatabaseService.logout().then((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                });
              } else {
                _go(v);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'perfil', child: Text('Mi Perfil')),
              const PopupMenuItem(value: 'tabla', child: Text('Tabla Méritos/Deméritos')),
              const PopupMenuItem(value: 'config', child: Text('Configuración')),
              const PopupMenuItem(value: 'logout', child: Text('Cerrar Sesión')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '👋 Bienvenido!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E3C72)),
                  ),
                  Text(
                    'Panel de control - ${u?.cargo ?? ""}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (puedeNotificar) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(children: [
                  const Text('Buscar Estudiante', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
                  TextField(
                    controller: _bc,
                    decoration: const InputDecoration(
                      hintText: 'Nombre, apellidos o CI...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _search,
                  ),
                  ..._results.map((e) => Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e['nombre']} ${e['apellidos']}',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              'CI: ${e['CI']}',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificarScreen(destinatarioPrecargado: e),
                          ),
                        ),
                        child: const Text('Reportar'),
                      ),
                    ]),
                  )),
                ]),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: puedeNotificar
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificarScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Notificar'),
              backgroundColor: const Color(0xFF1E3C72),
            )
          : null,
    );
  }
}
