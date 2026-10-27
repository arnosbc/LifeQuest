/// Rutas de la app. Las features navegan con estas constantes, sin importar
/// pantallas de otras features.
abstract final class RoutePaths {
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
  static const rpgenie = '/rpgenie';
  static const journal = '/journal';
  static const goals = '/goals';
  static const tavern = '/tavern';
  static const marketplace = '/marketplace';
}
