import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/screens/appearance_screen.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAppearanceBloc bloc;

  setUp(() {
    bloc = MockAppearanceBloc();
    whenListen(
      bloc,
      const Stream<AppearanceState>.empty(),
      initialState: const AppearanceSuccess(ThemePreference.system),
    );
  });

  Future<void> pump(WidgetTester tester, {ThemeData? theme}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: theme ?? LifeQuestTheme.light,
          home: Scaffold(
            body: BlocProvider<AppearanceBloc>.value(
              value: bloc,
              child: AppearanceScreen(onBack: () {}),
            ),
          ),
        ),
      );

  testWidgets('elegir Oscuro envía el cambio de tema', (tester) async {
    await pump(tester);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Tema Sistema')),
      isSemantics(
        label: 'Tema Sistema',
        isButton: true,
        isSelected: true,
        isInMutuallyExclusiveGroup: true,
        hasTapAction: true,
      ),
    );

    await tester.tap(find.text('Oscuro'));

    verify(
      () => bloc.add(const AppearanceThemeChanged(ThemePreference.dark)),
    ).called(1);
  });

  testWidgets('en tema oscuro y texto 1,3 a 360 dp no desborda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pump(tester, theme: LifeQuestTheme.dark);

    expect(tester.takeException(), isNull);
    expect(find.text('Sistema'), findsOneWidget);
  });
}
