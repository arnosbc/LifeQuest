import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/home/presentation/blocs/home_bloc.dart';
import 'package:proyecto_movil/features/home/presentation/screens/home_screen.dart';

import '../../../../helpers/mocks.dart';
import '../../home_fixtures.dart';

void main() {
  late MockHomeBloc bloc;

  setUp(() => bloc = MockHomeBloc());

  Future<void> pump(
    WidgetTester tester,
    HomeState state, {
    double textScale = 1,
    double width = 393,
  }) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: state);
    tester.view.physicalSize = Size(width, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 3000),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: BlocProvider<HomeBloc>.value(
              value: bloc,
              child: HomeScreen(userName: 'Alex', onNavigate: (_) {}),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra los datos del héroe', (tester) async {
    await pump(tester, HomeSuccess(dashboard));

    expect(find.textContaining(', Ana'), findsOneWidget);
    expect(find.text('Preparar presentación del proyecto'), findsOneWidget);
    expect(find.text('Prioridad alta'), findsOneWidget);
    expect(find.text('+350 XP'), findsOneWidget);
    expect(find.text('Nivel 24 · Estratega'), findsOneWidget);
    expect(find.text('Te faltan 4.150 XP para el nivel 25'), findsOneWidget);
    expect(find.text('2.450'), findsOneWidget);
    expect(find.text('3 / 5'), findsOneWidget);
    expect(find.text('Racha de 12 días'), findsOneWidget);
  });

  testWidgets('tocar un hábito pendiente lo registra; uno hecho, no', (
    tester,
  ) async {
    await pump(tester, HomeSuccess(dashboard));

    await tester.tap(find.text('Agua'));
    await tester.tap(find.text('Leer'));

    verify(() => bloc.add(const HomeHabitCompleted('h2'))).called(1);
    verifyNever(() => bloc.add(const HomeHabitCompleted('h1')));
  });

  testWidgets('un héroe nuevo ve estados vacíos que invitan a empezar', (
    tester,
  ) async {
    await pump(tester, const HomeSuccess(emptyDashboard));

    expect(find.textContaining(', Alex'), findsOneWidget);
    expect(find.text('No tienes misiones pendientes'), findsOneWidget);
    expect(find.text('Crear misión'), findsOneWidget);
    expect(find.text('Hoy no tienes hábitos programados.'), findsOneWidget);
    expect(find.text('Ver todos'), findsOneWidget);
    expect(find.text('Nivel 1'), findsOneWidget);
  });

  testWidgets('si la carga falla, ofrece reintentar', (tester) async {
    await pump(tester, const HomeFailure('Sin conexión.'));

    expect(find.text('Sin conexión.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));

    verify(() => bloc.add(const HomeRequested())).called(1);
  });

  testWidgets('mientras carga muestra el indicador', (tester) async {
    await pump(tester, const HomeLoading());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('con escala de texto 1,3 en 360 dp no desborda', (tester) async {
    await pump(
      tester,
      HomeSuccess(dashboardWith(isWeakened: true)),
      textScale: 1.3,
      width: 360,
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('débil por ahora'), findsOneWidget);
    expect(find.text('Taverna'), findsOneWidget);
  });
}
