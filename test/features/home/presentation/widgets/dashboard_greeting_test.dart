import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/home/presentation/widgets/dashboard_greeting.dart';

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    DateTime now, {
    int unread = 0,
    VoidCallback? onOpenNotifications,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DashboardGreeting(
          userName: 'Alex',
          onOpenProfile: () {},
          onOpenNotifications: onOpenNotifications ?? () {},
          unreadNotifications: unread,
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

  testWidgets('la campana abre los avisos y cuenta los no leídos', (
    tester,
  ) async {
    var opened = 0;
    await pumpAt(
      tester,
      DateTime(2026, 10, 29, 9),
      onOpenNotifications: () {
        opened++;
      },
    );
    expect(find.byTooltip('Notificaciones'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    await tester.tap(find.byTooltip('Notificaciones'));
    expect(opened, 1);

    await pumpAt(tester, DateTime(2026, 10, 29, 9), unread: 3);
    expect(find.byTooltip('Notificaciones, 3 sin leer'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    await pumpAt(tester, DateTime(2026, 10, 29, 9), unread: 12);
    expect(find.text('9+'), findsOneWidget);
  });
}
