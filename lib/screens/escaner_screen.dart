// lib/screens/escaner_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class EscanerScreen extends StatefulWidget {
  const EscanerScreen({super.key});

  @override
  State<EscanerScreen> createState() => _EscanerScreenState();
}

class _EscanerScreenState extends State<EscanerScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  List<Map<String, dynamic>> _escaneados = [];
  bool _procesando = false;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
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
    
    Future.delayed(const Duration(seconds: 1), () {
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, _escaneados),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text('${_escaneados.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
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
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF10B981), width: 3),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  children: [
                    _buildCorner(Icons.crop_square, 20, Alignment.topLeft),
                    _buildCorner(Icons.crop_square, 20, Alignment.topRight),
                    _buildCorner(Icons.crop_square, 20, Alignment.bottomLeft),
                    _buildCorner(Icons.crop_square, 20, Alignment.bottomRight),
                    AnimatedBuilder(
                      animation: _scanAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left: 0,
                          right: 0,
                          top: _scanAnimation.value * 280,
                          child: Container(
                            height: 2,
                            color: const Color(0xFF10B981),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              height: 2,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Coloca el QR dentro del recuadro',
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          if (_procesando)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF10B981)),
                    SizedBox(height: 16),
                    Text('Procesando...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          if (_escaneados.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text('Escaneados (${_escaneados.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _escaneados.length,
                        itemBuilder: (context, index) {
                          final e = _escaneados[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: const Color(0xFF1E3C72),
                                  child: Text(e['nombre'][0], style: const TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e['nombre'], style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text('CI: ${e['ci']} | Grado: ${e['grado']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red),
                                  onPressed: () => setState(() => _escaneados.removeAt(index)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, _escaneados),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Finalizar y Continuar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCorner(IconData icon, double size, Alignment alignment) {
    return Positioned(
      left: alignment.x == -1 ? -3 : null,
      right: alignment.x == 1 ? -3 : null,
      top: alignment.y == -1 ? -3 : null,
      bottom: alignment.y == 1 ? -3 : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF10B981), width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: const Color(0xFF10B981), size: 14),
      ),
    );
  }
}
