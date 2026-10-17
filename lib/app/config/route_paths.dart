/// Rutas de la app. Las features navegan con estas constantes, sin importar
/// pantallas de otras features.
abstract final class RoutePaths {
  static const login = '/login';
  static const register = '/register';

  // Pestañas de la barra inferior.
  static const home = '/home';
  static const missions = '/missions';
  static const dungeon = '/dungeon';
  static const habits = '/habits';
  static const profile = '/profile';

  // Subpáginas de perfil (dentro de la pestaña Perfil).
  static const notifications = '/profile/notifications';
  static const help = '/profile/help';
  static const appearance = '/profile/appearance';

  // Pantallas completas fuera de la barra inferior (RF-114).
  static const settings = '/settings';
  static const rpgenie = '/rpgenie';
  static const stage = '/stage';
  static const journal = '/journal';
  static const goals = '/goals';
  static const tavern = '/tavern';
  static const marketplace = '/marketplace';
}
