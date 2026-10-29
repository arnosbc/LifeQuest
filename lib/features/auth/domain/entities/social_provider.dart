/// Cuentas externas con las que se puede entrar (botones del login).
enum SocialProvider {
  google('Google'),
  apple('Apple');

  const SocialProvider(this.label);

  /// Nombre para los mensajes de la interfaz.
  final String label;
}
