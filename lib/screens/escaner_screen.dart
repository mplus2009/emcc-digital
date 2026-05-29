import ../services/database_service.dart;
// lib/screens/escaner_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EscanerScreen extends StatefulWidget {
  const EscanerScreen({super.key});

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  List<Map<String, dynamic>> _escaneados = [];
  bool _procesando = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _procesarQR(String? code) {
    if (code == null || _procesando) return;
    setState(() => _procesando = true);
    
    try {
      Map<String, dynamic>? usuario = _decodificarQR(code);
      if (usuario != null && usuario['nombre'] != null) {
        final id = '${usuario['id'] ?? ''}';
        final existe = _escaneados.any((e) => e['id'] == id);
        if (!existe) {
          setState(() {
            _escaneados.add({
              'id': id,
              'nombre': '${usuario['nombre']} ${usuario['apellidos']}',
              'ci': '${usuario['ci'] ?? ''}',
              'grado': usuario['grado'] ?? '10mo',
              'cargo': usuario['cargo'] ?? 'estudiante',
            });
          });
          _showSnackBar('Estudiante escaneado!', Colors.green);
        } else {
          _showSnackBar('Ya está en la lista', Colors.orange);
        }
      } else {
        _showSnackBar('QR no válido', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error al procesar QR', Colors.red);
    }
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _procesando = false);
    });
  }

  Map<String, dynamic>? _decodificarQR(String code) {
    try {
      final data = jsonDecode(code);
      if (data is Map<String, dynamic>) {
        return {
          'id': '${data['id'] ?? ''}',
          'nombre': '${data['nombre'] ?? ''}',
          'apellidos': '${data['apellidos'] ?? ''}',
          'ci': '${data['ci'] ?? ''}',
          'grado': '${data['grado'] ?? '10mo'}',
          'cargo': '${data['cargo'] ?? 'estudiante'}',
        };
      }
    } catch (e) {}
    return null;
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Escanear QR'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_escaneados.length}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _escaneados),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final barcode = barcodes.first;
                if (barcode.rawValue != null) _procesarQR(barcode.rawValue);
              }
            },
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF10B981), width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -3,
                    left: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(topRight: Radius.circular(8)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    left: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3,
                    right: -3,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Coloca el QR dentro del recuadro',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ),
          ),
          if (_procesando)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
