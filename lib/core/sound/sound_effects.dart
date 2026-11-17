import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sonidos cortos de la app (`assets/sounds/<nombre>.wav`).
enum Sfx {
  /// Tarea o hábito cumplido: «ding-ding».
  tarea,

  /// Cofre o desafío cobrado: arpegio de monedas.
  monedas,

  /// Subida de nivel: fanfarria.
  nivel,
}

/// Reproduce [Sfx] si el usuario no los apagó (Configuración → Apariencia).
/// Un fallo de audio nunca interrumpe la app.
class SoundEffects {
  SoundEffects([this._given]);

  static const _key = 'sounds_enabled';

  final SharedPreferencesAsync? _given;
  SharedPreferencesAsync? _lazy;

  // Perezoso: construir el servicio no toca el almacenamiento del teléfono.
  SharedPreferencesAsync get _prefs =>
      _given ?? (_lazy ??= SharedPreferencesAsync());
  final _players = <Sfx, AudioPlayer>{};
  bool _enabled = true;

  bool get enabled => _enabled;

  /// Lee la preferencia guardada; encendidos por defecto.
  Future<void> load() async {
    try {
      _enabled = await _prefs.getBool(_key) ?? true;
    } catch (_) {
      // Sin almacenamiento disponible (p. ej. en pruebas): encendidos.
      _enabled = true;
    }
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      await _prefs.setBool(_key, value);
    } catch (_) {
      // Sin almacenamiento: vale solo hasta cerrar la app.
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!_enabled) return;
    try {
      final player = _players.putIfAbsent(
        sfx,
        () => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
      );
      await player.stop();
      await player.play(AssetSource('sounds/${sfx.name}.wav'));
    } on Exception {
      // Sin audio disponible: la app sigue en silencio.
    }
  }
}
