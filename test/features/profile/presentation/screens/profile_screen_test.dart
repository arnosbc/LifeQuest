import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/profile_screen.dart';

import '../../../../helpers/mocks.dart';
import '../../profile_fixtures.dart';

void main() {
  late MockProfileBloc bloc;
  late MockAppearanceBloc appearanceBloc;
  late int settingsOpened;

  setUp(() {
    bloc = MockProfileBloc();
    appearanceBloc = MockAppearanceBloc();
    whenListen(
      appearanceBloc,
      const Stream<AppearanceState>.empty(),
      initialState: const AppearanceSuccess(ThemePreference.dark),
    );
    settingsOpened = 0;
  });

  Future<void> pump(
    WidgetTester tester,
    ProfileState state, {
    double textScale = 1,
    double width = 393,
  }) async {
    whenListen(bloc, const Stream<ProfileState>.empty(), initialState: state);
    tester.view.physicalSize = Size(width, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 3000),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<ProfileBloc>.value(value: bloc),
                BlocProvider<AppearanceBloc>.value(value: appearanceBloc),
              ],
              child: ProfileScreen(
                userName: 'Alex',
                onOpenNotifications: () {},
                onOpenHelp: () {},
                onOpenAppearance: () {},
                onOpenSettings: () => settingsOpened++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra identidad, vitalidad, tasa y skills', (tester) async {
    await pump(tester, const ProfileSuccess(profile));

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Nivel 24 · Estratega'), findsOneWidget);
    expect(
      find.text('Una estratega que termina lo que empieza.'),
      findsOneWidget,
    );
    expect(find.text('80 / 100'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(find.text('2.450'), findsOneWidget);
    expect(find.text('76 %'), findsOneWidget);
    expect(find.text('38 de 50 misiones cumplidas'), findsOneWidget);
    expect(find.text('Inglés'), findsOneWidget);
    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('Añadir skill'), findsOneWidget);
  });

  testWidgets('Game Master abre la configuración', (tester) async {
    await pump(tester, const ProfileSuccess(profile));

    await tester.tap(find.text('Game Master'));

    expect(settingsOpened, 1);
  });

  testWidgets('editar la identidad envía lo escrito', (tester) async {
    await pump(tester, const ProfileSuccess(newProfile));

    await tester.tap(find.text('¿Quién eres en este reino?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '¿Quién eres en este reino?'),
      'Un aprendiz constante',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        const ProfileIdentitySaved(
          displayName: 'Alex',
          identityStatement: 'Un aprendiz constante',
        ),
      ),
    ).called(1);
  });

  testWidgets('una skill sin nombre no se crea', (tester) async {
    await pump(tester, const ProfileSuccess(newProfile));

    await tester.tap(find.text('Añadir skill'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crear skill'));
    await tester.pumpAndSettle();

    expect(find.text('Ponle un nombre a tu skill.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Salud');
    await tester.tap(find.text('Crear skill'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ProfileSkillCreated('Salud'))).called(1);
  });

  testWidgets('eliminar una skill pide confirmación', (tester) async {
    await pump(tester, const ProfileSuccess(profile));

    await tester.tap(find.text('Inglés'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar skill'));
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar «Inglés»?'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ProfileSkillDeleted('s1'))).called(1);
  });

  testWidgets('si la carga falla, ofrece reintentar', (tester) async {
    await pump(tester, const ProfileFailure('Sin conexión.'));

    await tester.tap(find.text('Reintentar'));

    verify(() => bloc.add(const ProfileRequested())).called(1);
  });

  testWidgets('con escala de texto 1,3 en 360 dp no desborda', (tester) async {
    await pump(
      tester,
      const ProfileSuccess(profile),
      textScale: 1.3,
      width: 360,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Ayuda'), findsOneWidget);
  });
}
