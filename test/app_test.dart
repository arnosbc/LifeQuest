import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/app.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_nav_bar.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/missions/presentation/blocs/missions_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:proyecto_movil/features/stage/presentation/blocs/stage_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/injection_container.dart';

import 'features/home/home_fixtures.dart';
import 'features/missions/missions_fixtures.dart';
import 'features/onboarding/onboarding_fixtures.dart';
import 'features/profile/profile_fixtures.dart';
import 'features/settings/settings_fixtures.dart';
import 'features/stage/stage_fixtures.dart';
import 'helpers/mocks.dart';

void main() {
  late MockAuthBloc authBloc;
  late MockAppearanceBloc appearanceBloc;
  late MockOnboardingBloc onboardingBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    appearanceBloc = MockAppearanceBloc();
    onboardingBloc = MockOnboardingBloc();
    whenListen(
      onboardingBloc,
      const Stream<OnboardingState>.empty(),
      initialState: const OnboardingNotNeeded(),
    );
    whenListen(
      appearanceBloc,
      const Stream<AppearanceState>.empty(),
      initialState: const AppearanceSuccess(ThemePreference.system),
    );
    // El Home pide su bloc a get_it; aquí, uno simulado con datos fijos.
    sl.registerFactory<HomeBloc>(() {
      final homeBloc = MockHomeBloc();
      whenListen(
        homeBloc,
        const Stream<HomeState>.empty(),
        initialState: HomeSuccess(dashboard),
      );
      return homeBloc;
    });
    sl.registerFactory<MissionsBloc>(() {
      final missionsBloc = MockMissionsBloc();
      whenListen(
        missionsBloc,
        const Stream<MissionsState>.empty(),
        initialState: const MissionsSuccess(board),
      );
      return missionsBloc;
    });
    sl.registerFactory<StageBloc>(() {
      final stageBloc = MockStageBloc();
      whenListen(
        stageBloc,
        const Stream<StageState>.empty(),
        initialState: const StageSuccess(stageBoard),
      );
      return stageBloc;
    });
    sl.registerFactory<SettingsBloc>(() {
      final settingsBloc = MockSettingsBloc();
      whenListen(
        settingsBloc,
        const Stream<SettingsState>.empty(),
        initialState: const SettingsSuccess(settingsOverview),
      );
      return settingsBloc;
    });
    sl.registerFactory<ProfileBloc>(() {
      final profileBloc = MockProfileBloc();
      whenListen(
        profileBloc,
        const Stream<ProfileState>.empty(),
        initialState: const ProfileSuccess(profile),
      );
      return profileBloc;
    });
  });

  tearDown(() => sl.reset());

  void givenAuthState(AuthState state) => whenListen(
    authBloc,
    const Stream<AuthState>.empty(),
    initialState: state,
  );

  testWidgets('sin sesión abre el login y desde ahí el registro', (
    tester,
  ) async {
    givenAuthState(const AuthUnauthenticated());
    await tester.pumpWidget(
      App(
        authBloc: authBloc,
        appearanceBloc: appearanceBloc,
        onboardingBloc: onboardingBloc,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);

    await tester.tap(find.text('Crea tu perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu cuenta'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsOneWidget);
  });

  testWidgets('con sesión abre Home y navega entre pestañas y secciones', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    givenAuthState(
      const AuthSuccess(
        User(id: 'u1', email: 'alex@example.com', username: 'Alex'),
      ),
    );
    await tester.pumpWidget(
      App(
        authBloc: authBloc,
        appearanceBloc: appearanceBloc,
        onboardingBloc: onboardingBloc,
      ),
    );
    await tester.pumpAndSettle();

    // El saludo cambia con la hora; el nombre sale del perfil.
    expect(find.textContaining(', Ana'), findsOneWidget);
    expect(find.byType(QuestlyNavBar), findsOneWidget);

    // Barra: Hoy · Tareas · Hábitos · Foco · Tú.
    Finder tab(String label) => find.descendant(
      of: find.byType(QuestlyNavBar),
      matching: find.text(label),
    );
    for (final label in ['Hoy', 'Tareas', 'Hábitos', 'Foco', 'Tú']) {
      expect(tab(label), findsOneWidget);
    }

    // Tareas es la raíz de su pestaña; Proyectos cuelga de ella.
    await tester.tap(tab('Tareas'));
    await tester.pumpAndSettle();
    expect(find.text('Preparar la exposición'), findsOneWidget);
    await tester.tap(find.text('Proyectos'));
    await tester.pumpAndSettle();
    expect(find.text('Lanzamiento de la app'), findsOneWidget);
    expect(find.textContaining('🔴 Alta'), findsOneWidget);
    expect(find.text('METAS'), findsOneWidget);
    expect(find.byType(QuestlyNavBar), findsOneWidget);

    // Tocar una pestaña abre su raíz: Tareas, no Proyectos.
    await tester.tap(tab('Hoy'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Tareas'));
    await tester.pumpAndSettle();
    expect(find.text('Preparar la exposición'), findsOneWidget);
    expect(find.text('METAS'), findsNothing);
  });

  testWidgets('al volver a una pestaña recarga sus datos', (tester) async {
    final homeBloc = MockHomeBloc();
    whenListen(
      homeBloc,
      const Stream<HomeState>.empty(),
      initialState: HomeSuccess(dashboard),
    );
    sl.unregister<HomeBloc>();
    sl.registerFactory<HomeBloc>(() => homeBloc);
    givenAuthState(
      const AuthSuccess(User(id: 'u1', email: 'alex@example.com')),
    );
    await tester.pumpWidget(
      App(
        authBloc: authBloc,
        appearanceBloc: appearanceBloc,
        onboardingBloc: onboardingBloc,
      ),
    );
    await tester.pumpAndSettle();
    verify(() => homeBloc.add(const HomeRequested())).called(1);

    Finder tab(String label) => find.descendant(
      of: find.byType(QuestlyNavBar),
      matching: find.text(label),
    );
    await tester.tap(tab('Tú'));
    await tester.pumpAndSettle();
    await tester.tap(tab('Hoy'));
    await tester.pumpAndSettle();
    verify(() => homeBloc.add(const HomeRequested())).called(1);
  });

  testWidgets('con el Onboarding pendiente lo muestra en lugar de Inicio', (
    tester,
  ) async {
    whenListen(
      onboardingBloc,
      const Stream<OnboardingState>.empty(),
      initialState: const OnboardingPending(pendingStatus),
    );
    givenAuthState(
      const AuthSuccess(User(id: 'u1', email: 'alex@example.com')),
    );
    await tester.pumpWidget(
      App(
        authBloc: authBloc,
        appearanceBloc: appearanceBloc,
        onboardingBloc: onboardingBloc,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Paso 1 de 5'), findsOneWidget);
    expect(find.byType(QuestlyNavBar), findsNothing);
    verify(() => onboardingBloc.add(const OnboardingRequested())).called(1);
  });

  testWidgets('cerrar sesión desde Ajustes envía LogoutRequested', (
    tester,
  ) async {
    registerFallbackValue(const LogoutRequested());
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    givenAuthState(
      const AuthSuccess(User(id: 'u1', email: 'alex@example.com')),
    );
    await tester.pumpWidget(
      App(
        authBloc: authBloc,
        appearanceBloc: appearanceBloc,
        onboardingBloc: onboardingBloc,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tú').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    final signOutButton = find.text('Cerrar sesión');
    await tester.scrollUntilVisible(signOutButton, 200);
    await tester.pumpAndSettle();
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    verify(() => authBloc.add(const LogoutRequested())).called(1);
  });
}
