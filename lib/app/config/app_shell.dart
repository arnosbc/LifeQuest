import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Barra de navegación inferior. Cada pestaña es una rama del router que
/// conserva su propio historial.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    // Iconos de las barras del sistema legibles sobre el fondo de cada tema.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (q.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: q.card,
          ),
      child: Scaffold(
        backgroundColor: q.bg,
        body: SafeArea(bottom: false, child: navigationShell),
        // Brain Dump a un toque desde cualquier pestaña (Modelo de Fogg), salvo
        // en la Mazmorra: dentro del Deep Working, sin ruido (CLAUDE.md §8).
        floatingActionButton: navigationShell.currentIndex == 3
            ? null
            : FloatingActionButton.small(
                heroTag: 'brain_dump',
                tooltip: 'Brain Dump: anota una idea',
                backgroundColor: q.accent,
                foregroundColor: q.onAccent,
                onPressed: () => context.push(RoutePaths.brainDump),
                child: const Icon(Icons.lightbulb_outline),
              ),
        // Tocar una pestaña siempre abre su pantalla principal: Misiones,
        // abierta desde Inicio, no debe quedarse en lugar de Stage.
        bottomNavigationBar: QuestlyNavBar(
          currentIndex: navigationShell.currentIndex,
          onSelected: (index) =>
              navigationShell.goBranch(index, initialLocation: true),
        ),
      ),
    );
  }
}
