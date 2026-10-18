import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/create_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/delete_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/rename_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';

import '../../../../helpers/mocks.dart';
import '../../profile_fixtures.dart';

void main() {
  late MockProfileRepository repository;
  const ok = Right<Failure, Unit>(unit);

  setUp(() => repository = MockProfileRepository());

  test('GetCharacterProfile delega en el repositorio', () async {
    when(
      () => repository.getProfile(),
    ).thenAnswer((_) async => const Right(profile));

    expect(
      await GetCharacterProfile(repository)(const NoParams()),
      const Right<Failure, CharacterProfile>(profile),
    );
  });

  test('UpdateIdentity delega en el repositorio', () async {
    when(
      () => repository.updateIdentity(
        displayName: 'Ana',
        identityStatement: 'Yo',
      ),
    ).thenAnswer((_) async => ok);

    expect(
      await UpdateIdentity(repository)(
        const UpdateIdentityParams(displayName: 'Ana', identityStatement: 'Yo'),
      ),
      ok,
    );
  });

  test(
    'CreateSkill, RenameSkill y DeleteSkill delegan en el repositorio',
    () async {
      when(() => repository.createSkill('Salud')).thenAnswer((_) async => ok);
      when(
        () => repository.renameSkill(skillId: 's1', name: 'Inglés C1'),
      ).thenAnswer((_) async => ok);
      when(() => repository.deleteSkill('s1')).thenAnswer((_) async => ok);

      expect(await CreateSkill(repository)('Salud'), ok);
      expect(
        await RenameSkill(repository)(
          const RenameSkillParams(skillId: 's1', name: 'Inglés C1'),
        ),
        ok,
      );
      expect(await DeleteSkill(repository)('s1'), ok);
    },
  );
}
