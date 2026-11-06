import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:proyecto_movil/features/assistant/domain/repositories/voice_input.dart';

/// [VoiceInput] con el reconocimiento de voz del sistema (speech_to_text).
/// Usa el idioma del teléfono; el permiso de micrófono se pide la primera vez.
class SpeechVoiceInput implements VoiceInput {
  SpeechVoiceInput({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  /// Los callbacks de speech_to_text se fijan una sola vez al inicializar:
  /// apuntan siempre a la escucha en curso.
  StreamController<String>? _current;

  static const _unavailable =
      'No pude usar el micrófono. Revisa el permiso o escribe la tarea.';

  @override
  Stream<String> listen() {
    _current?.close();
    final controller = _current = StreamController<String>();
    unawaited(_start(controller));
    return controller.stream;
  }

  Future<void> _start(StreamController<String> controller) async {
    final ready = await _speech.initialize(
      onError: (_) => _fail(),
      onStatus: (status) {
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _current?.close();
        }
      },
    );
    if (!ready) return _fail();
    await _speech.listen(
      onResult: (SpeechRecognitionResult r) {
        if (controller.isClosed) return;
        controller.add(r.recognizedWords);
        if (r.finalResult) controller.close();
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  void _fail() {
    final c = _current;
    if (c == null || c.isClosed) return;
    c.addError(_unavailable);
    c.close();
  }

  @override
  Future<void> stop() => _speech.stop();
}
