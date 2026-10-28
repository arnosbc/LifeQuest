import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/profile/domain/entities/character_profile.dart';
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
  late int journalOpened;
  late int marketplaceOpened;
  late int otherOpened;

  setUp(() {
    bloc = MockProfileBloc();
    appearanceBloc = MockAppearanceBloc();
    whenListen(
      appearanceBloc,
      const Stream<AppearanceState>.empty(),
      initialState: const AppearanceSuccess(ThemePreference.dark),
    );
    settingsOpened = 0;
    journalOpened = 0;
    marketplaceOpened = 0;
    otherOpened = 0;
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
                onOpenJournal: () => journalOpened++,
                onOpenMarketplace: () => marketplaceOpened++,
                onOpenSettings: () => settingsOpened++,
                onOpenStats: () => otherOpened++,
                onOpenVision: () => otherOpened++,
                onOpenInventory: () => otherOpened++,
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
    expect(find.text('2.450'), findsOneWidget);
    expect(find.text('76 %'), findsOneWidget);
    expect(find.text('38 de 50 misiones cumplidas'), findsOneWidget);
    expect(find.text('Inglés'), findsOneWidget);
    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('Añadir skill'), findsOneWidget);
  });

  testWidgets('vitalidad baja explica la regla vigente', (tester) async {
    const weakened = CharacterProfile(
      level: 3,
      currentXp: 0,
      xpToNextLevel: 100,
      coins: 10,
      hpCurrent: 29,
      hpMax: 100,
      isWeakened: true,
      questsCompleted: 0,
      questsFailed: 0,
      skillLimit: 6,
      skills: [],
    );
    await pump(tester, const ProfileSuccess(weakened));

    expect(
      find.text(
        'Vitalidad baja: ganas un 25 % menos de XP hasta recuperarte. '
        'Tus Monedas no cambian.',
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.heart_broken_outlined), findsOneWidget);
  });

  testWidgets('con vida suficiente no hay aviso de vitalidad', (tester) async {
    await pump(tester, const ProfileSuccess(profile));

    expect(find.textContaining('Vitalidad baja'), findsNothing);
  });

  testWidgets('muestra el título activo y el Tesoro', (tester) async {
    await pump(tester, const ProfileSuccess(profile));

    expect(find.text('Guardián del Huerto'), findsOneWidget);
    expect(find.text('Tesoro del reino'), findsOneWidget);
    expect(find.text('12.500'), findsOneWidget);
    expect(
      find.text('Lo que no cabe en tu bolsa. No se gasta: es tu prestigio.'),
      findsOneWidget,
    );
  });

  testWidgets('sin título ni Tesoro no deja huecos', (tester) async {
    await pump(tester, const ProfileSuccess(newProfile));

    expect(find.text('Guardián del Huerto'), findsNothing);
    expect(find.text('Tesoro del reino'), findsOneWidget);
    expect(
      find.text('Lo que no cabe en tu bolsa. No se gasta: es tu prestigio.'),
      findsOneWidget,
    );
  });

  testWidgets('elegir título envía el elegido', (tester) async {
    await pump(tester, const ProfileSuccess(profile));

    await tester.tap(find.text('Elegir título'));
    await tester.pumpAndSettle();

    expect(find.text('Sin título'), findsOneWidget);
    expect(find.text('Guardián del Huerto'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('Explorador'));
    await tester.pumpAndSettle();

    verify(() => bloc.add(const ProfileActiveTitleChanged('t2'))).called(1);
  });

  testWidgets('sin títulos la hoja explica cómo se ganan', (tester) async {
    await pump(tester, const ProfileSuccess(newProfile));

    await tester.tap(find.text('Elegir título'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aún no tienes títulos. Se ganan con logros, subiendo de nivel y '
        'llenando tu Tesoro del reino.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Comprar'), findsNothing);
    expect(find.text('Sin título'), findsNothing);
  });

  testWidgets('6 accesos en el orden del diseño', (tester) async {
    await pump(tester, const ProfileSuccess(profile));

    const labels = [
      'Diario',
      'Estadísticas',
      'Vision Board',
      'Inventario y logros',
      'Marketplace',
      'Configuración',
    ];
    final positions = [
      for (final label in labels) tester.getTopLeft(find.text(label)),
    ];
    for (var i = 1; i < positions.length; i++) {
      final (prev, curr) = (positions[i - 1], positions[i]);
      expect(
        curr.dy > prev.dy || (curr.dy == prev.dy && curr.dx > prev.dx),
        isTrue,
        reason: '${labels[i]} va después de ${labels[i - 1]}',
      );
    }
    for (final gone in ['Historial', 'Game Master', 'Apariencia']) {
      expect(find.text(gone), findsNothing);
    }

    await tester.tap(find.text('Diario'));
    await tester.tap(find.text('Marketplace'));
    await tester.tap(find.text('Configuración'));
    expect((journalOpened, marketplaceOpened, settingsOpened), (1, 1, 1));

    await tester.tap(find.text('Estadísticas'));
    await tester.tap(find.text('Vision Board'));
    await tester.tap(find.text('Inventario y logros'));
    expect(otherOpened, 3);
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
    const longTitle = PrestigeTitle(
      id: 't9',
      name: 'Guardiana incansable del Huerto y de todos los caminos del reino',
    );
    const withLongTitle = CharacterProfile(
      displayName: 'Ana',
      level: 24,
      currentXp: 7850,
      xpToNextLevel: 12000,
      coins: 2450,
      treasury: 1250000,
      hpCurrent: 20,
      hpMax: 100,
      isWeakened: true,
      questsCompleted: 38,
      questsFailed: 12,
      skillLimit: 6,
      skills: [englishSkill],
      activeTitle: longTitle,
      earnedTitles: [longTitle],
    );
    await pump(
      tester,
      const ProfileSuccess(withLongTitle),
      textScale: 1.3,
      width: 360,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('1.250.000'), findsOneWidget);
    expect(find.text('Inventario y logros'), findsOneWidget);
    expect(find.text('Ayuda'), findsOneWidget);
  });
}
