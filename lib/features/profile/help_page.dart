import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
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
        _pageHeader(),
        const Divider(height: 18, color: LifeQuestColors.line),
        const Text(
          '¿Cómo podemos ayudarte?',
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Encuentra respuestas o habla con nuestro equipo.',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
        ),
        const SizedBox(height: 9),
        _searchField(),
        const SizedBox(height: 12),
        const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: _quickAccess(
                context,
                Icons.help_outline,
                'Preguntas frecuentes',
                'Respuestas más consultadas',
                _showFaqs,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _quickAccess(
                context,
                Icons.chat_bubble_outline,
                'Contactar soporte',
                'Respondemos en menos de 2 h',
                _contactSupport,
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        if (_query.isNotEmpty) ...[
          const LifeQuestSectionHeading('RESULTADOS DE AYUDA'),
          const SizedBox(height: 5),
          if (matches.isEmpty)
            const LifeQuestSurface(
              child: Text(
                'No encontramos resultados. Prueba con otra búsqueda.',
                style: TextStyle(color: LifeQuestColors.muted, fontSize: 10),
              ),
            )
          else
            ...matches.map((faq) => _faqTile(context, faq.$1, faq.$2)),
          const SizedBox(height: 9),
        ],
        const LifeQuestSectionHeading('RECURSOS Y LEGAL'),
        const SizedBox(height: 5),
        for (final resource in _resources)
          _resourceTile(context, resource.$1, resource.$2, resource.$3),
        const SizedBox(height: 3),
        LifeQuestSurface(
          color: const Color(0xFFEAF8EE),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.circle, color: LifeQuestColors.green, size: 7),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Todos los sistemas operativos',
                  style: TextStyle(color: LifeQuestColors.ink, fontSize: 9),
                ),
              ),
              InkWell(
                onTap: () => showLifeQuestMessage(
                  context,
                  'Todos los sistemas están operativos.',
                ),
                child: const Text(
                  'Ver estado',
                  style: TextStyle(
                    color: LifeQuestColors.deepGreen,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        const Center(
          child: Column(
            children: [
              Text(
                'Nexo para iOS',
                style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
              ),
              SizedBox(height: 2),
              Text(
                'Versión 6.4.1 (2418)',
                style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pageHeader() => Row(
    children: [
      InkWell(
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: LifeQuestColors.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.chevron_left,
            color: LifeQuestColors.muted,
            size: 18,
          ),
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Ayuda',
        style: TextStyle(
          color: LifeQuestColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );

  Widget _searchField() => TextField(
    controller: _searchController,
    onChanged: (value) => setState(() => _query = value.trim()),
    style: const TextStyle(color: LifeQuestColors.ink, fontSize: 10),
    decoration: InputDecoration(
      hintText: 'Buscar en Ayuda',
      hintStyle: const TextStyle(color: LifeQuestColors.muted, fontSize: 9),
      prefixIcon: const Icon(
        Icons.search,
        size: 16,
        color: LifeQuestColors.muted,
      ),
      suffixIcon: IconButton(
        tooltip: 'Buscar',
        onPressed: _showFaqs,
        icon: const Icon(
          Icons.keyboard_command_key,
          size: 15,
          color: LifeQuestColors.green,
        ),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LifeQuestColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: LifeQuestColors.line),
      ),
    ),
  );

  Widget _quickAccess(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: LifeQuestSurface(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LifeQuestIconTile(icon, size: 22),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: LifeQuestColors.ink,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: LifeQuestColors.muted,
              fontSize: 8,
              height: 1.3,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _resourceTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: InkWell(
      onTap: () => _showResource(context, title, subtitle),
      borderRadius: BorderRadius.circular(9),
      child: LifeQuestSurface(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          children: [
            LifeQuestIconTile(icon, size: 22),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: LifeQuestColors.muted,
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: LifeQuestColors.muted,
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _faqTile(BuildContext context, String question, String answer) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: LifeQuestSurface(
          padding: EdgeInsets.zero,
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 9),
            childrenPadding: const EdgeInsets.fromLTRB(9, 0, 9, 9),
            title: Text(
              question,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            children: [
              Text(
                answer,
                style: const TextStyle(
                  color: LifeQuestColors.muted,
                  fontSize: 9,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );

  void _showFaqs() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Preguntas frecuentes',
            style: TextStyle(
              color: LifeQuestColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final faq in _faqs) _faqTile(context, faq.$1, faq.$2),
        ],
      ),
    ),
  );

  void _contactSupport() => showLifeQuestMessage(
    context,
    'Escríbenos a soporte@lifequest.app. Respondemos en menos de 2 horas.',
  );

  void _showResource(BuildContext context, String title, String subtitle) =>
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(subtitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
}
