import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';

/// Respuesta de la RPC `settings_overview` (016_settings.sql).
class SettingsOverviewModel {
  const SettingsOverviewModel(this._json);

  factory SettingsOverviewModel.fromJson(Map<String, dynamic> json) =>
      SettingsOverviewModel(json);

  final Map<String, dynamic> _json;

  SettingsOverview toEntity() {
    int intOr(String key, int fallback) =>
        (_json[key] as num?)?.toInt() ?? fallback;
    return SettingsOverview(
      level: intOr('level', 1),
      currentXp: intOr('current_xp', 0),
      xpToNextLevel: intOr('xp_to_next_level', 100),
      settings: GameSettings(
        difficulty: _level(_json['difficulty']) ?? GameDifficulty.normal,
        notificationDailyLimit: (_json['notification_daily_limit'] as num?)
            ?.toInt(),
        silenceStart: _json['silence_window_start'] as String?,
        silenceEnd: _json['silence_window_end'] as String?,
        criticalBypassSilence:
            _json['critical_bypass_silence'] as bool? ?? false,
        shortBreakMinutes: intOr('short_break_minutes', 5),
        longBreakMinutes: intOr('long_break_minutes', 15),
        longBreakEveryNCycles: intOr('long_break_every_n_cycles', 4),
      ),
      difficulties: [
        for (final d
            in (_json['difficulties'] as List? ?? const [])
                .cast<Map<String, dynamic>>())
          if (_level(d['level']) case final level?)
            DifficultyOption(
              level: level,
              xpMultiplier: (d['xp_multiplier'] as num).toDouble(),
              hpPenaltyMultiplier: (d['hp_penalty_multiplier'] as num)
                  .toDouble(),
              coinMultiplier: (d['coin_multiplier'] as num).toDouble(),
            ),
      ],
    );
  }

  /// Columnas de `game_master_settings` que el jugador puede escribir (003, 007).
  static Map<String, Object?> toRow(GameSettings settings) => {
    'difficulty': settings.difficulty.name,
    'notification_daily_limit': settings.notificationDailyLimit,
    'silence_window_start': settings.silenceStart,
    'silence_window_end': settings.silenceEnd,
    'critical_bypass_silence': settings.criticalBypassSilence,
    'short_break_minutes': settings.shortBreakMinutes,
    'long_break_minutes': settings.longBreakMinutes,
    'long_break_every_n_cycles': settings.longBreakEveryNCycles,
  };

  static GameDifficulty? _level(Object? name) =>
      GameDifficulty.values.where((d) => d.name == name).firstOrNull;
}
