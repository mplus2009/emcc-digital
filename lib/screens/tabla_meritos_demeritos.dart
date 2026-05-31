// lib/screens/tabla_meritos_demeritos.dart
import 'package:flutter/material.dart';
import 'package:emcc_digital/services/database_service.dart';

class TablaMeritosDemeritos extends StatefulWidget {
  const TablaMeritosDemeritos({super.key});

  @override
  State<TablaMeritosDemeritos> createState() => _TablaMeritosDemeritosState();
}

class _TablaMeritosDemeritosState extends State<TablaMeritosDemeritos> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map<String, dynamic>> _meritos = [];
  List<Map<String, dynamic>> _demeritos = [];
  List<Map<String, dynamic>> _filteredMeritos = [];
  List<Map<String, dynamic>> _filteredDemeritos = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
    _searchController.addListener(_filterData);
  }

  Future<void> _load() async {
    final m = await DatabaseService.getCatalogo('merito');
    final d = await DatabaseService.getCatalogo('demerito');
    setState(() {
      _meritos = m;
      _demeritos = d;
      _filteredMeritos = m;
      _filteredDemeritos = d;
      _loading = false;
    });
  }

  void _filterData() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMeritos = _meritos.where((item) {
        final causa = item['causa']?.toLowerCase() ?? '';
        final categoria = item['categoria']?.toLowerCase() ?? '';
        return causa.contains(query) || categoria.contains(query);
      }).toList();
      _filteredDemeritos = _demeritos.where((item) {
        final falta = item['falta']?.toLowerCase() ?? '';
        final categoria = item['categoria']?.toLowerCase() ?? '';
        return falta.contains(query) || categoria.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Méritos y Deméritos'),
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Méritos'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Deméritos'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o categoría...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _lista(_filteredMeritos, true),
                      _lista(_filteredDemeritos, false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _lista(List<Map<String, dynamic>> items, bool esMerito) {
    if (items.isEmpty) {
      return const Center(child: Text('No hay resultados', style: TextStyle(color: Colors.grey)));
    }
    
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
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3C72).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Icon(esMerito ? Icons.emoji_events : Icons.warning_amber,
                        color: esMerito ? Colors.green : Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Text(cat, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: lista.map((item) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            esMerito ? '${item['causa'] ?? ''}' : '${item['falta'] ?? ''}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: esMerito ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            esMerito ? '+${item['meritos'] ?? 0}' : '-${item['demeritos_10mo'] ?? 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: esMerito ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
