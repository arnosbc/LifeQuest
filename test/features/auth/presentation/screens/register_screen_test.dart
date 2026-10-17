import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/register_screen.dart';
import 'package:proyecto_movil/features/auth/services/auth_service.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';

import '../../../../helpers/fake_auth_service.dart';

Widget _scoped(Widget app) => ProviderScope(
  overrides: [authServiceProvider.overrideWithValue(FakeAuthService())],
  child: app,
);

void main() {
  testWidgets('TalkBack: el botón de ver contraseña es un nodo propio', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_scoped(const MaterialApp(home: RegisterScreen())));

    expect(
      tester.getSemantics(find.byTooltip('Mostrar contraseña').first),
      containsSemantics(isButton: true, isTextField: false),
    );

    final password = tester
        .getSemantics(find.byType(EditableText).at(2))
        .getSemanticsData();
    expect(password.label, 'Contraseña');

    expect(
      tester.getSemantics(find.byType(Checkbox)),
      containsSemantics(label: 'Acepto los términos y condiciones'),
    );
    handle.dispose();
  });

  testWidgets('datos inválidos muestran errores y no salen de la página', (
    tester,
  ) async {
    await tester.pumpWidget(_scoped(const MaterialApp(home: RegisterScreen())));

    await tester.enterText(find.byType(EditableText).at(0), 'Ana');
    await tester.enterText(find.byType(EditableText).at(1), 'ana@correo');
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ingresa un correo válido, como nombre@correo.com.'),
      findsOneWidget,
    );
    expect(find.text('Acepta los términos para continuar.'), findsOneWidget);
    expect(find.byType(RegisterScreen), findsOneWidget);
    // El cursor salta al primer campo inválido (el correo).
    final email = tester.widget<EditableText>(find.byType(EditableText).at(1));
    expect(email.focusNode.hasFocus, isTrue);
  });

  testWidgets('en tema oscuro usa la paleta oscura', (tester) async {
    await tester.pumpWidget(
      _scoped(
        MaterialApp(
          theme: LifeQuestTheme.light,
          darkTheme: LifeQuestTheme.dark,
          themeMode: ThemeMode.dark,
          home: const RegisterScreen(),
        ),
      ),
    );
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, LifeQuestPalette.dark.background);
  });
}
