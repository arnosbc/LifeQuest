import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:proyecto_movil/features/settings/presentation/screens/settings_screen.dart';

import '../../../../helpers/mocks.dart';
import '../../settings_fixtures.dart';

void main() {
  late MockSettingsBloc bloc;
  var appearanceOpened = 0;

  setUpAll(() => registerFallbackValue(const SettingsRequested()));

  setUp(() {
    appearanceOpened = 0;
    bloc = MockSettingsBloc();
    whenListen(
      bloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsSuccess(settingsOverview),
    );
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.light,
        home: Scaffold(
          body: BlocProvider<SettingsBloc>.value(
            value: bloc,
            child: SettingsScreen(
              userName: 'Ana',
              onBack: () {},
              onSignOut: () {},
              onOpenAppearance: () => appearanceOpened++,
            ),
          ),
        ),
      ),
    );
  }

  GameSettings changed() =>
      (verify(() => bloc.add(captureAny())).captured.single
              as GameSettingsChanged)
          .settings;

  testWidgets('muestra nivel, XP y las reglas actuales', (tester) async {
    await pump(tester);
    expect(find.text('Nivel 7'), findsOneWidget);
    expect(find.text('120 / 1852 XP'), findsOneWidget);
    expect(find.text('XP ×0,85 · Vida perdida ×1,25'), findsOneWidget);
    expect(find.text('Sin límite diario · sin silencio'), findsOneWidget);
    expect(find.text('5 min, y 15 min cada 4 ciclos'), findsOneWidget);
  });

  testWidgets('elegir una dificultad la guarda', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Difícil'));
    expect(changed(), const GameSettings(difficulty: GameDifficulty.hard));
  });

  testWidgets('activar el límite de avisos y la ventana de silencio', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('Avisos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Límite diario de avisos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Más'));
    await tester.tap(find.text('Ventana de silencio'));
    await tester.pumpAndSettle();
    expect(find.text('De 22:00 a 07:00'), findsOneWidget);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      changed(),
      const GameSettings(
        notificationDailyLimit: 11,
        silenceStart: '22:00',
        silenceEnd: '07:00',
      ),
    );
  });

  testWidgets('cambiar los descansos de la Mazmorra', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Descansos de la Mazmorra'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Más').first);
    await tester.tap(find.byTooltip('Menos').last);
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(
      changed(),
      const GameSettings(shortBreakMinutes: 6, longBreakEveryNCycles: 3),
    );
  });

  testWidgets('Apariencia se abre desde Configuración', (tester) async {
    await pump(tester);
    final link = find.text('Modo claro, oscuro o del sistema.');
    await tester.scrollUntilVisible(link, 100);
    await tester.tap(link);
    expect(appearanceOpened, 1);
  });

  testWidgets('si la carga falla, ofrece reintentar', (tester) async {
    whenListen(
      bloc,
      const Stream<SettingsState>.empty(),
      initialState: const SettingsFailure('Sin conexión'),
    );
    await pump(tester);
    expect(find.text('Sin conexión'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    verify(() => bloc.add(const SettingsRequested())).called(1);
  });
}
