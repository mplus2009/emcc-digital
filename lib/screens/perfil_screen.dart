import 'package:emcc_digital/services/database_service.dart';
// lib/screens/perfil_screen.dart
import 'package:flutter/material.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _loading = true;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await DatabaseService.getPerfil();
    if (!mounted) return;
    setState(() {
      _data = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = DatabaseService.usuario;
    final stats = _data?['stats'] as Map<String, dynamic>?;
    final ultimas = (_data?['ultimas_actividades'] as List<dynamic>?) ?? [];
    final balance = (stats?['meritos'] ?? 0) - (stats?['demeritos'] ?? 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Color(0xFF667EEA),
                          child: Icon(Icons.person, size: 45, color: Colors.white),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          u?.nombreCompleto ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E3C72),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            u?.cargo ?? '',
                            style: const TextStyle(color: Color(0xFF64748B)),
                          ),
                        ),
                        if (u?.cargo == 'estudiante') ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _box(
                                '${stats?['meritos'] ?? 0}',
                                'Méritos',
                                Colors.green,
                              ),
                              const SizedBox(width: 10),
                              _box(
                                '${stats?['demeritos'] ?? 0}',
                                'Deméritos',
                                Colors.red,
                              ),
                              const SizedBox(width: 10),
                              _box(
                                '$balance',
                                'Balance',
                                balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _mensaje(balance),
                        ],
                      ],
                    ),
                  ),
                  if (ultimas.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Últimas Actividades',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ...ultimas.map((act) {
                            final esMerito = act['tipo'] == 'merito';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: esMerito
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act['falta_causa'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Notificado por: ${act['notificador'] ?? 'Sistema'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    '${act['fecha']} - ${act['hora']?.toString().substring(0, 5) ?? ""}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      '${esMerito ? "+" : "-"}${act['cantidad']}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: esMerito
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _box(String v, String l, Color c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              v,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: c,
              ),
            ),
            Text(l, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _mensaje(int b) {
    final bg = b > 0 ? Colors.green : b < 0 ? Colors.red : Colors.orange;
    final icon = b > 0 ? Icons.emoji_events : b < 0 ? Icons.warning : Icons.balance;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bg, bg.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b > 0
                      ? '¡Excelente!'
                      : b < 0
                          ? 'Atención'
                          : 'Equilibrado',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  b > 0
                      ? 'Más méritos que deméritos'
                      : b < 0
                          ? 'Más deméritos que méritos'
                          : 'Méritos y deméritos igualados',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
