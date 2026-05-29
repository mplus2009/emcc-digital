// lib/widgets/mesh_status_indicator.dart
import 'package:flutter/material.dart';
import '../services/mesh_service.dart';

class MeshStatusIndicator extends StatefulWidget {
  const MeshStatusIndicator({super.key});
  
  @override
  State<MeshStatusIndicator> createState() => _MeshStatusIndicatorState();
}

class _MeshStatusIndicatorState extends State<MeshStatusIndicator> {
  String _status = "Sin red";
  IconData _icon = Icons.wifi_off;
  Color _color = Colors.red;
  int _peersCount = 0;

  @override
  void initState() {
    super.initState();
    _actualizarEstado();
  }

  void _actualizarEstado() {
    MeshService.addListener(() {
      if (mounted) {
        setState(() {
          _peersCount = MeshService.peersCount;
          if (_peersCount > 0) {
            _status = "$_peersCount disp.";
            _icon = Icons.wifi;
            _color = Colors.green;
          } else if (MeshService.isScanning) {
            _status = "Buscando...";
            _icon = Icons.search;
            _color = Colors.orange;
          } else {
            _status = "Sin red";
            _icon = Icons.wifi_off;
            _color = Colors.red;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarDialogo(context),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 18, color: _color),
            const SizedBox(width: 4),
            Text(_status, style: TextStyle(fontSize: 11, color: _color)),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Red Mesh P2P"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Estado: $_status"),
            const SizedBox(height: 8),
            const Text("Dispositivos conectados:"),
            const SizedBox(height: 8),
            ...MeshService.peersList.map((p) => Text("• $p")),
            if (MeshService.peersList.isEmpty)
              const Text("Ninguno", style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }
}
