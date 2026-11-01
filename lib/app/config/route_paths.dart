/// Rutas de la app. Las features navegan con estas constantes, sin importar
/// pantallas de otras features.
abstract final class RoutePaths {
  static const login = '/login';
  static const register = '/register';
  static const checkEmail = '/check-email';

  // Primer inicio de sesión, antes de Inicio.
  static const onboarding = '/onboarding';

  // Pestañas de la barra inferior: Hoy · Tareas · Hábitos · Foco · Tú.
  static const home = '/home';
  static const missions = '/tasks';
  static const habits = '/habits';
  static const dungeon = '/dungeon';
  static const profile = '/profile';

  // Dentro de la pestaña Tareas: proyectos, metas y recursos (P.A.R.A.).
  static const stage = '/tasks/projects';

  // Subpáginas de perfil (dentro de la pestaña Perfil).
  static const notifications = '/profile/notifications';
  static const help = '/profile/help';

  // Pantallas completas fuera de la barra inferior (RF-114).
  static const settings = '/settings';

  // Subpáginas de Configuración.
  static const appearance = '/settings/appearance';
  static const journal = '/journal';
  static const brainDump = '/brain-dump';

  // Desde Perfil (§13).
  static const stats = '/stats';
}
