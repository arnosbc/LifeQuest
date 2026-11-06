import 'package:proyecto_movil/features/assistant/domain/repositories/voice_input.dart';

/// Dictar una tarea. Devuelve un stream (texto parcial) en lugar de un
/// `Either`: el texto llega mientras se habla.
class ListenVoice {
  const ListenVoice(this._voice);

  final VoiceInput _voice;

  Stream<String> call() => _voice.listen();

  Future<void> stop() => _voice.stop();
}
