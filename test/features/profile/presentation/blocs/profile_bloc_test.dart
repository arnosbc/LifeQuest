import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/rename_skill.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/update_identity.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';

import '../../../../helpers/mocks.dart';
import '../../profile_fixtures.dart';

void main() {
  late MockGetCharacterProfile getProfile;
  late MockUpdateIdentity updateIdentity;
  late MockCreateSkill createSkill;
  late MockRenameSkill renameSkill;
  late MockDeleteSkill deleteSkill;
  late MockSetActiveTitle setActiveTitle;
  const failure = ServerFailure('Algo salió mal.');

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const UpdateIdentityParams(displayName: 'x'));
    registerFallbackValue(const RenameSkillParams(skillId: 'x', name: 'x'));
  });

  setUp(() {
    getProfile = MockGetCharacterProfile();
    updateIdentity = MockUpdateIdentity();
    createSkill = MockCreateSkill();
    renameSkill = MockRenameSkill();
    deleteSkill = MockDeleteSkill();
    setActiveTitle = MockSetActiveTitle();
  });

  ProfileBloc build() => ProfileBloc(
    getCharacterProfile: getProfile,
    updateIdentity: updateIdentity,
    createSkill: createSkill,
    renameSkill: renameSkill,
    deleteSkill: deleteSkill,
    setActiveTitle: setActiveTitle,
  );

  void givenProfile(Either<Failure, CharacterProfile> result) =>
      when(() => getProfile(any())).thenAnswer((_) async => result);

  group('ProfileRequested', () {
    blocTest<ProfileBloc, ProfileState>(
      'la primera carga pasa por Loading y termina en Success',
      setUp: () => givenProfile(const Right(profile)),
      build: build,
      act: (bloc) => bloc.add(const ProfileRequested()),
      expect: () => [const ProfileLoading(), const ProfileSuccess(profile)],
    );

    blocTest<ProfileBloc, ProfileState>(
      'si la primera carga falla, muestra el error',
      setUp: () => givenProfile(const Left(failure)),
      build: build,
      act: (bloc) => bloc.add(const ProfileRequested()),
      expect: () => [const ProfileLoading(), ProfileFailure(failure.message)],
    );
  });

  group('cambios', () {
    blocTest<ProfileBloc, ProfileState>(
      'guardar la identidad relee el perfil y lo confirma',
      setUp: () {
        when(
          () => updateIdentity(any()),
        ).thenAnswer((_) async => const Right(unit));
        givenProfile(const Right(profile));
      },
      build: build,
      seed: () => const ProfileSuccess(newProfile),
      act: (bloc) => bloc.add(
        const ProfileIdentitySaved(displayName: 'Ana', identityStatement: 'Yo'),
      ),
      expect: () => [
        const ProfileSuccess(newProfile, saving: true),
        const ProfileSuccess(profile, message: 'Identidad guardada.'),
      ],
      verify: (_) => verify(
        () => updateIdentity(
          const UpdateIdentityParams(
            displayName: 'Ana',
            identityStatement: 'Yo',
          ),
        ),
      ).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'crear una skill confirma con su nombre',
      setUp: () {
        when(
          () => createSkill(any()),
        ).thenAnswer((_) async => const Right(unit));
        givenProfile(const Right(profile));
      },
      build: build,
      seed: () => const ProfileSuccess(newProfile),
      act: (bloc) => bloc.add(const ProfileSkillCreated('  Salud ')),
      expect: () => [
        const ProfileSuccess(newProfile, saving: true),
        const ProfileSuccess(profile, message: 'Skill «Salud» creada.'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'si el servidor rechaza el cambio, avisa y conserva el perfil',
      setUp: () => when(
        () => deleteSkill(any()),
      ).thenAnswer((_) async => const Left(failure)),
      build: build,
      seed: () => const ProfileSuccess(profile),
      act: (bloc) => bloc.add(const ProfileSkillDeleted('s1')),
      expect: () => [
        const ProfileSuccess(profile, saving: true),
        ProfileSuccess(profile, message: failure.message),
      ],
      verify: (_) => verifyNever(() => getProfile(any())),
    );

    blocTest<ProfileBloc, ProfileState>(
      'renombrar llama al caso de uso con el id y el nombre',
      setUp: () {
        when(
          () => renameSkill(any()),
        ).thenAnswer((_) async => const Right(unit));
        givenProfile(const Right(profile));
      },
      build: build,
      seed: () => const ProfileSuccess(profile),
      act: (bloc) =>
          bloc.add(const ProfileSkillRenamed(skillId: 's1', name: 'Inglés C1')),
      verify: (_) => verify(
        () => renameSkill(
          const RenameSkillParams(skillId: 's1', name: 'Inglés C1'),
        ),
      ).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'elegir un título lo confirma con su nombre',
      setUp: () {
        when(
          () => setActiveTitle('t2'),
        ).thenAnswer((_) async => const Right(unit));
        givenProfile(const Right(profile));
      },
      build: build,
      seed: () => const ProfileSuccess(profile),
      act: (bloc) => bloc.add(const ProfileActiveTitleChanged('t2')),
      expect: () => [
        const ProfileSuccess(profile, saving: true),
        const ProfileSuccess(profile, message: 'Ahora luces «Explorador».'),
      ],
      verify: (_) => verify(() => setActiveTitle('t2')).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'quitar el título lo confirma',
      setUp: () {
        when(
          () => setActiveTitle(null),
        ).thenAnswer((_) async => const Right(unit));
        givenProfile(const Right(profile));
      },
      build: build,
      seed: () => const ProfileSuccess(profile),
      act: (bloc) => bloc.add(const ProfileActiveTitleChanged(null)),
      expect: () => [
        const ProfileSuccess(profile, saving: true),
        const ProfileSuccess(profile, message: 'Ya no muestras ningún título.'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'si el título se rechaza, conserva el anterior',
      setUp: () => when(
        () => setActiveTitle(any()),
      ).thenAnswer((_) async => const Left(failure)),
      build: build,
      seed: () => const ProfileSuccess(profile),
      act: (bloc) => bloc.add(const ProfileActiveTitleChanged('t9')),
      expect: () => [
        const ProfileSuccess(profile, saving: true),
        ProfileSuccess(profile, message: failure.message),
      ],
      verify: (_) => verifyNever(() => getProfile(any())),
    );

    blocTest<ProfileBloc, ProfileState>(
      'sin perfil cargado no hace nada',
      build: build,
      act: (bloc) => bloc.add(const ProfileSkillCreated('Salud')),
      expect: () => <ProfileState>[],
    );
  });
}
