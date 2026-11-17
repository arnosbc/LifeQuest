import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/entities/difficulty.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/onboarding/presentation/widgets/onboarding_steps.dart';

import '../onboarding_fixtures.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Pantalla angosta y letra grande: el globo de la mascota no debe desbordar.
  final steps = <String, Widget>{
    'bienvenida': const WelcomeStep(),
    'propósito': IdentityStep(controller: TextEditingController()),
    'área': SkillStep(controller: TextEditingController()),
    'ritmo': DifficultyStep(
      options: difficulties,
      selected: GameDifficulty.normal,
      onSelected: (_) {},
    ),
    'resumen': const SummaryStep(
      identity: 'Una persona que termina lo que empieza',
      skill: 'Programación móvil',
      difficulty: GameDifficulty.normal,
    ),
  };

  for (final MapEntry(key: name, value: step) in steps.entries) {
    testWidgets('paso «$name»: mascota y globo caben en 360 dp con 1,3×', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: LifeQuestTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 800),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: step,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(MascotPose), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
