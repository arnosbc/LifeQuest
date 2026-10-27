import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/screens/onboarding_screen.dart';

import '../../../helpers/mocks.dart';
import '../onboarding_fixtures.dart';

void main() {
  late MockOnboardingBloc bloc;

  setUpAll(() => registerFallbackValue(const OnboardingReset()));

  setUp(() {
    bloc = MockOnboardingBloc();
    whenListen(
      bloc,
      const Stream<OnboardingState>.empty(),
      initialState: const OnboardingPending(pendingStatus),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.light,
        home: BlocProvider<OnboardingBloc>.value(
          value: bloc,
          child: const OnboardingScreen(),
        ),
      ),
    );
  }

  Future<void> tapMain(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  OnboardingChoices submitted() =>
      (verify(() => bloc.add(captureAny())).captured.single
              as OnboardingSubmitted)
          .choices;

  testWidgets('recorre los 5 pasos y guarda lo elegido', (tester) async {
    await pump(tester);
    expect(find.text('Paso 1 de 5'), findsOneWidget);
    await tapMain(tester, 'Empezar');

    await tester.enterText(find.byType(TextField), 'Guardiana del huerto');
    await tapMain(tester, 'Continuar');

    // La sugerencia rellena el campo y sigue editable.
    await tester.tap(find.text('Salud'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'Salud'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Salud física');
    await tapMain(tester, 'Continuar');

    // Paso 4: valores del servidor, Normal preseleccionada.
    expect(find.text('XP ×1,2 · Vida perdida ×0,75'), findsOneWidget);
    expect(find.text('XP ×0,85 · Vida perdida ×1,25'), findsOneWidget);
    expect(find.text('Las Monedas son iguales en las tres.'), findsOneWidget);
    expect(
      find.text('Después solo podrás cambiarla en Configuración.'),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Normal'),
          matching: find.byType(InkWell),
        ),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tapMain(tester, 'Continuar');

    expect(find.text('Guardiana del huerto'), findsOneWidget);
    expect(find.text('Salud física'), findsOneWidget);
    expect(find.text('Difícil'), findsOneWidget);
    await tapMain(tester, 'Entrar al reino');

    expect(
      submitted(),
      const OnboardingChoices(
        identity: 'Guardiana del huerto',
        skill: 'Salud física',
        difficulty: GameDifficulty.hard,
      ),
    );
  });

  testWidgets('Atrás vuelve al paso anterior con lo escrito', (tester) async {
    await pump(tester);
    await tapMain(tester, 'Empezar');
    await tester.enterText(find.byType(TextField), 'Viajera');
    await tapMain(tester, 'Continuar');
    await tester.tap(find.byTooltip('Atrás'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 2 de 5'), findsOneWidget);
    expect(find.text('Viajera'), findsOneWidget);
  });

  testWidgets('saltar antes del paso 4 guarda lo escrito y Normal', (
    tester,
  ) async {
    await pump(tester);
    await tapMain(tester, 'Empezar');
    await tester.enterText(find.byType(TextField), 'Viajera');
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(submitted(), const OnboardingChoices(identity: 'Viajera'));
  });

  testWidgets('saltar en el paso 4 guarda la dificultad marcada', (
    tester,
  ) async {
    await pump(tester);
    await tapMain(tester, 'Empezar');
    await tapMain(tester, 'Continuar');
    await tapMain(tester, 'Continuar');
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(
      submitted(),
      const OnboardingChoices(difficulty: GameDifficulty.easy),
    );
  });

  testWidgets('error al guardar muestra el aviso con Reintentar', (
    tester,
  ) async {
    whenListen(
      bloc,
      Stream<OnboardingState>.fromIterable(const [
        OnboardingPending(pendingStatus, error: 'Sin conexión.'),
      ]),
      initialState: const OnboardingPending(pendingStatus),
    );
    await pump(tester);
    await tester.pump();
    expect(find.text('Sin conexión.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    // Saltar sigue disponible.
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Saltar'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('mientras consulta muestra un indicador', (tester) async {
    whenListen(
      bloc,
      const Stream<OnboardingState>.empty(),
      initialState: const OnboardingLoading(),
    );
    await pump(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Preparando tu aventura'), findsOneWidget);
  });
}
