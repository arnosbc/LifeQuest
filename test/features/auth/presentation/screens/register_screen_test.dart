import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/register_screen.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthBloc authBloc;

  setUpAll(() => registerFallbackValue(const LogoutRequested()));

  setUp(() {
    authBloc = MockAuthBloc();
    when(() => authBloc.state).thenReturn(const AuthUnauthenticated());
  });

  Widget app({ThemeMode themeMode = ThemeMode.light}) =>
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp(
          theme: LifeQuestTheme.light,
          darkTheme: LifeQuestTheme.dark,
          themeMode: themeMode,
          home: const RegisterScreen(),
        ),
      );

  Future<void> tapCreateAccount(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Crear cuenta'));
    await tester.tap(find.text('Crear cuenta'));
    await tester.pumpAndSettle();
  }

  testWidgets('TalkBack: etiquetas de campos, contraseña y casilla', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app());

    expect(
      tester.getSemantics(find.byTooltip('Mostrar contraseña').first),
      isSemantics(isButton: true, isTextField: false),
    );
    final password = tester
        .getSemantics(find.byType(EditableText).at(2))
        .getSemanticsData();
    expect(password.label, 'Contraseña');
    expect(
      tester.getSemantics(find.byType(Checkbox)),
      isSemantics(label: 'Acepto los términos y condiciones'),
    );
    handle.dispose();
  });

  testWidgets('datos inválidos muestran errores y no envían el registro', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(EditableText).at(0), 'Ana');
    await tester.enterText(find.byType(EditableText).at(1), 'ana@correo');
    await tapCreateAccount(tester);

    expect(
      find.text('Ingresa un correo válido, como nombre@correo.com.'),
      findsOneWidget,
    );
    expect(find.text('Acepta los términos para continuar.'), findsOneWidget);
    // El cursor salta al primer campo inválido (el correo).
    final email = tester.widget<EditableText>(find.byType(EditableText).at(1));
    expect(email.focusNode.hasFocus, isTrue);
    verifyNever(() => authBloc.add(any()));
  });

  testWidgets('datos válidos envían RegisterRequested al bloc', (tester) async {
    await tester.pumpWidget(app());

    await tester.enterText(find.byType(EditableText).at(0), ' Ana ');
    await tester.enterText(find.byType(EditableText).at(1), 'ana@correo.com');
    await tester.enterText(find.byType(EditableText).at(2), 'secret1');
    await tester.enterText(find.byType(EditableText).at(3), 'secret1');
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tapCreateAccount(tester);

    verify(
      () => authBloc.add(
        const RegisterRequested(
          username: 'Ana',
          email: 'ana@correo.com',
          password: 'secret1',
        ),
      ),
    ).called(1);
  });

  testWidgets('un AuthFailure se muestra como mensaje', (tester) async {
    whenListen(
      authBloc,
      Stream.fromIterable(const [
        AuthLoading(),
        AuthFailure('Ya existe una cuenta con ese correo. Inicia sesión.'),
      ]),
      initialState: const AuthUnauthenticated(),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(
      find.text('Ya existe una cuenta con ese correo. Inicia sesión.'),
      findsOneWidget,
    );
  });

  testWidgets('mientras carga, el botón muestra el indicador', (tester) async {
    when(() => authBloc.state).thenReturn(const AuthLoading());
    await tester.pumpWidget(app());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('en tema oscuro usa la paleta oscura', (tester) async {
    await tester.pumpWidget(app(themeMode: ThemeMode.dark));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, LifeQuestPalette.dark.background);
  });
}
