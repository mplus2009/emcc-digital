// lib/screens/notificar_screen.dart
import 'package:flutter/material.dart';
import 'package:emcc_digital/services/database_service.dart';
import 'package:emcc_digital/utils/role_checker.dart';
import 'escaner_screen.dart';

class NotificarScreen extends StatefulWidget {
  final Map<String, dynamic>? destinatarioPrecargado;
  const NotificarScreen({super.key, this.destinatarioPrecargado});

  @override
  State<NotificarScreen> createState() => _NotificarScreenState();
}

class _NotificarScreenState extends State<NotificarScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _dest = [];
  List<Map<String, dynamic>> _acts = [];
  List<Map<String, dynamic>> _catMeritos = [];
  List<Map<String, dynamic>> _catDemeritos = [];
  List<Map<String, dynamic>> _search = [];
  List<Map<String, dynamic>> _searchActividades = [];
  String _tipo = 'merito';
  bool _loading = true;
  bool _sending = false;
  final _bc = TextEditingController();
  final _searchActController = TextEditingController();
  final _fc = TextEditingController();
  final _hc = TextEditingController();
  final _obs = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  Map<String, dynamic>? _sel;
  double _s10 = 1;
  double _s11 = 1;
  String? _catFiltro;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fc.text = DateTime.now().toString().split(' ')[0];
    _hc.text = DateTime.now().toString().substring(11, 16);
    if (widget.destinatarioPrecargado != null) {
      _dest.add(widget.destinatarioPrecargado!);
    }
    _load();
  }

  Future<void> _load() async {
    _catMeritos = await DatabaseService.getCatalogo('merito');
    _catDemeritos = await DatabaseService.getCatalogo('demerito');
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _catActual =>
      _tipo == 'merito' ? _catMeritos : _catDemeritos;

  List<Map<String, dynamic>> get _filteredActividades {
    final query = _searchActController.text.toLowerCase();
    final filtered = _catActual.where((a) {
      final nombre = _tipo == 'merito' ? a['causa'] : a['falta'];
      final categoria = a['categoria'];
      final matchesQuery = query.isEmpty || nombre.toLowerCase().contains(query);
      final matchesCategory = _catFiltro == null || categoria == _catFiltro;
      return matchesQuery && matchesCategory;
    }).toList();
    return filtered;
  }

  int _calcCantidad() {
    if (_tipo == 'merito') {
      return int.tryParse(_cantidadController.text) ?? 1;
    }
    final hay10 = _dest.any((d) => d['grado'] == '10mo');
    final hay11 = _dest.any((d) => d['grado'] != '10mo');
    if (hay10 && hay11) return _s10.toInt() + _s11.toInt();
    if (hay10) return _s10.toInt();
    return _s11.toInt();
  }

  @override
  void dispose() {
    _bc.dispose();
    _searchActController.dispose();
    _fc.dispose();
    _hc.dispose();
    _obs.dispose();
    _cantidadController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final puede = _dest.isNotEmpty && _acts.isNotEmpty;
    final hay10 = _dest.any((d) => d['grado'] == '10mo');
    final hay11 = _dest.any((d) => d['grado'] != '10mo');
    final cats = {..._catActual.map((c) => c['categoria'] as String).where((c) => c != null)};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notificar Actividad', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: const Color(0xFF1E3C72),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Destinatarios'),
            Tab(icon: Icon(Icons.list_alt), text: 'Actividades'),
            Tab(icon: Icon(Icons.settings), text: 'Detalles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDestinatariosTab(),
          _buildActividadesTab(cats),
          _buildDetallesTab(puede, hay10, hay11),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(puede),
    );
  }

  Widget _buildDestinatariosTab() {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destinatarios agregados', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_dest.isEmpty)
                      const Center(child: Text('No hay destinatarios', style: TextStyle(color: Colors.grey)))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dest.asMap().entries.map((entry) => Chip(
                          label: Text(entry.value['nombre'], style: const TextStyle(color: Colors.white)),
                          backgroundColor: const Color(0xFF1E3C72),
                          deleteIcon: const Icon(Icons.close, color: Colors.white70, size: 18),
                          onDeleted: () => setState(() => _dest.removeAt(entry.key)),
                        )).toList(),
                      ),
                    const SizedBox(height: 20),
                    const Text('Buscar estudiantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _bc,
                      decoration: InputDecoration(
                        hintText: 'Nombre, apellidos o CI...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onChanged: (q) async {
                        if (q.length > 1) {
                          final r = await DatabaseService.buscarEstudiantes(q);
                          if (mounted) setState(() => _search = r);
                        } else {
                          setState(() => _search = []);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    ..._search.map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(e['nombre'][0])),
                        title: Text('${e['nombre']} ${e['apellidos']}'),
                        subtitle: Text('CI: ${e['CI']} | Grado: ${e['grado'] ?? '10mo'}'),
                        trailing: const Icon(Icons.add_circle, color: Colors.green),
                        onTap: () {
                          _dest.add({
                            'id': '${e['id']}',
                            'nombre': '${e['nombre']} ${e['apellidos']}',
                            'ci': '${e['CI']}',
                            'grado': e['grado'] ?? '10mo',
                          });
                          setState(() {
                            _search = [];
                            _bc.clear();
                          });
                        },
                      ),
                    )),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<List<Map<String, dynamic>>>(
                          context,
                          MaterialPageRoute(builder: (_) => const EscanerScreen()),
                        );
                        if (result != null && mounted) {
                          setState(() => _dest.addAll(result));
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear QR'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActividadesTab(Set<String> cats) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actividades agregadas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_acts.isEmpty)
                      const Center(child: Text('No hay actividades', style: TextStyle(color: Colors.grey)))
                    else
                      ..._acts.asMap().entries.map((entry) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: entry.value['tipo'] == 'merito' ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(entry.value['tipo'] == 'merito' ? Icons.emoji_events : Icons.warning_amber,
                                color: entry.value['tipo'] == 'merito' ? Colors.green : Colors.red),
                            const SizedBox(width: 12),
                            Expanded(child: Text(entry.value['nombre'])),
                            Text('${entry.value['tipo'] == 'merito' ? '+' : '-'}${entry.value['cantidad']}',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: entry.value['tipo'] == 'merito' ? Colors.green : Colors.red)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () => setState(() => _acts.removeAt(entry.key))),
                          ],
                        ),
                      )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'merito', label: Text('Mérito'), icon: Icon(Icons.emoji_events)),
                              ButtonSegment(value: 'demerito', label: Text('Demérito'), icon: Icon(Icons.warning_amber)),
                            ],
                            selected: {_tipo},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() => _tipo = newSelection.first);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_tipo == 'merito')
                      TextField(
                        controller: _cantidadController,
                        decoration: const InputDecoration(labelText: 'Valor', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _catFiltro,
                      decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        ...cats.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) => setState(() => _catFiltro = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchActController,
                      decoration: InputDecoration(
                        hintText: 'Buscar mérito o demérito...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredActividades.length,
                        itemBuilder: (context, index) {
                          final item = _filteredActividades[index];
                          final nombre = _tipo == 'merito' ? item['causa'] : item['falta'];
                          final valor = _tipo == 'merito' ? '+${item['meritos']}' : '${item['demeritos_10mo']}';
                          return ListTile(
                            leading: Icon(_tipo == 'merito' ? Icons.emoji_events : Icons.warning_amber,
                                color: _tipo == 'merito' ? Colors.green : Colors.red),
                            title: Text(nombre, style: const TextStyle(fontSize: 14)),
                            subtitle: Text(item['categoria']),
                            trailing: Chip(label: Text(valor), backgroundColor: _tipo == 'merito' ? Colors.green.shade100 : Colors.red.shade100),
                            onTap: () => setState(() => _sel = item),
                          );
                        },
                      ),
                    ),
                    if (_sel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _acts.add({
                              'nombre': _tipo == 'merito' ? _sel!['causa'] : _sel!['falta'],
                              'cantidad': _calcCantidad(),
                              'tipo': _tipo,
                              'categoria': _sel!['categoria'],
                            });
                            setState(() => _sel = null);
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar actividad'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetallesTab(bool puede, bool hay10, bool hay11) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fc,
                            decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder()),
                            readOnly: true,
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (d != null) _fc.text = d.toString().split(' ')[0];
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _hc,
                            decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder()),
                            readOnly: true,
                            onTap: () async {
                              final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                              if (t != null) _hc.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_tipo == 'demerito' && _sel != null && (hay10 || hay11)) ...[
                      const Text('Valores por grado', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (hay10)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              const Text('10mo Grado', style: TextStyle(fontWeight: FontWeight.bold)),
                              Slider(min: 1, max: 3, value: _s10, onChanged: (v) => setState(() => _s10 = v)),
                              Text('${_s10.toInt()} puntos'),
                            ],
                          ),
                        ),
                      if (hay11) const SizedBox(height: 12),
                      if (hay11)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              const Text('11no/12mo Grado', style: TextStyle(fontWeight: FontWeight.bold)),
                              Slider(min: 1, max: 3, value: _s11, onChanged: (v) => setState(() => _s11 = v)),
                              Text('${_s11.toInt()} puntos'),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _obs,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Notas adicionales...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool puede) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: puede && !_sending ? _enviarNotificacion : null,
          icon: _sending ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
          label: Text(_sending ? 'Enviando...' : 'Enviar Notificación'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
    );
  }

  Future<void> _enviarNotificacion() async {
    setState(() => _sending = true);
    final u = DatabaseService.usuario;
    await DatabaseService.enviarNotificacion({
      'destinatarios': _dest,
      'actividades': _acts,
      'fecha': _fc.text,
      'hora': _hc.text,
      'id_star': u?.id,
      'cargo_notificador': u?.cargo,
      'observaciones': _obs.text,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notificación enviada'), backgroundColor: Colors.green));
      setState(() {
        _dest = [];
        _acts = [];
        _sending = false;
        _tabController.index = 0;
      });
    }
  }
}
