import 'dart:async';

import 'package:proyecto_movil/core/entities/reward_outcome.dart';

/// Canal de recompensas: los datasources le pasan la respuesta de `_award`
/// justo después de la RPC y el AppShell muestra el momento de recompensa.
/// Así los usecases y blocs no cambian y todas las secciones lo muestran igual.
/// También lleva los avisos de lo que el usuario acaba de crear ([notices]),
/// que se muestran como notificación del teléfono.
class RewardFeed {
  final _controller = StreamController<RewardOutcome>.broadcast();
  final _notices = StreamController<(String, String)>.broadcast();

  Stream<RewardOutcome> get stream => _controller.stream;

  /// (título, texto) de cada aviso.
  Stream<(String, String)> get notices => _notices.stream;

  void announce(String title, String body) => _notices.add((title, body));

  /// Acepta la respuesta tal cual llega de Supabase; ignora lo que no sea un
  /// objeto o no traiga nada que contar.
  void report(Object? json) {
    final outcome = parse(json);
    if (outcome != null && outcome.isVisible) _controller.add(outcome);
  }

  static RewardOutcome? parse(Object? json) {
    if (json is! Map) return null;
    int? asInt(String key) => (json[key] as num?)?.toInt();
    return RewardOutcome(
      xp: asInt('xp') ?? 0,
      coins: asInt('coins') ?? 0,
      constancyChange: asInt('hp_change') ?? 0,
      level: asInt('level'),
      levelUp: json['level_up'] == true,
      currentXp: asInt('current_xp'),
      xpToNextLevel: asInt('xp_to_next_level'),
      areaName: json['skill_name'] as String?,
      areaLevel: asInt('skill_level'),
      areaLevelUp: json['skill_level_up'] == true,
      streak: asInt('streak'),
      bestStreak: asInt('best_streak'),
    );
  }

  void dispose() {
    _controller.close();
    _notices.close();
  }
}
