import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';

Widget _app(
  Widget child, {
  bool dark = false,
  QuestlyRealm realm = QuestlyRealm.bosque,
}) => MaterialApp(
  theme: LifeQuestTheme.build(realm, dark: dark),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: child,
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('los componentes se pintan en claro, oscuro y los 4 temas', (
    tester,
  ) async {
    for (final realm in QuestlyRealm.values) {
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          _app(
            dark: dark,
            realm: realm,
            Column(
              children: [
                const QuestlyHero(kicker: 'Diario', heading: 'Bitácora'),
                QuestlyButton(label: 'Principal', onPressed: () {}),
                const QuestlyCard(child: Text('Tarjeta')),
                const QuestlyPriorityChip(QuestlyPriority.high),
              ],
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Bitácora'), findsOneWidget);
      }
    }
  });

  testWidgets('el botón desactivado explica por qué y no responde', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            QuestlyButton(label: 'Guardar', onPressed: () => taps++),
            const QuestlyButton(
              label: 'Comprar',
              disabledReason: 'Te faltan 20 Monedas',
              onPressed: null,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Guardar'));
    await tester.tap(find.text('Te faltan 20 Monedas'));
    expect(taps, 1);
    expect(find.text('Comprar'), findsNothing);
    expect(
      tester.getSize(find.byType(QuestlyButton).first).height,
      greaterThanOrEqualTo(QSize.buttonPrimary),
    );
  });

  testWidgets('botones de icono con nombre accesible y zona táctil ≥ 44', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            QuestlyHero(
              kicker: 'Tablero de misiones',
              heading: 'Stage',
              onBack: () {},
              onAction: () {},
              actionLabel: 'Crear',
            ),
            QuestlyFilterChip(label: 'Hoy', selected: true, onTap: () {}),
            QuestlySegmented<int>(
              segments: const [(0, 'Hoy'), (1, 'Calendario')],
              selected: 0,
              onChanged: (_) {},
            ),
            QuestlyCloseButton(onTap: () {}),
          ],
        ),
      ),
    );
    expect(find.bySemanticsLabel('Volver'), findsOneWidget);
    expect(find.bySemanticsLabel('Crear'), findsOneWidget);
    expect(find.bySemanticsLabel('Cerrar'), findsOneWidget);
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('la barra marca la pestaña activa y avisa el toque', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: LifeQuestTheme.build(QuestlyRealm.bosque, dark: false),
        home: Scaffold(
          bottomNavigationBar: QuestlyNavBar(
            currentIndex: 1,
            onSelected: (i) => tapped = i,
          ),
        ),
      ),
    );
    for (final label in ['Inicio', 'Stage', 'Hábitos', 'Mazmorra', 'Perfil']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.text('Stage')),
      matchesSemantics(
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        label: 'Stage',
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    await tester.tap(find.text('Mazmorra'));
    expect(tapped, 3);
    // La barra mide lo suyo y deja ver la pantalla.
    expect(tester.getSize(find.byType(QuestlyNavBar)).height, lessThan(100));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('el toast se anuncia y se va a los 2,2 s', (tester) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => QuestlyButton(
            label: 'Archivar',
            onPressed: () => showQuestlyToast(context, 'Tarea archivada'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Archivar'));
    await tester.pump();
    expect(find.text('Tarea archivada'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2100));
    expect(find.text('Tarea archivada'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Tarea archivada'), findsNothing);
  });

  testWidgets('la hoja y el diálogo tienen título y cierre visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Column(
            children: [
              QuestlyButton(
                label: 'Hoja',
                onPressed: () => showQuestlySheet<void>(
                  context,
                  title: 'Tu carrito',
                  child: const Text('Contenido'),
                ),
              ),
              QuestlyButton(
                label: 'Diálogo',
                onPressed: () => showQuestlyDialog<void>(
                  context,
                  title: '¿Cerrar sesión?',
                  message: 'Tu progreso queda guardado.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Hoja'));
    await tester.pumpAndSettle();
    expect(find.text('Tu carrito'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('Tu carrito'), findsNothing);

    await tester.tap(find.text('Diálogo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsNothing);
  });
}
