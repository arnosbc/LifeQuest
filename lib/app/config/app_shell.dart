import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/config/theme.dart';

/// Barra de navegación inferior. Cada pestaña es una rama del router que
/// conserva su propio historial.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _labels = ['Inicio', 'Stage', 'Hábitos', 'Mazmorra', 'Perfil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.dashboard_outlined,
    Icons.monitor_heart_outlined,
    Icons.shield_outlined,
    Icons.person_outline,
  ];
  static const _selectedIcons = [
    Icons.home_rounded,
    Icons.dashboard_rounded,
    Icons.monitor_heart_rounded,
    Icons.shield_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Iconos de las barras del sistema legibles sobre el fondo de cada tema.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: lq.surface,
          ),
      child: Scaffold(
        backgroundColor: lq.background,
        body: SafeArea(bottom: false, child: navigationShell),
        // Brain Dump a un toque desde cualquier pestaña (Modelo de Fogg), salvo
        // en la Mazmorra: dentro del Deep Working, sin ruido (CLAUDE.md §8).
        floatingActionButton: navigationShell.currentIndex == 3
            ? null
            : FloatingActionButton.small(
                heroTag: 'brain_dump',
                tooltip: 'Brain Dump: anota una idea',
                backgroundColor: lq.deepGreen,
                foregroundColor: lq.onDeepGreen,
                onPressed: () => context.push(RoutePaths.brainDump),
                child: const Icon(Icons.lightbulb_outline),
              ),
        bottomNavigationBar: NavigationBar(
          height: 66,
          selectedIndex: navigationShell.currentIndex,
          // Tocar una pestaña siempre abre su pantalla principal: Misiones,
          // abierta desde Inicio, no debe quedarse en lugar de Stage.
          onDestinationSelected: (index) =>
              navigationShell.goBranch(index, initialLocation: true),
          backgroundColor: lq.surface,
          indicatorColor: lq.softGreen,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (var i = 0; i < _labels.length; i++)
              NavigationDestination(
                icon: Icon(_icons[i]),
                selectedIcon: Icon(_selectedIcons[i]),
                label: _labels[i],
              ),
          ],
        ),
      ),
    );
  }
}
