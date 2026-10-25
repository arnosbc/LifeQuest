import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';

/// Respuesta JSON de la RPC `profile_overview`
/// (supabase/migrations/002_profile.sql, ampliada en 009_profile_titles.sql).
class CharacterProfileModel {
  const CharacterProfileModel(this.json);

  factory CharacterProfileModel.fromJson(Map<String, dynamic> json) =>
      CharacterProfileModel(json);

  final Map<String, dynamic> json;

  CharacterProfile toEntity() {
    final skills = (json['skills'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final titles = (json['titles'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return CharacterProfile(
      displayName: _text(json['display_name']),
      characterClass: _text(json['character_class']),
      identityStatement: _text(json['identity_statement']),
      // Sin fila en character_stats: los valores por defecto del esquema.
      level: _int(json['level'], 1),
      currentXp: _int(json['current_xp']),
      xpToNextLevel: _int(json['xp_to_next_level'], 100),
      coins: _int(json['coins']),
      treasury: _int(json['treasury']),
      hpCurrent: _int(json['hp_current'], 100),
      hpMax: _int(json['hp_max'], 100),
      isWeakened: json['is_weakened'] as bool? ?? false,
      questsCompleted: _int(json['quests_completed']),
      questsFailed: _int(json['quests_failed']),
      skillLimit: _int(json['skill_limit'], 6),
      skills: [
        for (final skill in skills)
          Skill(
            id: skill['id'] as String,
            name: skill['name'] as String,
            level: _int(skill['level'], 1),
            currentXp: _int(skill['current_xp']),
            xpToNextLevel: _int(skill['xp_to_next_level'], 100),
          ),
      ],
      activeTitle: _title(json['active_title'] as Map<String, dynamic>?),
      earnedTitles: [for (final title in titles) ?_title(title)],
    );
  }

  static PrestigeTitle? _title(Map<String, dynamic>? json) {
    final id = json?['id'];
    final name = _text(json?['name']);
    if (id is! String || name == null) return null;
    return PrestigeTitle(
      id: id,
      name: name,
      description: _text(json!['description']),
    );
  }

  static int _int(Object? value, [int fallback = 0]) =>
      (value as num?)?.toInt() ?? fallback;

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}
