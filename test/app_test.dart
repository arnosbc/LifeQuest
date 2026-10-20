import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/app.dart';
import 'package:proyecto_movil/features/auth/domain/entities/user.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/injection_container.dart';

import 'features/home/home_fixtures.dart';
import 'features/profile/profile_fixtures.dart';
import 'helpers/mocks.dart';

void main() {
  late MockAuthBloc authBloc;
  late MockAppearanceBloc appearanceBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    appearanceBloc = MockAppearanceBloc();
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
      App(authBloc: authBloc, appearanceBloc: appearanceBloc),
    );
    await tester.pumpAndSettle();

    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);

    await tester.tap(find.text('Crea tu perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu Héroe'), findsOneWidget);
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
      App(authBloc: authBloc, appearanceBloc: appearanceBloc),
    );
    await tester.pumpAndSettle();

    // El saludo cambia con la hora; el nombre sale del perfil.
    expect(find.textContaining(', Ana'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Taverna'), 200);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taverna'));
    await tester.pumpAndSettle();
    expect(find.text('Entrenadora Vera · Salud'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('EXPLORA EL REINO'), findsOneWidget);

    await tester.tap(find.text('Misiones').last);
    await tester.pumpAndSettle();
    expect(find.text('Preparar presentación del proyecto'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
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
      App(authBloc: authBloc, appearanceBloc: appearanceBloc),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perfil').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Configuración'));
    await tester.pumpAndSettle();
    final signOutButton = find.widgetWithText(OutlinedButton, 'Cerrar Sesión');
    await tester.ensureVisible(signOutButton);
    await tester.pumpAndSettle();
    await tester.tap(signOutButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
    await tester.pumpAndSettle();

    verify(() => authBloc.add(const LogoutRequested())).called(1);
  });
}
