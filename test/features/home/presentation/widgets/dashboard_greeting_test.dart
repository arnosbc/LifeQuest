import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/home/presentation/widgets/dashboard_greeting.dart';

void main() {
  Future<void> pumpAt(WidgetTester tester, DateTime now) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DashboardGreeting(
          userName: 'Alex',
          onOpenProfile: () {},
          now: now,
        ),
      ),
    ),
  );

  testWidgets('muestra la fecha en español y saluda según la hora', (
    tester,
  ) async {
    await pumpAt(tester, DateTime(2026, 9, 29, 8));
    expect(find.text('Martes, 29 de septiembre'), findsOneWidget);
    expect(find.text('Buenos días, Alex'), findsOneWidget);

    await pumpAt(tester, DateTime(2026, 10, 17, 15));
    expect(find.text('Sábado, 17 de octubre'), findsOneWidget);
    expect(find.text('Buenas tardes, Alex'), findsOneWidget);

    await pumpAt(tester, DateTime(2026, 10, 17, 21));
    expect(find.text('Buenas noches, Alex'), findsOneWidget);
  });
}
