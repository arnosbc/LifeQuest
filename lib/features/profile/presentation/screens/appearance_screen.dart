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
    this.soundsOn,
    this.onSoundsChanged,
  });

  final VoidCallback onBack;

  /// Sonidos de logro (los guarda la app); null oculta el interruptor.
  final bool? soundsOn;
  final ValueChanged<bool>? onSoundsChanged;

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
                      'Fondo violeta nocturno, más cómodo con poca luz.',
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
                if (soundsOn != null) ...[
                  const SizedBox(height: 28),
                  const LifeQuestSectionHeading('SONIDOS'),
                  const SizedBox(height: 8),
                  LifeQuestSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _SoundSwitch(
                      initial: soundsOn!,
                      onChanged: onSoundsChanged,
                    ),
                  ),
                ],
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

/// Interruptor con estado propio: reconstruir la pantalla (p. ej. al cambiar
/// el tema) no lo devuelve al valor inicial.
class _SoundSwitch extends StatefulWidget {
  const _SoundSwitch({required this.initial, this.onChanged});

  final bool initial;
  final ValueChanged<bool>? onChanged;

  @override
  State<_SoundSwitch> createState() => _SoundSwitchState();
}

class _SoundSwitchState extends State<_SoundSwitch> {
  late bool _on = widget.initial;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: _on,
    title: Text(
      'Sonidos de logro',
      style: TextStyle(color: context.lq.ink, fontSize: 14),
    ),
    subtitle: Text(
      'Al completar tareas, cobrar cofres y subir de nivel.',
      style: TextStyle(color: context.lq.muted, fontSize: 12),
    ),
    onChanged: (v) {
      setState(() => _on = v);
      widget.onChanged?.call(v);
    },
  );
}
