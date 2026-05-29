// lib/models/actividad.dart
import 'package:flutter/material.dart';

class Actividad {
  final int? id;
  final String idStar;
  final String idEnd;
  final String tipo;
  final String categoria;
  final String faltaCausa;
  final int cantidad;
  final String fecha;
  final String hora;
  final int leido;
  final String? notificador;
  final String? alegacion;
  final String? observaciones;

  Actividad({
    this.id,
    required this.idStar,
    required this.idEnd,
    required this.tipo,
    required this.categoria,
    required this.faltaCausa,
    required this.cantidad,
    required this.fecha,
    required this.hora,
    this.leido = 0,
    this.notificador,
    this.alegacion,
    this.observaciones,
  });

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: json['id'] as int?,
      idStar: json['id_star'] as String? ?? '',
      idEnd: json['id_end'] as String? ?? '',
      tipo: json['tipo'] as String? ?? '',
      categoria: json['categoria'] as String? ?? '',
      faltaCausa: json['falta_causa'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 0,
      fecha: json['fecha'] as String? ?? '',
      hora: json['hora'] as String? ?? '',
      leido: json['leido'] as int? ?? 0,
      notificador: json['notificador'] as String?,
      alegacion: json['alegacion'] as String?,
      observaciones: json['observaciones'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'id_star': idStar,
    'id_end': idEnd,
    'tipo': tipo,
    'categoria': categoria,
    'falta_causa': faltaCausa,
    'cantidad': cantidad,
    'fecha': fecha,
    'hora': hora,
    'leido': leido,
    if (notificador != null) 'notificador': notificador,
    if (alegacion != null) 'alegacion': alegacion,
    if (observaciones != null) 'observaciones': observaciones,
  };

  bool get esMerito => tipo == 'merito';
  bool get esDemerito => tipo == 'demerito';
  String get valor => esMerito ? '+$cantidad' : '-$cantidad';
  
  Color get color => esMerito ? const Color(0xFF10B981) : const Color(0xFFEF4444);
  Color get backgroundColor => esMerito ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2);
}
