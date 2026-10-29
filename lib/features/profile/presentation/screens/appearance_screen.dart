import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/subpage_header.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/theme_option_card.dart';

/// Elige el tema de la app. Necesita el [AppearanceBloc] global por encima.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({
    super.key,
    required this.onBack,
    this.onOpenDesignPreview,
  });

  final VoidCallback onBack;

  /// Solo en desarrollo: abre la galería de componentes Questly.
  final VoidCallback? onOpenDesignPreview;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<AppearanceBloc, AppearanceState>(
    listenWhen: (_, state) =>
        state is AppearanceSuccess && state.message != null,
    listener: (context, state) =>
        showLifeQuestMessage(context, (state as AppearanceSuccess).message!),
    builder: (context, state) {
      final lq = context.lq;
      return ListView(
        padding: const EdgeInsets.fromLTRB(8, 9, 19, 22),
        children: [
          SubpageHeader(title: 'Apariencia', onBack: onBack),
          Padding(
            padding: const EdgeInsets.only(left: 11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const LifeQuestSectionHeading('TEMA'),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final theme in ThemePreference.values) ...[
                      if (theme != ThemePreference.values.first)
                        const SizedBox(width: 8),
                      Expanded(
                        child: ThemeOptionCard(
                          theme: theme,
                          selected: state.theme == theme,
                          onTap: () => context.read<AppearanceBloc>().add(
                            AppearanceThemeChanged(theme),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  switch (state.theme) {
                    ThemePreference.light =>
                      'Fondo de niebla y superficies blancas.',
                    ThemePreference.dark =>
                      'Fondo de bosque nocturno, más cómodo con poca luz.',
                    ThemePreference.system =>
                      'Cambia entre claro y oscuro según tu teléfono.',
                  },
                  style: TextStyle(color: lq.muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 28),
                const LifeQuestSectionHeading('TAMAÑO DEL TEXTO'),
                const SizedBox(height: 8),
                LifeQuestSurface(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const LifeQuestIconTile(
                        Icons.text_fields_rounded,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Sigue el tamaño de letra de los ajustes de '
                          'tu teléfono.',
                          style: TextStyle(
                            color: lq.ink,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onOpenDesignPreview != null) ...[
                  const SizedBox(height: 28),
                  QuestlyButton(
                    label: 'Galería de diseño (desarrollo)',
                    variant: QuestlyButtonVariant.tonal,
                    onPressed: onOpenDesignPreview,
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    },
  );
}
