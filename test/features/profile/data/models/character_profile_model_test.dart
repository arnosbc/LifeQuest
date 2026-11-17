import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/profile/data/models/character_profile_model.dart';

import '../../profile_fixtures.dart';

void main() {
  test('convierte el JSON de la RPC en la entidad', () {
    expect(CharacterProfileModel.fromJson(profileJson).toEntity(), profile);
  });

  test('un perfil sin datos usa los valores por defecto', () {
    final entity = CharacterProfileModel.fromJson(const {
      'display_name': ' ',
      'identity_statement': '',
      'skills': null,
    }).toEntity();

    expect(entity, newProfile);
    expect(entity.treasury, 0);
    expect(entity.activeTitle, isNull);
    expect(entity.earnedTitles, isEmpty);
  });

  test('lee la racha y los días del mes de activity_month (059)', () {
    final entity = CharacterProfileModel.fromJson(const {
      'activity': {
        'streak': 3,
        'days': {'13': 1, '14': 2, 'x': 9},
      },
    }).toEntity();

    expect(entity.activityStreak, 3);
    expect(entity.activityHeat, {13: 1, 14: 2});
  });

  test('vitrina: 3 logros más recientes y el conteo', () {
    final entity = CharacterProfileModel.fromJson(const {
      'achievements': [
        {'name': 'Buen hábito', 'unlocked_at': '2026-11-15T10:00:00Z'},
        {'name': 'Primer paso', 'unlocked_at': '2026-11-14T10:00:00Z'},
        {'name': 'Racha encendida', 'unlocked_at': '2026-11-13T10:00:00Z'},
        {'name': 'Aventurero', 'unlocked_at': '2026-11-12T10:00:00Z'},
        {'name': 'Leyenda', 'unlocked_at': null},
      ],
    }).toEntity();

    expect(entity.recentAchievements, [
      'Buen hábito',
      'Primer paso',
      'Racha encendida',
    ]);
    expect((entity.achievementsUnlocked, entity.achievementsTotal), (4, 5));
  });

  test('un título sin nombre se ignora', () {
    final entity = CharacterProfileModel.fromJson(const {
      'active_title': {'id': 't1', 'name': ' '},
      'titles': [
        {'id': 't1', 'name': ''},
        {'name': 'Sin id'},
      ],
    }).toEntity();

    expect(entity.activeTitle, isNull);
    expect(entity.earnedTitles, isEmpty);
  });

  test('tasa de finalización y espacio para skills', () {
    expect(profile.completionRate, 0.76);
    expect(newProfile.completionRate, isNull);
    expect(profile.canAddSkill, isTrue);
    expect(englishSkill.progress, 0.5);
  });
}
