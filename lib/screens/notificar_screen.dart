// lib/screens/notificar_screen.dart
import 'package:flutter/material.dart';
import 'package:emcc_digital/services/database_service.dart';
import 'escaner_screen.dart';

class NotificarScreen extends StatefulWidget {
  final Map<String, dynamic>? destinatarioPrecargado;
  const NotificarScreen({super.key, this.destinatarioPrecargado});

  @override
  State<NotificarScreen> createState() => _NotificarScreenState();
}

class _NotificarScreenState extends State<NotificarScreen> {
  List<Map<String, dynamic>> _dest = [];
  List<Map<String, dynamic>> _acts = [];
  List<Map<String, dynamic>> _catMeritos = [];
  List<Map<String, dynamic>> _catDemeritos = [];
  List<Map<String, dynamic>> _search = [];
  String _tipo = 'merito';
  bool _loading = true;
  bool _sending = false;
  final _bc = TextEditingController();
  final _fc = TextEditingController();
  final _hc = TextEditingController();
  final _obs = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  Map<String, dynamic>? _sel;
  double _s10 = 1;
  double _s11 = 1;
  String? _catFiltro;

  @override
  void initState() {
    super.initState();
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
    _fc.dispose();
    _hc.dispose();
    _obs.dispose();
    _cantidadController.dispose();
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
      appBar: AppBar(title: const Text('Notificar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Destinatarios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, children: _dest.asMap().entries.map((entry) => Chip(
                    label: Text(entry.value['nombre']),
                    onDeleted: () => setState(() => _dest.removeAt(entry.key)),
                  )).toList()),
                  TextField(controller: _bc, decoration: const InputDecoration(hintText: 'Buscar...', prefixIcon: Icon(Icons.search)),
                    onChanged: (q) async {
                      if (q.length > 1) {
                        final r = await DatabaseService.buscarEstudiantes(q);
                        if (mounted) setState(() => _search = r);
                      } else { setState(() => _search = []); }
                    },
                  ),
                  ..._search.map((e) => ListTile(
                    title: Text('${e['nombre']} ${e['apellidos']}'),
                    onTap: () {
                      _dest.add({'id': '${e['id']}', 'nombre': '${e['nombre']} ${e['apellidos']}', 'ci': '${e['CI']}', 'grado': e['grado'] ?? '10mo'});
                      setState(() { _search = []; _bc.clear(); });
                    },
                  )),
                  OutlinedButton.icon(onPressed: () async {
                    final result = await Navigator.push<List<Map<String, dynamic>>>(
                      context, MaterialPageRoute(builder: (_) => const EscanerScreen()));
                    if (result != null && mounted) setState(() => _dest.addAll(result));
                  }, icon: const Icon(Icons.qr_code), label: const Text('Escanear QR')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
              child: Column(children: [
                const Text('Actividades', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _tipo = 'merito'),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _tipo == 'merito' ? const Color(0xFF10B981) : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('Mérito', style: TextStyle(color: _tipo == 'merito' ? Colors.white : Colors.black87))),
                    ),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: GestureDetector(
                    onTap: () => setState(() => _tipo = 'demerito'),
                    child: Container(padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _tipo == 'demerito' ? const Color(0xFFEF4444) : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('Demérito', style: TextStyle(color: _tipo == 'demerito' ? Colors.white : Colors.black87))),
                    ),
                  )),
                ]),
                if (_tipo == 'merito') TextField(controller: _cantidadController, decoration: const InputDecoration(labelText: 'Valor'), keyboardType: TextInputType.number),
                DropdownButtonFormField<String>(
                  value: _catFiltro, decoration: const InputDecoration(labelText: 'Categoría'),
                  items: [const DropdownMenuItem(value: null, child: Text('Todas')), ...cats.map((c) => DropdownMenuItem(value: c, child: Text(c)))],
                  onChanged: (v) => setState(() => _catFiltro = v),
                ),
                ..._catActual.where((a) => _catFiltro == null || a['categoria'] == _catFiltro).map((a) => ListTile(
                  title: Text(_tipo == 'merito' ? a['causa'] : a['falta']),
                  subtitle: Text(_tipo == 'merito' ? '+${a['meritos']}' : '10mo: ${a['demeritos_10mo']}'),
                  trailing: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onTap: () => setState(() => _sel = a),
                )),
                if (_sel != null && _tipo == 'demerito') ...[
                  if (hay10) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(top: 10), color: Colors.amber.shade100,
                    child: Column(children: [const Text('Rango 10mo'), Slider(min: 1, max: 3, value: _s10, onChanged: (v) => setState(() => _s10 = v)), Text('${_s10.toInt()}')])),
                  if (hay11) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(top: 10), color: Colors.amber.shade100,
                    child: Column(children: [const Text('Rango 11no/12mo'), Slider(min: 1, max: 3, value: _s11, onChanged: (v) => setState(() => _s11 = v)), Text('${_s11.toInt()}')])),
                ],
                if (_sel != null) ElevatedButton(onPressed: () {
                  _acts.add({'nombre': _tipo == 'merito' ? _sel!['causa'] : _sel!['falta'], 'cantidad': _calcCantidad(), 'tipo': _tipo, 'categoria': _sel!['categoria']});
                  setState(() => _sel = null);
                }, child: const Text('Agregar')),
                ..._acts.asMap().entries.map((entry) => ListTile(
                  title: Text(entry.value['nombre']),
                  subtitle: Text('${entry.value['tipo'] == 'merito' ? '+' : '-'}${entry.value['cantidad']}'),
                  trailing: IconButton(icon: const Icon(Icons.delete), onPressed: () => setState(() => _acts.removeAt(entry.key))),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: _fc, decoration: const InputDecoration(labelText: 'Fecha'), readOnly: true, onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                if (d != null) _fc.text = d.toString().split(' ')[0];
              })),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _hc, decoration: const InputDecoration(labelText: 'Hora'), readOnly: true, onTap: () async {
                final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                if (t != null) _hc.text = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
              })),
            ]),
            const SizedBox(height: 16),
            TextField(controller: _obs, maxLines: 2, decoration: const InputDecoration(labelText: 'Observaciones')),
            const SizedBox(height: 20),
            ElevatedButton.icon(onPressed: puede && !_sending ? () async {
              setState(() => _sending = true);
              final u = DatabaseService.usuario;
              await DatabaseService.enviarNotificacion({
                'destinatarios': _dest, 'actividades': _acts, 'fecha': _fc.text, 'hora': _hc.text,
                'id_star': u?.id, 'cargo_notificador': u?.cargo, 'observaciones': _obs.text,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enviado')));
                setState(() { _dest = []; _acts = []; _sending = false; });
              }
            } : null, icon: _sending ? const CircularProgressIndicator() : const Icon(Icons.send), label: const Text('Enviar')),
          ],
        ),
      ),
    );
  }
}
