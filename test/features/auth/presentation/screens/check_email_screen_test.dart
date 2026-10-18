import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/check_email_screen.dart';

void main() {
  Widget app({ThemeMode themeMode = ThemeMode.light}) => MaterialApp.router(
    theme: LifeQuestTheme.light,
    darkTheme: LifeQuestTheme.dark,
    themeMode: themeMode,
    routerConfig: GoRouter(
      initialLocation: RoutePaths.checkEmail,
      routes: [
        GoRoute(path: RoutePaths.login, builder: (_, _) => const Text('login')),
        GoRoute(
          path: RoutePaths.register,
          builder: (_, _) => const Text('registro'),
        ),
        GoRoute(
          path: RoutePaths.checkEmail,
          builder: (_, _) =>
              const CheckEmailScreen(username: 'Ana', email: 'ana@correo.com'),
        ),
      ],
    ),
  );

  testWidgets('muestra el correo al que se envió el enlace', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Revisa tu correo'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.textContaining('«Ana»'), findsOneWidget);
  });

  testWidgets('el botón lleva al login', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Ir a iniciar sesión'));
    await tester.tap(find.text('Ir a iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('login'), findsOneWidget);
  });

  testWidgets('con escala de texto 1,3 no desborda', (tester) async {
    tester.view.physicalSize = const Size(360, 640) * 3;
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(app(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, LifeQuestPalette.dark.background);
  });
}
