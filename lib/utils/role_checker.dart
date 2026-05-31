// lib/utils/role_checker.dart
import '../models/usuario.dart';

class RoleChecker {
  static const List<String> cargosEstudiantesQuePuedenNotificar = [
    'activista',
    'jefe_escuadra',
    'politico_peloton',
    '2do_jefe_peloton',
    '1er_jefe_peloton',
    'politico_compania',
    '2do_jefe_compania',
    '1er_jefe_compania',
    'sargento_mayor',
    '2do_jefe_batallon',
    'jefe_batallon',
  ];
  
  static bool puedeNotificar(Usuario? usuario) {
    if (usuario == null) return false;
    
    if (usuario.cargo == 'directiva' ||
        usuario.cargo == 'oficial' ||
        usuario.cargo == 'profesor') {
      return true;
    }
    
    if (usuario.cargo == 'estudiante') {
      final ocupacion = usuario.ocupacion ?? 'ninguno';
      return cargosEstudiantesQuePuedenNotificar.contains(ocupacion);
    }
    
    return false;
  }
  
  static List<String> getCargosEstudiantes() {
    return cargosEstudiantesQuePuedenNotificar;
  }
  
  static bool esCargoValidoParaNotificar(String cargo) {
    return cargosEstudiantesQuePuedenNotificar.contains(cargo);
  }
}
