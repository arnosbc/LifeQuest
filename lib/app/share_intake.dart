import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Texto o enlaces compartidos desde otra app («Compartir → Questly»).
/// [onText] se llama con lo recibido; App decide cuándo abrir «Anotar».
class ShareIntake {
  ShareIntake(this.onText);

  final void Function(String text) onText;
  StreamSubscription<List<SharedMediaFile>>? _sub;

  void start() {
    try {
      // Con la app abierta.
      _sub = ReceiveSharingIntent.instance.getMediaStream().listen(
        _handle,
        onError: (_) {},
      );
      // La app se abrió compartiendo.
      ReceiveSharingIntent.instance
          .getInitialMedia()
          .then((files) {
            _handle(files);
            ReceiveSharingIntent.instance.reset();
          })
          .catchError((_) {});
    } on Exception {
      // Sin plugin (tests, plataformas sin compartir).
    }
  }

  void _handle(List<SharedMediaFile> files) {
    final text = [
      for (final f in files)
        if (f.type == SharedMediaType.text || f.type == SharedMediaType.url)
          f.path.trim(),
    ].where((t) => t.isNotEmpty).join('\n');
    if (text.isNotEmpty) {
      onText(text.length > 500 ? text.substring(0, 500) : text);
    }
  }

  void dispose() => _sub?.cancel();
}
