import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/capture_sheet.dart';
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
        // Anotar a un toque desde cualquier pestaña (Modelo de Fogg), salvo en
        // Foco: dentro de la sesión, sin ruido (CLAUDE.md §8). Lo que no es
        // tarea va a la Bandeja desde la misma hoja.
        floatingActionButton: navigationShell.currentIndex == 3
            ? null
            : FloatingActionButton(
                heroTag: 'capture',
                tooltip: 'Anotar una tarea o una idea',
                onPressed: () => openCaptureSheet(context),
                child: const Icon(Icons.add_rounded, size: 28),
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
