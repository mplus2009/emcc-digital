// lib/config/app_strings.dart
class AppStrings {
  // App general
  static const String appName = 'EMCC Digital';
  static const String loading = 'Cargando...';
  static const String error = 'Error';
  static const String retry = 'Reintentar';
  static const String save = 'Guardar';
  static const String cancel = 'Cancelar';
  static const String confirm = 'Confirmar';
  static const String delete = 'Eliminar';
  static const String edit = 'Editar';
  static const String add = 'Agregar';
  static const String search = 'Buscar';
  static const String back = 'Volver';
  static const String close = 'Cerrar';
  static const String download = 'Descargar';
  static const String success = 'Éxito';
  static const String updated = 'Actualizado';
  static const String noData = 'No hay datos disponibles';

  // Login
  static const String login = 'Acceso';
  static const String loginSubtitle = 'Inicia sesión en el sistema';
  static const String scanQR = 'Escanear QR';
  static const String manualLogin = 'o ingresa manualmente';
  static const String nameLabel = 'Nombre';
  static const String nameHint = 'Ingresa tu nombre';
  static const String lastNameLabel = 'Apellidos';
  static const String lastNameHint = 'Ingresa tus apellidos';
  static const String passwordLabel = 'Contraseña';
  static const String passwordHint = 'Ingresa tu contraseña';
  static const String roleLabel = 'Cargo';
  static const String roleHint = 'Selecciona tu cargo';
  static const String loginButton = 'Iniciar Sesión';
  static const String loginFooter = 'Ingresa con tus credenciales';
  static const String loginError = 'Error al iniciar sesión';
  static const String qrInvalid = 'QR no válido';
  static const String sessionExpired = 'Sesión expirada';

  // Dashboard
  static const String welcome = 'Bienvenido';
  static const String dashboardPanel = 'Panel de control';
  static const String thisWeek = 'Esta Semana';
  static const String noActivities = 'Sin actividades esta semana';
  static const String searchStudent = 'Buscar Estudiante';
  static const String searchHint = 'Nombre, apellidos o CI...';
  static const String noResults = 'No se encontraron estudiantes';
  static const String merits = 'Méritos';
  static const String demerits = 'Deméritos';
  static const String balance = 'Balance';
  static const String alarmActive = 'ALARMA ACTIVADA';
  static const String alarmMessage = 'Has alcanzado el límite de deméritos.';
  
  // Perfil
  static const String myProfile = 'Mi Perfil';
  static const String noRecentActivities = 'No hay actividades recientes';
  static const String meritsTotal = 'Méritos Totales';
  static const String demeritsTotal = 'Deméritos Totales';
  static const String excellent = '¡Excelente!';
  static const String excellentMsg = 'Tienes más méritos que deméritos';
  static const String attention = 'Atención';
  static const String attentionMsg = 'Tienes más deméritos que méritos';
  static const String balanced = 'Equilibrado';
  static const String balancedMsg = 'Méritos y deméritos equilibrados';

  // Notificaciones
  static const String notifyActivity = 'Notificar Actividad';
  static const String recipients = 'Destinatarios';
  static const String noRecipients = 'Sin destinatarios';
  static const String activities = 'Actividades';
  static const String noActivitiesAdded = 'Sin actividades';
  static const String merit = 'Mérito';
  static const String demerit = 'Demérito';
  static const String category = 'Categoría';
  static const String allCategories = 'Todas';
  static const String value = 'Valor';
  static const String dateTime = 'Fecha y Hora';
  static const String date = 'Fecha';
  static const String time = 'Hora';
  static const String observations = 'Observaciones';
  static const String send = 'Enviar';
  static const String sending = 'Enviando...';
  static const String notificationSent = 'Notificación enviada';

  // Roles
  static const List<Map<String, String>> roles = [
    {'value': 'directiva', 'label': 'Directiva'},
    {'value': 'oficial', 'label': 'Oficial'},
    {'value': 'profesor', 'label': 'Profesor'},
    {'value': 'estudiante', 'label': 'Estudiante'},
  ];

  // Estados de red
  static const String networkOffline = 'Sin red';
  static const String networkSearching = 'Buscando...';
  static const String networkConnected = 'Conectado';
  static const String networkSyncing = 'Sincronizando...';
  
  // Horario
  static const String schedule = 'Horario';
  static const String mySchedule = 'Mi Horario';
  static const String editSchedule = 'Editar Horario';
  static const String turn = 'Turno';
  static const String subject = 'Asignatura';
  static const String grade = 'Grado';
  static const String platoon = 'Pelotón';
  
  // Configuración
  static const String configuration = 'Configuración';
  static const String changePassword = 'Cambiar Contraseña';
  static const String currentPassword = 'Contraseña Actual';
  static const String newPassword = 'Nueva Contraseña';
  static const String confirmPassword = 'Confirmar Contraseña';
  
  // Panel Secretaria
  static const String secretaryPanel = 'Panel Secretaria';
  static const String addStudent = 'Ingresar Estudiante';
  static const String deactivate = 'Dar baja';
  static const String reactivate = 'Reactivar';
  
  // Cambio de cargos
  static const String changeRoles = 'Cambiar Cargos';
  static const String changeCommand = 'Cambio de Mando';
  static const String editRules = 'Editar Reglas';
  
  // Errores
  static const String fillName = 'Ingresa tu nombre';
  static const String fillLastName = 'Ingresa tus apellidos';
  static const String fillPassword = 'Ingresa tu contraseña';
  static const String fillRole = 'Selecciona tu cargo';
  static const String userNotFound = 'Usuario no encontrado';
  static const String wrongPassword = 'Contraseña incorrecta';
  static const String passwordsDoNotMatch = 'Las contraseñas no coinciden';
}
