import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';

// shortcut: textos provisionales hasta que exista PRODUCT.md.

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Title('Bienvenido a LifeQuest'),
      _Body('Tu progreso real hace progresar a tu personaje.'),
      SizedBox(height: 20),
      LifeQuestSurface(
        padding: EdgeInsets.all(16),
        child: _Body('Tarea → XP y Monedas → Nivel'),
      ),
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
      const _Title('¿Quién eres en este reino?'),
      const _Body('Puedes dejarlo para después.'),
      const SizedBox(height: 16),
      TextField(
        controller: controller,
        maxLength: OnboardingChoices.identityMaxLength,
        minLines: 3,
        maxLines: 5,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Tu identidad',
          hintText: 'Ej.: Una estratega que termina lo que empieza.',
          border: OutlineInputBorder(),
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
      const _Title('¿Qué área de tu vida quieres hacer crecer?'),
      const _Body('Será tu primera skill. Puedes dejarlo para después.'),
      const SizedBox(height: 16),
      TextField(
        controller: controller,
        maxLength: OnboardingChoices.skillMaxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nombre de la skill',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 8),
      // Escucha el campo para marcar la sugerencia que coincide.
      ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final name in suggestions)
              ChoiceChip(
                label: Text(name),
                selected: controller.text.trim() == name,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                onSelected: (_) => controller.value = TextEditingValue(
                  text: name,
                  selection: TextSelection.collapsed(offset: name.length),
                ),
              ),
          ],
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
      const _Title('Elige tu dificultad'),
      if (DifficultyPicker.sameCoins(options))
        const _Body('Las Monedas son iguales en las tres.'),
      const SizedBox(height: 16),
      DifficultyPicker(
        options: options,
        selected: selected,
        onSelected: onSelected,
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: context.lq.muted),
          const SizedBox(width: 6),
          const Expanded(
            child: _Body('Después solo podrás cambiarla en Configuración.'),
          ),
        ],
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
      const _Title('¡Todo listo!'),
      const _Body('Esto es lo que elegiste. Puedes cambiarlo cuando quieras.'),
      const SizedBox(height: 16),
      LifeQuestSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row('Identidad', _or(identity, 'Sin identidad por ahora')),
            _Row('Skill', _or(skill, 'Sin skill por ahora')),
            _Row('Dificultad', difficultyName(difficulty)),
          ],
        ),
      ),
    ],
  );

  static String _or(String value, String empty) =>
      value.trim().isEmpty ? empty : value.trim();
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          color: context.lq.ink,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(color: context.lq.muted, fontSize: 14));
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(color: context.lq.muted)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: context.lq.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
