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
