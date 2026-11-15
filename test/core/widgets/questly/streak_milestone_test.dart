import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/entities/reward_outcome.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/questly/reward_moment.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> reward(WidgetTester tester, int streak) async {
    final rewards = StreamController<RewardOutcome>();
    addTearDown(rewards.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.light,
        home: RewardMomentListener(
          rewards: rewards.stream,
          streakNow: () async => streak,
          child: const Scaffold(),
        ),
      ),
    );
    rewards.add(const RewardOutcome(xp: 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  // Deja correr la tarjeta (2,8 s) y el confeti para que no queden timers.
  Future<void> drain(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 6));

  testWidgets('a los 7 días la pantalla de racha celebra el hito', (
    tester,
  ) async {
    await reward(tester, 7);
    expect(find.text('🏆 ¡Hito: 7 días de racha!'), findsOneWidget);
    expect(find.textContaining('Semana de fuego'), findsOneWidget);
    final pose = tester.widget<MascotPose>(find.byType(MascotPose));
    expect(pose.pose, 'celebrando');
    await drain(tester);
  });

  testWidgets('un día normal muestra la racha de siempre', (tester) async {
    await reward(tester, 5);
    expect(find.text('¡Racha de 5 días!'), findsOneWidget);
    expect(find.textContaining('Hito'), findsNothing);
    await drain(tester);
  });
}
