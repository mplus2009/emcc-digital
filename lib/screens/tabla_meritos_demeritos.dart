import ../services/database_service.dart;
// lib/screens/tabla_meritos_demeritos.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';

class TablaMeritosDemeritos extends StatefulWidget {
  const TablaMeritosDemeritos({super.key});

  @override
  State<TablaMeritosDemeritos> createState() => _TablaMeritosDemeritosState();
}

class _TablaMeritosDemeritosState extends State<TablaMeritosDemeritos>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _meritos = [];
  List<Map<String, dynamic>> _demeritos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final m = await DatabaseService.getCatalogo('merito');
    final d = await DatabaseService.getCatalogo('demerito');
    setState(() {
      _meritos = m;
      _demeritos = d;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Méritos y Deméritos'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Méritos'), Tab(text: 'Deméritos')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [_lista(_meritos, true), _lista(_demeritos, false)],
            ),
    );
  }

  Widget _lista(List<Map<String, dynamic>> items, bool esMerito) {
    final cats = <String, List<Map<String, dynamic>>>{};
    for (final i in items) {
      cats.putIfAbsent(i['categoria'] ?? 'Sin categoría', () => []).add(i);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cats.length,
      itemBuilder: (ctx, i) {
        final cat = cats.keys.elementAt(i);
        final lista = cats[cat]!;
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cat,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E3C72),
                ),
              ),
              const SizedBox(height: 12),
              ...lista.map((item) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF0F0F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            esMerito ? '${item['causa'] ?? ''}' : '${item['falta'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: esMerito
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            esMerito
                                ? '+${item['meritos'] ?? 0}'
                                : '-${item['demeritos_10mo'] ?? 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: esMerito
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
