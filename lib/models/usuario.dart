// lib/models/usuario.dart
class Usuario {
  final int id;
  final String nombre;
  final String apellidos;
  final String ci;
  final String cargo;
  final String? ocupacion;
  final String? grado;
  final int? peloton;
  final int activo;

  Usuario({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.ci,
    required this.cargo,
    this.ocupacion,
    this.grado,
    this.peloton,
    this.activo = 1,
  });

  String get nombreCompleto => '$nombre $apellidos';
  String get idFormateado => '${cargo}_$id';

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      apellidos: json['apellidos'] as String? ?? '',
      ci: json['ci'] as String? ?? '',
      cargo: json['cargo'] as String? ?? 'estudiante',
      ocupacion: json['ocupacion'] as String?,
      grado: json['grado'] as String?,
      peloton: json['peloton'] as int?,
      activo: json['activo'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellidos': apellidos,
      'ci': ci,
      'cargo': cargo,
      'ocupacion': ocupacion,
      'grado': grado,
      'peloton': peloton,
      'activo': activo,
    };
  }
}
