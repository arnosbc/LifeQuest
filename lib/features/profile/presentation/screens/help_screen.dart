import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/faq_tile.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/help_quick_access_card.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/help_resource_tile.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/help_search_field.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/subpage_header.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/system_status_banner.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _resources = [
    (
      'Reportar un problema',
      'Envíanos detalles y capturas',
      Icons.bug_report_outlined,
    ),
    ('Privacidad', 'Cómo protegemos tus datos', Icons.verified_user_outlined),
    (
      'Términos y condiciones',
      'Condiciones de uso del servicio',
      Icons.description_outlined,
    ),
  ];

  static const _faqs = [
    (
      '¿Cómo completo un hábito?',
      'Entra en Hábitos y toca el círculo del hábito que hayas realizado. Tu progreso se actualizará al instante.',
    ),
    (
      '¿Cómo funciona la racha?',
      'La racha cuenta los días consecutivos en los que registras tus hábitos. Si necesitas un descanso, puedes ajustar tu rutina.',
    ),
    (
      '¿Cómo gano experiencia?',
      'Completa misiones, registra hábitos y termina sesiones de concentración para recibir XP.',
    ),
    (
      '¿Cómo cambio mi apariencia?',
      'Abre Perfil y selecciona Apariencia para cambiar el tema, el color y las preferencias de visualización.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matches = _faqs
        .where((faq) => faq.$1.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
      children: [
        SubpageHeader(title: 'Ayuda', onBack: widget.onBack),
        Divider(height: 18, color: context.lq.line),
        Text(
          '¿Cómo podemos ayudarte?',
          style: TextStyle(
            color: context.lq.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Encuentra respuestas o habla con nuestro equipo.',
          style: TextStyle(color: context.lq.muted, fontSize: 9),
        ),
        const SizedBox(height: 9),
        HelpSearchField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value.trim()),
          onShowAll: _showFaqs,
        ),
        const SizedBox(height: 12),
        const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: HelpQuickAccessCard(
                icon: Icons.help_outline,
                title: 'Preguntas frecuentes',
                subtitle: 'Respuestas más consultadas',
                onTap: _showFaqs,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: HelpQuickAccessCard(
                icon: Icons.chat_bubble_outline,
                title: 'Contactar soporte',
                subtitle: 'Respondemos en menos de 2 h',
                onTap: _contactSupport,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        if (_query.isNotEmpty) ...[
          const LifeQuestSectionHeading('RESULTADOS DE AYUDA'),
          const SizedBox(height: 5),
          if (matches.isEmpty)
            LifeQuestSurface(
              child: Text(
                'No encontramos resultados. Prueba con otra búsqueda.',
                style: TextStyle(color: context.lq.muted, fontSize: 10),
              ),
            )
          else
            for (final (question, answer) in matches)
              FaqTile(question: question, answer: answer),
          const SizedBox(height: 9),
        ],
        const LifeQuestSectionHeading('RECURSOS Y LEGAL'),
        const SizedBox(height: 5),
        for (final (title, subtitle, icon) in _resources)
          HelpResourceTile(title: title, subtitle: subtitle, icon: icon),
        const SizedBox(height: 3),
        const SystemStatusBanner(),
        const SizedBox(height: 9),
        Center(
          child: Column(
            children: [
              Text(
                'Nexo para iOS',
                style: TextStyle(color: context.lq.muted, fontSize: 8),
              ),
              SizedBox(height: 2),
              Text(
                'Versión 6.4.1 (2418)',
                style: TextStyle(color: context.lq.muted, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showFaqs() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Preguntas frecuentes',
            style: TextStyle(
              color: context.lq.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final (question, answer) in _faqs)
            FaqTile(question: question, answer: answer),
        ],
      ),
    ),
  );

  void _contactSupport() => showLifeQuestMessage(
    context,
    'Escríbenos a soporte@lifequest.app. Respondemos en menos de 2 horas.',
  );
}
