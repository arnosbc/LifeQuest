import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';

// Textos de PRODUCT.md v2 y plan-funcionalidades-asistente.md §3.1 (sin fantasía).

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  static const _promises = [
    (
      QIcons.focus,
      'Tareas que suman',
      'Cada tarea completada te da XP y Monedas.',
    ),
    (
      QIcons.flag,
      'Metas con avance visible',
      'Cada paso acerca tu meta al 100 %.',
    ),
    (QIcons.leaf, 'Sin culpa', 'Si fallas un día, descansas y sigues.'),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Heading(
        kicker: 'Bienvenido a LifeQuest',
        title: 'Organiza, avanza y ve cómo creces',
        lead:
            'Soy tu Asistente. Te ayudo a convertir lo que quieres lograr en '
            'pasos concretos y a ver tu progreso real.',
      ),
      for (final (icon, title, text) in _promises) ...[
        const SizedBox(height: QSpace.s),
        _Promise(icon: icon, title: title, text: text),
      ],
    ],
  );
}

class IdentityStep extends StatelessWidget {
  const IdentityStep({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Heading(
        kicker: 'Tu propósito',
        title: '¿En quién te quieres convertir?',
        lead:
            'Una frase que te recuerde para qué haces esto. Puedes dejarlo '
            'para después.',
      ),
      const SizedBox(height: QSpace.l),
      TextField(
        controller: controller,
        maxLength: OnboardingChoices.identityMaxLength,
        minLines: 3,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        style: QText.body(context.q.text).copyWith(fontSize: 16),
        decoration: _fieldDecoration(
          context,
          label: 'Tu propósito',
          hint: 'Ej.: Una persona que termina lo que empieza.',
        ),
      ),
    ],
  );
}

class SkillStep extends StatelessWidget {
  const SkillStep({super.key, required this.controller});

  static const suggestions = [
    'Salud',
    'Estudio',
    'Trabajo',
    'Hogar',
    'Creatividad',
    'Relaciones',
  ];

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Heading(
        kicker: 'Tu primera área',
        title: '¿Qué quieres hacer crecer?',
        lead:
            'Lo que completes en esta área la hará subir de nivel. Puedes '
            'dejarlo para después y añadir más luego.',
      ),
      const SizedBox(height: QSpace.l),
      // Escucha el campo para marcar la sugerencia que coincide.
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Wrap(
          spacing: QSpace.s,
          runSpacing: QSpace.s,
          children: [
            for (final name in suggestions)
              QuestlyFilterChip(
                label: name,
                selected: controller.text.trim() == name,
                onTap: () => controller.value = TextEditingValue(
                  text: name,
                  selection: TextSelection.collapsed(offset: name.length),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: QSpace.m),
      TextField(
        controller: controller,
        maxLength: OnboardingChoices.skillMaxLength,
        textCapitalization: TextCapitalization.sentences,
        style: QText.body(context.q.text).copyWith(fontSize: 16),
        decoration: _fieldDecoration(
          context,
          label: 'Nombre del área',
          hint: 'O escribe la tuya: ej. Guitarra',
        ),
      ),
    ],
  );
}

class DifficultyStep extends StatelessWidget {
  const DifficultyStep({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<DifficultyOption> options;
  final GameDifficulty selected;
  final ValueChanged<GameDifficulty> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Heading(
        kicker: 'Tu ritmo',
        title: '¿A qué ritmo quieres avanzar?',
        lead: DifficultyPicker.sameCoins(options)
            ? 'Cambia cuánta XP ganas y cuánta Constancia pierdes. Las Monedas '
                  'son iguales en los tres.'
            : 'Cambia cuánta XP ganas y cuánta Constancia pierdes.',
      ),
      const SizedBox(height: QSpace.l),
      DifficultyPicker(
        options: options,
        selected: selected,
        onSelected: onSelected,
      ),
      const SizedBox(height: QSpace.xs),
      Text(
        'Después solo podrás cambiarlo en Ajustes.',
        style: QText.body(context.q.text2).copyWith(fontSize: 13),
      ),
    ],
  );
}

class SummaryStep extends StatelessWidget {
  const SummaryStep({
    super.key,
    required this.identity,
    required this.skill,
    required this.difficulty,
  });

  final String identity;
  final String skill;
  final GameDifficulty difficulty;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _Heading(
        kicker: 'Todo listo',
        title: '¡Tu cuenta está lista!',
        lead: 'Esto es lo que elegiste. Puedes cambiarlo cuando quieras.',
      ),
      const SizedBox(height: QSpace.l),
      QuestlyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row('Propósito', _or(identity, 'Sin propósito por ahora')),
            _Row('Área', _or(skill, 'Sin área por ahora')),
            _Row('Ritmo', difficultyName(difficulty)),
          ],
        ),
      ),
    ],
  );

  static String _or(String value, String empty) =>
      value.trim().isEmpty ? empty : value.trim();
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
  required String hint,
}) {
  final q = context.q;
  OutlineInputBorder border(Color color, [double width = 1.5]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(QRadius.button),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: QText.label(q.text2),
    hintStyle: QText.body(q.text2),
    filled: true,
    fillColor: q.card,
    enabledBorder: border(q.inputBorder),
    focusedBorder: border(q.ink, 2),
  );
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.kicker,
    required this.title,
    required this.lead,
  });

  final String kicker;
  final String title;
  final String lead;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker.toUpperCase(), style: QText.meta(q.ink)),
        const SizedBox(height: 6),
        Semantics(
          header: true,
          child: Text(
            title,
            style: QText.title1(q.text).copyWith(fontSize: 28, height: 1.12),
          ),
        ),
        const SizedBox(height: 6),
        Text(lead, style: QText.body(q.text2)),
      ],
    );
  }
}

class _Promise extends StatelessWidget {
  const _Promise({required this.icon, required this.title, required this.text});

  final QIcons icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QuestlyCard(
      padding: const EdgeInsets.all(QSpace.m),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: q.tint,
              borderRadius: BorderRadius.circular(QRadius.control),
            ),
            alignment: Alignment.center,
            child: QIcon(icon, color: q.ink),
          ),
          const SizedBox(width: QSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: QText.label(q.text).copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(text, style: QText.body(q.text2).copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: QText.body(q.text2))),
          Expanded(child: Text(value, style: QText.label(q.text))),
        ],
      ),
    );
  }
}
