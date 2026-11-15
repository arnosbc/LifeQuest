import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/first_tour.dart';
import 'package:proyecto_movil/core/rewards/reward_feed.dart';
import 'package:proyecto_movil/core/sound/sound_effects.dart';
import 'package:proyecto_movil/core/widgets/mascot_background.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/questly/reward_moment.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Barra de navegación inferior. Cada pestaña es una rama del router que
/// conserva su propio historial.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  // shortcut: en memoria; un segundo usuario nuevo en el mismo proceso no
  // vería la guía. Reiniciarlo al cerrar sesión si hiciera falta.
  static bool _tourShown = false;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    // Recién terminó el Onboarding: Nevi muestra la guía una sola vez.
    if (context.read<OnboardingBloc>().state case OnboardingNotNeeded(
      justCompleted: true,
    ) when !_tourShown) {
      _tourShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showFirstTour(context);
      });
    }
    // Iconos de las barras del sistema legibles sobre el fondo de cada tema.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (q.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: q.card,
          ),
      // Lo que pagó el servidor se muestra aquí, en cualquier pestaña.
      child: RewardMomentListener(
        rewards: sl<RewardFeed>().stream,
        sounds: sl<SoundEffects>(),
        streakNow: _activityStreak,
        child: Scaffold(
          backgroundColor: q.bg,
          body: MascotBackground(
            veil: q.bg,
            child: SafeArea(bottom: false, child: navigationShell),
          ),
          // Brain Dump a un toque desde cualquier pestaña (Modelo de Fogg), salvo
          // en la Mazmorra: dentro del Deep Working, sin ruido (CLAUDE.md §8).
          floatingActionButton: navigationShell.currentIndex == 3
              ? null
              : FloatingActionButton.small(
                  heroTag: 'brain_dump',
                  tooltip: 'Bandeja de ideas: anota una idea',
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
      ),
    );
  }
}

/// Racha diaria de actividad (056) para la pantalla de racha.
// shortcut: consulta directa desde app/ (composición) en vez de una feature;
// moverla a home/data si crece (p. ej. mejor racha o calendario de racha).
Future<int?> _activityStreak() async {
  final client = sl<SupabaseClient>();
  final uid = client.auth.currentUser?.id;
  if (uid == null) return null;
  final now = DateTime.now();
  final result = await client.rpc<dynamic>(
    '_activity_streak',
    params: {
      'p_uid': uid,
      'p_day': now.toIso8601String().substring(0, 10),
      'p_utc_offset_minutes': now.timeZoneOffset.inMinutes,
    },
  );
  return (result as num?)?.toInt();
}
