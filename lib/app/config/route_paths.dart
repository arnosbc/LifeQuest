/// Rutas de la app. Las features navegan con estas constantes, sin importar
/// pantallas de otras features.
abstract final class RoutePaths {
  // Bienvenida con «Comenzar», antes del login.
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const checkEmail = '/check-email';

  // Primer inicio de sesión, antes de Inicio.
  static const onboarding = '/onboarding';

  // Pestañas de la barra inferior (§13: Inicio · Stage · Hábitos · Mazmorra · Perfil).
  static const home = '/home';
  static const stage = '/stage';
  static const habits = '/habits';
  static const dungeon = '/dungeon';
  static const profile = '/profile';

  // Dentro de la pestaña Stage.
  static const missions = '/stage/missions';

  // Subpáginas de perfil (dentro de la pestaña Perfil).
  static const notifications = '/profile/notifications';
  static const help = '/profile/help';

  // Pantallas completas fuera de la barra inferior (RF-114).
  static const settings = '/settings';

  // Subpáginas de Configuración.
  static const appearance = '/settings/appearance';
  // Galería de componentes Questly (solo en modo debug).
  static const designPreview = '/settings/diseno';
  static const rpgenie = '/rpgenie';
  static const journal = '/journal';
  static const goals = '/goals';
  static const tavern = '/tavern';
  static const marketplace = '/marketplace';
  static const brainDump = '/brain-dump';

  // Taller de documentos (046, specs/006).
  static const documents = '/documents';
  static const document = '/document';
  static String documentById(String id) => '$document?id=$id';
  static String documentForTask(String taskId, String title) => Uri(
    path: document,
    queryParameters: {'task': taskId, 'title': title},
  ).toString();

  // Desde Perfil (§13).
  static const stats = '/stats';
  static const vision = '/vision';
  static const inventory = '/inventory';

  // Tarea guiada con sus pasos (039, plan B1–B2).
  static const guidedTask = '/task/:id';
  static String task(String id) => '/task/$id';

  /// Modo Foco con la tarea ya elegida (040: las tareas se completan en Foco).
  static String focusOn(String taskId) => '$dungeon?task=$taskId';
}
