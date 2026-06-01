// lib/screens/notificar_screen.dart
import 'package:flutter/material.dart';
import 'package:emcc_digital/services/database_service.dart';
import 'package:emcc_digital/services/debug_logger.dart';
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
  int _rango10mo = 1;
  int _rango11_12 = 1;
  String? _catFiltro;
  late TabController _tabController;
  
  bool _usandoCuentaTemporal = false;
  String _notificadorNombre = '';
  String _notificadorCargo = '';
  final _tempNombreController = TextEditingController();
  final _tempPasswordController = TextEditingController();
  bool _mostrarTemporalForm = false;
  bool _showDebug = false;
  int _tapCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fc.text = DateTime.now().toString().split(' ')[0];
    _hc.text = DateTime.now().toString().substring(11, 16);
    if (widget.destinatarioPrecargado != null) {
      _dest.add(widget.destinatarioPrecargado!);
    }
    _load();
    
    final u = DatabaseService.usuario;
    if (u != null) {
      _notificadorNombre = u.nombreCompleto;
      _notificadorCargo = u.cargo;
    }
    DebugLogger.log("📱 NotificarScreen iniciada");
  }

  void _onHeaderTap() {
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
      final nombre = _tipo == 'merito' ? (a['causa'] ?? '') : (a['falta'] ?? '');
      final categoria = a['categoria'] ?? '';
      final matchesQuery = query.isEmpty || nombre.toLowerCase().contains(query);
      final matchesCategory = _catFiltro == null || categoria == _catFiltro;
      return matchesQuery && matchesCategory;
    }).toList();
    return filtered;
  }

  int _getCantidadParaGrado(String grado) {
    if (_tipo == 'merito') {
      return int.tryParse(_cantidadController.text) ?? 1;
    }
    return grado == '10mo' ? _rango10mo : _rango11_12;
  }

  @override
  void dispose() {
    _bc.dispose();
    _searchActController.dispose();
    _fc.dispose();
    _hc.dispose();
    _obs.dispose();
    _cantidadController.dispose();
    _tempNombreController.dispose();
    _tempPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _verificarTemporal() async {
    final nombreCompleto = _tempNombreController.text.trim();
    final password = _tempPasswordController.text.trim();
    if (nombreCompleto.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete nombre y contraseña'), backgroundColor: Colors.orange));
      return;
    }
    
    final partes = nombreCompleto.split(' ');
    final nombre = partes.first;
    final apellidos = partes.skip(1).join(' ');
    
    final db = await DatabaseService.database;
    for (final cargo in ['directiva', 'profesor', 'oficial', 'estudiante']) {
      final result = await db.query(
        cargo,
        where: 'LOWER(TRIM(nombre)) = ? AND LOWER(TRIM(apellidos)) = ? AND password = ? AND activo = 1',
        whereArgs: [nombre.toLowerCase(), apellidos.toLowerCase(), password],
      );
      if (result.isNotEmpty) {
        setState(() {
          _usandoCuentaTemporal = true;
          _notificadorNombre = '$nombre $apellidos';
          _notificadorCargo = cargo;
          _mostrarTemporalForm = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta temporal verificada'), backgroundColor: Colors.green));
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Credenciales incorrectas'), backgroundColor: Colors.red));
  }

  Future<void> _escanearQRTemporal() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(builder: (_) => const EscanerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      final datos = result.first;
      setState(() {
        _usandoCuentaTemporal = true;
        _notificadorNombre = '${datos['nombre']} ${datos['apellidos']}';
        _notificadorCargo = datos['cargo'] ?? 'estudiante';
        _mostrarTemporalForm = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta temporal cargada desde QR'), backgroundColor: Colors.green));
    }
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
        title: GestureDetector(
          onTap: _onHeaderTap,
          child: const Text('Notificar Actividad', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
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
            Tab(icon: Icon(Icons.person), text: 'Notificador'),
            Tab(icon: Icon(Icons.settings), text: 'Detalles'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildDestinatariosTab(),
              _buildActividadesTab(cats, hay10, hay11),
              _buildNotificadorTab(),
              _buildDetallesTab(puede),
            ],
          ),
          if (_showDebug)
            _buildDebugPanel(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(puede),
    );
  }

  Widget _buildDebugPanel() {
    return Positioned(
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
                  GestureDetector(
                    onTap: () => setState(() => _showDebug = false),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
            SizedBox(height: 200, child: DebugLogger.buildDebugPanel()),
          ],
        ),
      ),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destinatarios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    if (_dest.isEmpty)
                      const Center(child: Text('No hay destinatarios', style: TextStyle(color: Colors.grey)))
                    else
                      Wrap(spacing: 8, runSpacing: 8, children: _dest.asMap().entries.map((entry) => Chip(
                        label: Text(entry.value['nombre'], style: const TextStyle(color: Colors.white)),
                        backgroundColor: const Color(0xFF1E3C72),
                        deleteIcon: const Icon(Icons.close, color: Colors.white70, size: 18),
                        onDeleted: () => setState(() => _dest.removeAt(entry.key)),
                      )).toList()),
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
                          setState(() { _search = []; _bc.clear(); });
                        },
                      ),
                    )),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<List<Map<String, dynamic>>>(
                          context, MaterialPageRoute(builder: (_) => const EscanerScreen()));
                        if (result != null && mounted) setState(() => _dest.addAll(result));
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear QR'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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

  Widget _buildActividadesTab(Set<String> cats, bool hay10, bool hay11) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actividades', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'merito', label: Text('Mérito'), icon: Icon(Icons.emoji_events)),
                          ButtonSegment(value: 'demerito', label: Text('Demérito'), icon: Icon(Icons.warning_amber)),
                        ],
                        selected: {_tipo},
                        onSelectionChanged: (Set<String> newSelection) => setState(() => _tipo = newSelection.first),
                      )),
                    ]),
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
                      onChanged: (_) => setState(() {}),
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
                    if (_sel != null) ...[
                      const SizedBox(height: 16),
                      if (_tipo == 'demerito' && (hay10 || hay11))
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              const Text('Valores por grado', style: TextStyle(fontWeight: FontWeight.bold)),
                              if (hay10) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Text('10mo Grado:'),
                                  const Spacer(),
                                  IconButton(onPressed: () => setState(() => _rango10mo = _rango10mo > 1 ? _rango10mo - 1 : 1), icon: const Icon(Icons.remove)),
                                  Text('$_rango10mo', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  IconButton(onPressed: () => setState(() => _rango10mo = _rango10mo < 3 ? _rango10mo + 1 : 3), icon: const Icon(Icons.add)),
                                ]),
                              ],
                              if (hay11) ...[
                                const SizedBox(height: 8),
                                Row(children: [
                                  const Text('11no/12mo Grado:'),
                                  const Spacer(),
                                  IconButton(onPressed: () => setState(() => _rango11_12 = _rango11_12 > 1 ? _rango11_12 - 1 : 1), icon: const Icon(Icons.remove)),
                                  Text('$_rango11_12', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                  IconButton(onPressed: () => setState(() => _rango11_12 = _rango11_12 < 3 ? _rango11_12 + 1 : 3), icon: const Icon(Icons.add)),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          _acts.add({
                            'nombre': _tipo == 'merito' ? _sel!['causa'] : _sel!['falta'],
                            'cantidad': _tipo == 'merito' ? (int.tryParse(_cantidadController.text) ?? 1) : 1,
                            'tipo': _tipo,
                            'categoria': _sel!['categoria'],
                          });
                          setState(() => _sel = null);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar actividad'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificadorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quién notifica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.account_circle, size: 48, color: Color(0xFF1E3C72)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_notificadorNombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_notificadorCargo, style: const TextStyle(color: Colors.grey)),
                        if (_usandoCuentaTemporal)
                          const Chip(
                            label: Text('Temporal', style: TextStyle(fontSize: 12)),
                            backgroundColor: Colors.orange,
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _mostrarTemporalForm = !_mostrarTemporalForm),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Cambiar'),
                  ),
                ],
              ),
              if (_mostrarTemporalForm) ...[
                const Divider(),
                const SizedBox(height: 12),
                TextField(
                  controller: _tempNombreController,
                  decoration: const InputDecoration(labelText: 'Nombre y Apellidos', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tempPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _verificarTemporal,
                        icon: const Icon(Icons.verified),
                        label: const Text('Verificar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _escanearQRTemporal,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Escanear QR'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetallesTab(bool puede) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: TextField(controller: _fc, decoration: const InputDecoration(labelText: 'Fecha', border: OutlineInputBorder()), readOnly: true,
                        onTap: () async {
                          final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                          if (d != null) _fc.text = d.toString().split(' ')[0];
                        })),
                      const SizedBox(width: 12),
                      Expanded(child: TextField(controller: _hc, decoration: const InputDecoration(labelText: 'Hora', border: OutlineInputBorder()), readOnly: true,
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                          if (t != null) _hc.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        })),
                    ]),
                    const SizedBox(height: 16),
                    const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(controller: _obs, maxLines: 3, decoration: const InputDecoration(hintText: 'Notas adicionales...', border: OutlineInputBorder())),
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
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: puede && !_sending ? _enviarNotificacion : null,
          icon: _sending ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send),
          label: Text(_sending ? 'Enviando...' : 'Enviar Notificación'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    );
  }

  Future<void> _enviarNotificacion() async {
    setState(() => _sending = true);
    DebugLogger.log("📤 Enviando notificación...");
    
    final u = DatabaseService.usuario;
    
    final rangos = <String, int>{};
    if (_tipo == 'demerito' && _sel != null) {
      rangos['10mo'] = _rango10mo;
      rangos['11_12'] = _rango11_12;
    }
    
    final result = await DatabaseService.enviarNotificacion({
      'destinatarios': _dest,
      'actividades': _acts,
      'fecha': _fc.text,
      'hora': _hc.text,
      'id_star': _usandoCuentaTemporal ? null : u?.id,
      'cargo_notificador': _usandoCuentaTemporal ? _notificadorCargo : u?.cargo,
      'observaciones': _obs.text,
      'rangos': rangos,
    });
    
    if (mounted) {
      setState(() => _sending = false);
      
      if (result['success'] == true) {
        DebugLogger.log("✅ Notificación enviada exitosamente");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación enviada'), backgroundColor: Colors.green));
        setState(() {
          _dest = [];
          _acts = [];
          _tabController.index = 0;
        });
      } else {
        DebugLogger.error("Error al enviar notificación", result['message']);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result['message']}'), backgroundColor: Colors.red));
      }
    }
  }
}
