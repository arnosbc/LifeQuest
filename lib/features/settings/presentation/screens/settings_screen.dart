import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/presentation/blocs/settings_bloc.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/account_card.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/setting_link.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/settings_sheets.dart';

/// Configuración (Game Master). Necesita un [SettingsBloc] (lo provee el router).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.userName,
    required this.onBack,
    required this.onSignOut,
    required this.onOpenAppearance,
  });

  final String userName;
  final VoidCallback onBack;

  /// Cierra la sesión. Lo provee la app (la sesión vive en auth); al cerrarse,
  /// el router vuelve al login.
  final VoidCallback onSignOut;

  /// Abre la pantalla de Apariencia (modo claro, oscuro o del sistema).
  final VoidCallback onOpenAppearance;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<SettingsBloc, SettingsState>(
    listenWhen: (_, state) => state is SettingsSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as SettingsSuccess).message!),
    builder: (context, state) => LifeQuestPage(
      title: 'Configuración',
      subtitle: 'Tus reglas del juego. Cámbialas cuando quieras.',
      trailing: IconButton(
        onPressed: onBack,
        tooltip: 'Volver al perfil',
        icon: Icon(Icons.close_rounded, color: context.lq.ink),
      ),
      children: [
        AccountCard(
          userName: userName,
          overview: state is SettingsSuccess ? state.overview : null,
        ),
        const SizedBox(height: 20),
        ...switch (state) {
          SettingsSuccess(:final overview, :final saving) => _gameMaster(
            context,
            overview,
            saving: saving,
          ),
          SettingsFailure(:final message) => [
            _LoadError(
              message: message,
              onRetry: () =>
                  context.read<SettingsBloc>().add(const SettingsRequested()),
            ),
          ],
          _ => [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: context.lq.deepGreen),
              ),
            ),
          ],
        },
        const SizedBox(height: 12),
        const LifeQuestSectionHeading('APP'),
        const SizedBox(height: 8),
        SettingLink(
          icon: Icons.palette_outlined,
          title: 'Apariencia',
          description: 'Modo claro, oscuro o del sistema.',
          onTap: onOpenAppearance,
        ),
        SettingLink(
          icon: Icons.shopping_bag_outlined,
          title: 'Contenido de la Tienda',
          description: 'Elige qué recompensas aparecen en tu Tienda.',
          onTap: () => showLifeQuestMessage(
            context,
            'La Tienda estará disponible próximamente.',
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tu progreso está guardado en la nube. Puedes volver a entrar '
          'cuando quieras.',
          style: TextStyle(color: context.lq.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _confirmSignOut(context),
            icon: const Icon(Icons.logout_rounded, size: 20),
            label: const Text('Cerrar sesión'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.lq.ink,
              side: BorderSide(color: context.lq.line),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  List<Widget> _gameMaster(
    BuildContext context,
    SettingsOverview overview, {
    required bool saving,
  }) {
    final bloc = context.read<SettingsBloc>();
    final settings = overview.settings;

    Future<void> edit(
      Future<GameSettings?> Function(BuildContext, GameSettings) sheet,
    ) async {
      final result = await sheet(context, settings);
      if (result != null) bloc.add(GameSettingsChanged(result));
    }

    return [
      const LifeQuestSectionHeading('DIFICULTAD'),
      const SizedBox(height: 4),
      if (DifficultyPicker.sameCoins(overview.difficulties))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Cambia la XP que ganas y la vida que pierdes. Las Monedas son '
            'iguales en las tres.',
            style: TextStyle(color: context.lq.muted, fontSize: 12),
          ),
        ),
      DifficultyPicker(
        options: overview.difficulties,
        selected: settings.difficulty,
        onSelected: saving
            ? null
            : (level) =>
                  bloc.add(GameSettingsChanged(settings.withDifficulty(level))),
      ),
      const SizedBox(height: 12),
      const LifeQuestSectionHeading('REGLAS DEL JUEGO'),
      const SizedBox(height: 8),
      SettingLink(
        icon: Icons.notifications_active_outlined,
        title: 'Avisos',
        description: notificationSummary(settings),
        onTap: saving ? null : () => edit(showNotificationSheet),
      ),
      SettingLink(
        icon: Icons.timer_outlined,
        title: 'Descansos de la Mazmorra',
        description: breaksSummary(settings),
        onTap: saving ? null : () => edit(showBreaksSheet),
      ),
    ];
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tu progreso está guardado. Puedes volver cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true) onSignOut();
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.lq.ink, fontSize: 14),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 20),
          label: const Text('Reintentar'),
          style: FilledButton.styleFrom(
            backgroundColor: context.lq.deepGreen,
            foregroundColor: context.lq.onDeepGreen,
            minimumSize: const Size(48, 48),
          ),
        ),
      ],
    ),
  );
}
