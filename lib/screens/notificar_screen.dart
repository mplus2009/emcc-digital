// lib/screens/notificar_screen.dart
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'escaner_screen.dart';

class NotificarScreen extends StatefulWidget {
  final Map<String, dynamic>? destinatarioPrecargado;
  const NotificarScreen({super.key, this.destinatarioPrecargado});

  @override
  State<NotificarScreen> createState() => _NotificarScreenState();
}

class _NotificarScreenState extends State<NotificarScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _destinatarios = [];
  List<Map<String, dynamic>> _actividades = [];
  List<Map<String, dynamic>> _catalogoMeritos = [];
  List<Map<String, dynamic>> _catalogoDemeritos = [];
  List<Map<String, dynamic>> _busquedaEstudiantes = [];
  String _tipoActividad = 'merito';
  bool _cargando = true;
  bool _enviando = false;
  final _buscarController = TextEditingController();
  final _buscarActividadController = TextEditingController();
  final _fechaController = TextEditingController();
  final _horaController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  Map<String, dynamic>? _actividadSeleccionada;
  int _rango10mo = 1;
  int _rango11_12 = 1;
  String? _categoriaFiltro;
  late TabController _tabController;
  
  bool _usandoCuentaTemporal = false;
  String _nombreNotificador = '';
  String _cargoNotificador = '';
  final _tempNombreController = TextEditingController();
  final _tempPasswordController = TextEditingController();
  bool _mostrarTemporalForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fechaController.text = DateTime.now().toString().split(' ')[0];
    _horaController.text = DateTime.now().toString().substring(11, 16);
    
    if (widget.destinatarioPrecargado != null) {
      _destinatarios.add(widget.destinatarioPrecargado!);
    }
    
    _cargarCatalogos();
    
    final usuario = DatabaseService.usuario;
    if (usuario != null) {
      _nombreNotificador = usuario.nombreCompleto;
      _cargoNotificador = usuario.cargo;
    }
  }

  Future<void> _cargarCatalogos() async {
    _catalogoMeritos = await DatabaseService.getCatalogo('merito');
    _catalogoDemeritos = await DatabaseService.getCatalogo('demerito');
    setState(() => _cargando = false);
  }

  List<Map<String, dynamic>> get _catalogoActual =>
      _tipoActividad == 'merito' ? _catalogoMeritos : _catalogoDemeritos;

  List<Map<String, dynamic>> get _actividadesFiltradas {
    final query = _buscarActividadController.text.toLowerCase();
    return _catalogoActual.where((a) {
      final nombre = _tipoActividad == 'merito' ? (a['causa'] ?? '') : (a['falta'] ?? '');
      final categoria = a['categoria'] ?? '';
      final matchesQuery = query.isEmpty || nombre.toLowerCase().contains(query);
      final matchesCategory = _categoriaFiltro == null || categoria == _categoriaFiltro;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  int _calcularCantidad() {
    if (_tipoActividad == 'merito') {
      return int.tryParse(_cantidadController.text) ?? 1;
    }
    final hay10mo = _destinatarios.any((d) => d['grado'] == '10mo');
    final hayOtros = _destinatarios.any((d) => d['grado'] != '10mo');
    int cantidad = 0;
    if (hay10mo) cantidad += _rango10mo;
    if (hayOtros) cantidad += _rango11_12;
    return cantidad;
  }

  @override
  void dispose() {
    _buscarController.dispose();
    _buscarActividadController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    _observacionesController.dispose();
    _cantidadController.dispose();
    _tempNombreController.dispose();
    _tempPasswordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: color),
    );
  }

  Future<void> _verificarTemporal() async {
    final nombreCompleto = _tempNombreController.text.trim();
    final password = _tempPasswordController.text.trim();
    if (nombreCompleto.isEmpty || password.isEmpty) {
      _mostrarSnackBar('Complete nombre y contraseña', Colors.orange);
      return;
    }
    
    final resultado = await DatabaseService.login(
      nombreCompleto.split(' ').first,
      nombreCompleto.split(' ').skip(1).join(' '),
      password,
      'directiva',
    );
    
    if (resultado['success'] == true) {
      setState(() {
        _usandoCuentaTemporal = true;
        _nombreNotificador = nombreCompleto;
        _cargoNotificador = resultado['usuario'].cargo;
        _mostrarTemporalForm = false;
      });
      _mostrarSnackBar('Cuenta temporal verificada', Colors.green);
    } else {
      _mostrarSnackBar('Credenciales incorrectas', Colors.red);
    }
  }

  Future<void> _enviarNotificacion() async {
    setState(() => _enviando = true);
    
    final rangos = <String, int>{};
    if (_tipoActividad == 'demerito' && _actividadSeleccionada != null) {
      rangos['10mo'] = _rango10mo;
      rangos['11_12'] = _rango11_12;
    }
    
    final result = await DatabaseService.enviarNotificacion({
      'destinatarios': _destinatarios,
      'actividades': _actividades,
      'fecha': _fechaController.text,
      'hora': _horaController.text,
      'id_star': _usandoCuentaTemporal ? null : DatabaseService.usuario?.id,
      'cargo_notificador': _usandoCuentaTemporal ? _cargoNotificador : DatabaseService.usuario?.cargo,
      'observaciones': _observacionesController.text,
      'rangos': rangos,
    });
    
    if (mounted) {
      setState(() => _enviando = false);
      
      if (result['success'] == true) {
        _mostrarSnackBar('Notificación enviada', Colors.green);
        setState(() {
          _destinatarios = [];
          _actividades = [];
          _tabController.index = 0;
        });
      } else {
        _mostrarSnackBar('Error: ${result['message']}', Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final puedeEnviar = _destinatarios.isNotEmpty && _actividades.isNotEmpty;
    final hay10mo = _destinatarios.any((d) => d['grado'] == '10mo');
    final hayOtros = _destinatarios.any((d) => d['grado'] != '10mo');
    final categorias = {..._catalogoActual.map((c) => c['categoria'] as String)};

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notificar Actividad'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Destinatarios'),
            Tab(icon: Icon(Icons.list_alt), text: 'Actividades'),
            Tab(icon: Icon(Icons.person), text: 'Notificador'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDestinatariosTab(),
          _buildActividadesTab(categorias, hay10mo, hayOtros),
          _buildNotificadorTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(puedeEnviar),
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destinatarios', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: _destinatarios.asMap().entries.map((entry) => Chip(
                        label: Text(entry.value['nombre']),
                        onDeleted: () => setState(() => _destinatarios.removeAt(entry.key)),
                      )).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('Buscar estudiantes', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _buscarController,
                      decoration: const InputDecoration(
                        hintText: 'Nombre, apellidos o CI...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (q) async {
                        if (q.length > 1) {
                          final r = await DatabaseService.buscarEstudiantes(q);
                          setState(() => _busquedaEstudiantes = r);
                        } else {
                          setState(() => _busquedaEstudiantes = []);
                        }
                      },
                    ),
                    ..._busquedaEstudiantes.map((e) => ListTile(
                      title: Text('${e['nombre']} ${e['apellidos']}'),
                      subtitle: Text('CI: ${e['ci']}'),
                      trailing: const Icon(Icons.add_circle, color: Colors.green),
                      onTap: () {
                        setState(() {
                          _destinatarios.add({
                            'id': '${e['id']}',
                            'nombre': '${e['nombre']} ${e['apellidos']}',
                            'ci': '${e['ci']}',
                            'grado': e['grado'] ?? '10mo',
                          });
                          _busquedaEstudiantes = [];
                          _buscarController.clear();
                        });
                      },
                    )),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push<List>(
                          context,
                          MaterialPageRoute(builder: (_) => const EscanerScreen()),
                        );
                        if (result != null && mounted) {
                          setState(() => _destinatarios.addAll(result.cast<Map<String, dynamic>>()));
                        }
                      },
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Escanear QR'),
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

  Widget _buildActividadesTab(Set<String> categorias, bool hay10mo, bool hayOtros) {
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Actividades agregadas', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ..._actividades.asMap().entries.map((entry) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: entry.value['tipo'] == 'merito' ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(entry.value['tipo'] == 'merito' ? Icons.emoji_events : Icons.warning_amber),
                          const SizedBox(width: 12),
                          Expanded(child: Text(entry.value['nombre'])),
                          Text('${entry.value['tipo'] == 'merito' ? '+' : '-'}${entry.value['cantidad']}'),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => setState(() => _actividades.removeAt(entry.key)),
                          ),
                        ],
                      ),
                    )),
                    if (_actividades.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: Text('No hay actividades')),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                            selected: {_tipoActividad},
                            onSelectionChanged: (set) => setState(() => _tipoActividad = set.first),
                          ),
                        ),
                      ],
                    ),
                    if (_tipoActividad == 'merito') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _cantidadController,
                        decoration: const InputDecoration(labelText: 'Valor (méritos)'),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _categoriaFiltro,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        ...categorias.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                      ],
                      onChanged: (v) => setState(() => _categoriaFiltro = v),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _buscarActividadController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _actividadesFiltradas.length,
                        itemBuilder: (ctx, i) {
                          final item = _actividadesFiltradas[i];
                          final nombre = _tipoActividad == 'merito' ? item['causa'] : item['falta'];
                          final valor = _tipoActividad == 'merito' ? '+${item['meritos']}' : '${item['demeritos_10mo']}';
                          return ListTile(
                            title: Text(nombre),
                            subtitle: Text(item['categoria']),
                            trailing: Chip(label: Text(valor)),
                            onTap: () => setState(() => _actividadSeleccionada = item),
                          );
                        },
                      ),
                    ),
                    if (_actividadSeleccionada != null && _tipoActividad == 'demerito' && (hay10mo || hayOtros)) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text('Valores por grado', style: TextStyle(fontWeight: FontWeight.bold)),
                            if (hay10mo) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('10mo Grado:'),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => setState(() => _rango10mo = _rango10mo > 1 ? _rango10mo - 1 : 1),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('$_rango10mo', style: const TextStyle(fontSize: 18)),
                                  IconButton(
                                    onPressed: () => setState(() => _rango10mo = _rango10mo < 3 ? _rango10mo + 1 : 3),
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                            if (hayOtros) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('11no/12mo Grado:'),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () => setState(() => _rango11_12 = _rango11_12 > 1 ? _rango11_12 - 1 : 1),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('$_rango11_12', style: const TextStyle(fontSize: 18)),
                                  IconButton(
                                    onPressed: () => setState(() => _rango11_12 = _rango11_12 < 3 ? _rango11_12 + 1 : 3),
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (_actividadSeleccionada != null) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _actividades.add({
                              'nombre': _tipoActividad == 'merito' ? _actividadSeleccionada!['causa'] : _actividadSeleccionada!['falta'],
                              'cantidad': _calcularCantidad(),
                              'tipo': _tipoActividad,
                              'categoria': _actividadSeleccionada!['categoria'],
                            });
                            _actividadSeleccionada = null;
                          });
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Agregar actividad'),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quién notifica', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_nombreNotificador, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(_cargoNotificador),
                        if (_usandoCuentaTemporal)
                          const Chip(
                            label: Text('Temporal'),
                            backgroundColor: Colors.orange,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _mostrarTemporalForm = !_mostrarTemporalForm),
                    child: const Text('Cambiar'),
                  ),
                ],
              ),
              if (_mostrarTemporalForm) ...[
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  controller: _tempNombreController,
                  decoration: const InputDecoration(labelText: 'Nombre y Apellidos'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tempPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _verificarTemporal,
                        child: const Text('Verificar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<List>(
                            context,
                            MaterialPageRoute(builder: (_) => const EscanerScreen()),
                          );
                          if (result != null && result.isNotEmpty) {
                            final datos = result.first;
                            setState(() {
                              _usandoCuentaTemporal = true;
                              _nombreNotificador = '${datos['nombre']} ${datos['apellidos']}';
                              _cargoNotificador = datos['cargo'] ?? 'estudiante';
                              _mostrarTemporalForm = false;
                            });
                          }
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Escanear QR'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const Text('Fecha y Hora', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fechaController,
                      decoration: const InputDecoration(labelText: 'Fecha'),
                      readOnly: true,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) {
                          _fechaController.text = date.toString().split(' ')[0];
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _horaController,
                      decoration: const InputDecoration(labelText: 'Hora'),
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          _horaController.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Observaciones', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: _observacionesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Notas adicionales...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool puedeEnviar) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: puedeEnviar && !_enviando ? _enviarNotificacion : null,
          icon: _enviando
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(_enviando ? 'Enviando...' : 'Enviar Notificación'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
