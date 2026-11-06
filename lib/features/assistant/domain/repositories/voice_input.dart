/// Dictado del teléfono. La capa data lo implementa con speech_to_text.
abstract class VoiceInput {
  /// Texto reconocido mientras se habla; se cierra al terminar la frase.
  /// Emite un error con un mensaje en español si no se puede escuchar.
  Stream<String> listen();

  Future<void> stop();
}
