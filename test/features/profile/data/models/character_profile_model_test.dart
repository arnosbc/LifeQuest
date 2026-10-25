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
