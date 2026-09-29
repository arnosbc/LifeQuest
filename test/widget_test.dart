// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/main.dart';

void main() {
  testWidgets('LifeQuest login opens registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LifeQuest'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);

    await tester.tap(find.text('Crea tu perfil'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Crea tu Héroe'), findsOneWidget);
    expect(find.text('Confirmar Contraseña'), findsOneWidget);
    expect(find.text('Crear Cuenta'), findsOneWidget);
  });

  testWidgets('valid login opens home and bottom tabs navigate', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 756);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'alex@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Buenos días, Alex'), findsOneWidget);
    expect(find.text('ACCESOS RÁPIDOS'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.tap(find.text('Misiones').last);
    await tester.pumpAndSettle();

    expect(
      find.text('Cada paso cuenta para tu siguiente nivel.'),
      findsOneWidget,
    );
    expect(find.text('Preparar presentación del proyecto'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
