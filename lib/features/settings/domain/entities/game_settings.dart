import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/core/entities/difficulty.dart';

export 'package:proyecto_movil/core/entities/difficulty.dart';

/// Reglas que el propio jugador define (Game Master, `game_master_settings`).
class GameSettings extends Equatable {
  const GameSettings({
    this.difficulty = GameDifficulty.normal,
    this.notificationDailyLimit,
    this.silenceStart,
    this.silenceEnd,
    this.criticalBypassSilence = false,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.longBreakEveryNCycles = 4,
  });

  // Mismos rangos que los checks de 016_settings.sql.
  static const dailyLimitRange = (min: 1, max: 50);
  static const shortBreakRange = (min: 1, max: 30);
  static const longBreakRange = (min: 5, max: 60);
  static const longBreakEveryRange = (min: 2, max: 8);

  final GameDifficulty difficulty;

  /// Máximo de avisos al día; null = sin límite (por defecto).
  final int? notificationDailyLimit;

  /// Ventana de silencio en `HH:mm`; ambas null = sin ventana.
  final String? silenceStart;
  final String? silenceEnd;

  /// Los avisos críticos saltan la ventana de silencio.
  final bool criticalBypassSilence;

  /// RF-067: descansos de la Mazmorra.
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int longBreakEveryNCycles;

  bool get isValid {
    bool within(int value, ({int min, int max}) range) =>
        value >= range.min && value <= range.max;
    final limit = notificationDailyLimit;
    return (limit == null || within(limit, dailyLimitRange)) &&
        (silenceStart == null) == (silenceEnd == null) &&
        within(shortBreakMinutes, shortBreakRange) &&
        within(longBreakMinutes, longBreakRange) &&
        within(longBreakEveryNCycles, longBreakEveryRange);
  }

  GameSettings withDifficulty(GameDifficulty value) => GameSettings(
    difficulty: value,
    notificationDailyLimit: notificationDailyLimit,
    silenceStart: silenceStart,
    silenceEnd: silenceEnd,
    criticalBypassSilence: criticalBypassSilence,
    shortBreakMinutes: shortBreakMinutes,
    longBreakMinutes: longBreakMinutes,
    longBreakEveryNCycles: longBreakEveryNCycles,
  );

  GameSettings withNotifications({
    required int? dailyLimit,
    required String? silenceStart,
    required String? silenceEnd,
    required bool criticalBypassSilence,
  }) => GameSettings(
    difficulty: difficulty,
    notificationDailyLimit: dailyLimit,
    silenceStart: silenceStart,
    silenceEnd: silenceEnd,
    criticalBypassSilence: criticalBypassSilence,
    shortBreakMinutes: shortBreakMinutes,
    longBreakMinutes: longBreakMinutes,
    longBreakEveryNCycles: longBreakEveryNCycles,
  );

  GameSettings withBreaks({
    required int shortMinutes,
    required int longMinutes,
    required int longEveryNCycles,
  }) => GameSettings(
    difficulty: difficulty,
    notificationDailyLimit: notificationDailyLimit,
    silenceStart: silenceStart,
    silenceEnd: silenceEnd,
    criticalBypassSilence: criticalBypassSilence,
    shortBreakMinutes: shortMinutes,
    longBreakMinutes: longMinutes,
    longBreakEveryNCycles: longEveryNCycles,
  );

  @override
  List<Object?> get props => [
    difficulty,
    notificationDailyLimit,
    silenceStart,
    silenceEnd,
    criticalBypassSilence,
    shortBreakMinutes,
    longBreakMinutes,
    longBreakEveryNCycles,
  ];
}

/// Lo que muestra Configuración: progreso del personaje, reglas y las
/// dificultades con su efecto.
class SettingsOverview extends Equatable {
  const SettingsOverview({
    required this.level,
    required this.currentXp,
    required this.xpToNextLevel,
    required this.settings,
    required this.difficulties,
  });

  final int level;
  final int currentXp;
  final int xpToNextLevel;
  final GameSettings settings;
  final List<DifficultyOption> difficulties;

  SettingsOverview withSettings(GameSettings value) => SettingsOverview(
    level: level,
    currentXp: currentXp,
    xpToNextLevel: xpToNextLevel,
    settings: value,
    difficulties: difficulties,
  );

  @override
  List<Object?> get props => [
    level,
    currentXp,
    xpToNextLevel,
    settings,
    difficulties,
  ];
}
