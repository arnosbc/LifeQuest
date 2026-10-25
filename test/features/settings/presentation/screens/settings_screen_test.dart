import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('Apariencia se abre desde Configuración', (tester) async {
    var appearanceOpened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsScreen(
            userName: 'Ana',
            onBack: () {},
            onSignOut: () {},
            onOpenAppearance: () => appearanceOpened++,
          ),
        ),
      ),
    );

    final link = find.text('Modo claro, oscuro o del sistema.');
    await tester.scrollUntilVisible(link, 100);
    await tester.tap(link);

    expect(appearanceOpened, 1);
  });
}
