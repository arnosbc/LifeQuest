import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/entities/smart_goal.dart';
import 'package:proyecto_movil/core/widgets/smart_goal_sheet.dart';

Widget _host(SmartGoalSheet sheet) => MaterialApp(
  theme: LifeQuestTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: sheet)),
);

void main() {
  testWidgets('muestra todas las skills como chips y deja elegir una', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const SmartGoalSheet(
          initialTitle: 'Correr 21 km',
          skills: [
            SkillChoice(id: 's1', name: 'Salud'),
            SkillChoice(id: 's2', name: 'Programación'),
          ],
        ),
      ),
    );

    expect(find.text('Correr 21 km'), findsOneWidget);
    for (final name in ['Sin vincular', 'Salud', 'Programación']) {
      expect(find.widgetWithText(ChoiceChip, name), findsOneWidget);
    }
    ChoiceChip chip(String name) =>
        tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, name));
    expect(chip('Sin vincular').selected, isTrue);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Salud'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Salud'));
    await tester.pump();
    expect(chip('Salud').selected, isTrue);
    expect(chip('Sin vincular').selected, isFalse);
  });

  testWidgets('sin skills invita a crearlas en el Perfil', (tester) async {
    await tester.pumpWidget(_host(const SmartGoalSheet(skills: [])));
    expect(find.textContaining('Créalas en tu Perfil'), findsOneWidget);
  });
}
