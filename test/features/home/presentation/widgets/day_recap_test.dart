import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/day_recap.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/nevi_mood.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const done = HomeDashboard(
    level: 1,
    currentXp: 0,
    xpToNextLevel: 100,
    coins: 0,
    hpCurrent: 100,
    hpMax: 100,
    isWeakened: false,
    habits: [TodayHabit(id: 'h1', name: 'Leer', done: true)],
    habitsDone: 1,
    habitsTotal: 1,
    streakDays: 1,
    missionsDone: 3,
    missionsTotal: 3,
    focusMinutes: 75,
    dailyXp: 95,
  );

  testWidgets('el repaso resume el día y cabe en 360 dp con 1,3×', (
    tester,
  ) async {
    expect(dayComplete(done), isTrue);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDayRecap(context, done),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¡Día completo!'), findsOneWidget);
    expect(find.text('3 tareas'), findsOneWidget);
    expect(find.text('1 de 1 hábitos'), findsOneWidget);
    expect(find.text('95 XP ganada'), findsOneWidget);
    expect(find.text('75 min de Foco'), findsOneWidget);
    expect(find.text('Racha de 1 día'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Hasta mañana'));
    await tester.pumpAndSettle();
    expect(find.text('¡Día completo!'), findsNothing);
  });
}
