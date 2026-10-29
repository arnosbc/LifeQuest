import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';

/// Galería de los componentes Questly (solo en desarrollo). Los datos son de
/// ejemplo, tomados de SistemaDiseno.dc.html y Hero.dc.html.
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  String _tab = 'Hoy';
  String _filter = 'Todas';

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final appearance = context.watch<AppearanceBloc>().state;
    final bloc = context.read<AppearanceBloc>();
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: QSpace.xl, bottom: QSpace.m),
      child: Semantics(
        header: true,
        child: Text(text, style: QText.title3(q.text)),
      ),
    );
    return Scaffold(
      backgroundColor: q.bg,
      body: ListView(
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        children: [
          QuestlyHero(
            kicker: 'Sistema de diseño',
            heading: 'Bosque vivo',
            icon: QIcons.leaf,
            onBack: () => context.pop(),
            onAction: () => showQuestlyToast(context, 'Tienes 3 avisos'),
            actionLabel: 'Avisos',
            actionIcon: QIcons.bell,
            badge: '3',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QSpace.gutter,
              0,
              QSpace.gutter,
              QSpace.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                heading('Modo'),
                QuestlySegmented<ThemePreference>(
                  segments: const [
                    (ThemePreference.light, 'Claro'),
                    (ThemePreference.dark, 'Oscuro'),
                    (ThemePreference.system, 'Auto'),
                  ],
                  selected: appearance.theme,
                  onChanged: (v) => bloc.add(AppearanceThemeChanged(v)),
                ),
                heading('Tema del reino'),
                QuestlySegmented<ThemeRealm>(
                  segments: const [
                    (ThemeRealm.bosque, 'Bosque'),
                    (ThemeRealm.rio, 'Río'),
                    (ThemeRealm.brasa, 'Brasa'),
                    (ThemeRealm.oro, 'Oro'),
                  ],
                  selected: appearance.realm,
                  onChanged: (v) => bloc.add(AppearanceRealmChanged(v)),
                ),
                heading('Cabecera (Hero) · 5 tonos'),
                for (final (tone, name) in const [
                  (QHeroTone.forest, 'Bosque'),
                  (QHeroTone.river, 'Río'),
                  (QHeroTone.ember, 'Brasa'),
                  (QHeroTone.gold, 'Oro'),
                  (QHeroTone.night, 'Noche'),
                ]) ...[
                  QuestlyHero(
                    kicker: 'Tablero de misiones',
                    heading: name,
                    icon: QIcons.board,
                    tone: tone,
                    onAction: () {},
                    actionLabel: 'Crear',
                  ),
                  const SizedBox(height: QSpace.m),
                ],
                heading('Tarjetas'),
                const QuestlyCard(child: Text('Tarjeta · borde + 4 px')),
                const SizedBox(height: QSpace.l),
                QuestlyCard(
                  onTap: () => showQuestlyToast(context, 'Misión abierta'),
                  semanticsLabel: 'Lee un capítulo en voz alta',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Lee un capítulo en voz alta',
                          style: QText.body(q.text),
                        ),
                      ),
                      Text('+25 XP', style: QText.number(q.ink, size: 13)),
                    ],
                  ),
                ),
                heading('Botones'),
                QuestlyButton(
                  label: 'Principal',
                  onPressed: () => showQuestlyToast(context, 'Principal'),
                ),
                const SizedBox(height: QSpace.m),
                QuestlyButton(
                  label: 'Secundario',
                  variant: QuestlyButtonVariant.secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: QSpace.m),
                QuestlyButton(
                  label: 'Tonal',
                  variant: QuestlyButtonVariant.tonal,
                  onPressed: () {},
                ),
                const SizedBox(height: QSpace.m),
                QuestlyButton(
                  label: 'Destructivo',
                  variant: QuestlyButtonVariant.destructive,
                  onPressed: () {},
                ),
                const SizedBox(height: QSpace.m),
                const QuestlyButton(
                  label: 'Comprar',
                  disabledReason: 'Te faltan 20 Monedas',
                  onPressed: null,
                ),
                const SizedBox(height: QSpace.s),
                QuestlyButton(
                  label: 'Enlace de texto',
                  variant: QuestlyButtonVariant.text,
                  onPressed: () {},
                ),
                heading('Pestañas segmentadas'),
                QuestlySegmented<String>(
                  segments: const [
                    ('Hoy', 'Hoy'),
                    ('Calendario', 'Calendario'),
                    ('Biblioteca', 'Biblioteca'),
                  ],
                  selected: _tab,
                  onChanged: (v) => setState(() => _tab = v),
                ),
                heading('Chips'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final f in const ['Todas', 'Hoy', 'Urgentes'])
                      QuestlyFilterChip(
                        label: f,
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                    const QuestlyTagChip('Chip de Área'),
                    const QuestlyPriorityChip(QuestlyPriority.high),
                    const QuestlyPriorityChip(QuestlyPriority.medium),
                    const QuestlyPriorityChip(QuestlyPriority.low),
                  ],
                ),
                heading('Hoja, diálogo y toast'),
                QuestlyButton(
                  label: 'Abrir hoja inferior',
                  variant: QuestlyButtonVariant.secondary,
                  onPressed: () => showQuestlySheet<void>(
                    context,
                    title: 'Tu carrito',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Gastar Monedas nunca te quita progreso.',
                          style: QText.body(q.text),
                        ),
                        const SizedBox(height: QSpace.l),
                        QuestlyButton(
                          label: 'Entendido',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: QSpace.m),
                QuestlyButton(
                  label: 'Abrir diálogo',
                  variant: QuestlyButtonVariant.secondary,
                  onPressed: () => showQuestlyDialog<void>(
                    context,
                    title: '¿Cerrar sesión?',
                    message: 'Tu progreso queda guardado.',
                    actions: [
                      Builder(
                        builder: (context) => QuestlyButton(
                          label: 'Cerrar sesión',
                          variant: QuestlyButtonVariant.destructive,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: QSpace.m),
                QuestlyButton(
                  label: 'Mostrar toast con «Deshacer»',
                  variant: QuestlyButtonVariant.secondary,
                  onPressed: () => showQuestlyToast(
                    context,
                    'Tarea archivada',
                    onUndo: () => showQuestlyToast(context, 'Tarea restaurada'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
