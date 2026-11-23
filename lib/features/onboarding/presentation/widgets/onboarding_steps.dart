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
      Calindir(
        pose: 'hola',
        dice: '¡Hola! Soy Calindir. Te ayudo a que cada día cuente.',
      ),
      _Title('Bienvenido a Questly'),
      _Body('Lo que cumples en tu día se convierte en progreso visible.'),
      SizedBox(height: 20),
      LifeQuestSurface(
        padding: EdgeInsets.all(16),
        child: _Body('Tarea → XP → Nivel'),
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
      const Calindir(
        pose: 'anotar',
        dice:
            'Cuéntame qué quieres lograr. Lo uso para animarte, nunca para juzgarte.',
      ),
      const _Title('¿Qué quieres lograr este año?'),
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
      const Calindir(
        pose: 'habitos',
        dice:
            'Un área agrupa lo que haces: estudio, salud, trabajo… Elige la primera.',
      ),
      const _Title('¿Qué área de tu vida quieres hacer crecer?'),
      const _Body('Será tu primera área. Puedes dejarlo para después.'),
      const SizedBox(height: 16),
      TextField(
        controller: controller,
        maxLength: OnboardingChoices.skillMaxLength,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nombre de el área',
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
      const Calindir(
        pose: 'foco',
        dice: '¿Con cuánta exigencia quieres avanzar? Elige con calma.',
      ),
      const _Title('Elige tu dificultad'),
      const _Body('Cambia cuánta XP ganas. Lo puedes ajustar luego.'),
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
            child: _Body('Después solo podrás cambiarla en Ajustes.'),
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
    required this.aiEnabled,
    required this.onAiChanged,
  });

  final String identity;
  final String skill;
  final GameDifficulty difficulty;
  final bool aiEnabled;
  final ValueChanged<bool> onAiChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Calindir(
        pose: 'listo',
        dice: '¡Listo! Ya preparé tu espacio. Vamos por tu primer día.',
      ),
      const _Title('¡Todo listo!'),
      const _Body('Esto es lo que elegiste. Puedes cambiarlo cuando quieras.'),
      const SizedBox(height: 16),
      LifeQuestSurface(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row('Identidad', _or(identity, 'Sin identidad por ahora')),
            _Row('Área', _or(skill, 'Sin área por ahora')),
            _Row('Dificultad', difficultyName(difficulty)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      LifeQuestSurface(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SwitchListTile(
          value: aiEnabled,
          onChanged: onAiChanged,
          title: const Text('Asistente con IA'),
          subtitle: const Text(
            'Divide tus tareas en pasos y entiende frases como «gym '
            'mañana 6pm». Lo que escribes se envía a Gemini (Google); no '
            'pongas datos sensibles. Puedes apagarlo en Ajustes.',
          ),
        ),
      ),
    ],
  );

  static String _or(String value, String empty) =>
      value.trim().isEmpty ? empty : value.trim();
}

/// Calindir, la mascota de Questly, dice [dice] desde un globo. Solo
/// acompaña: no cambia qué se pregunta ni qué se guarda.
class Calindir extends StatelessWidget {
  const Calindir({super.key, required this.pose, required this.dice});

  /// Pose de `assets/images/guia/guia_<pose>.png`.
  final String pose;
  final String dice;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.asset(
              'assets/images/guia/guia_$pose.png',
              width: 96,
              height: 96,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Semantics(
            label: 'Calindir dice: $dice',
            excludeSemantics: true,
            child: CustomPaint(
              painter: _Pico(color: context.lq.surface, borde: context.lq.line),
              child: Container(
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: context.lq.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: context.lq.line),
                ),
                child: Text(
                  dice,
                  style: TextStyle(
                    color: context.lq.ink,
                    fontSize: 14,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Pico del globo, hacia Calindir (a la izquierda).
class _Pico extends CustomPainter {
  const _Pico({required this.color, required this.borde});

  final Color color;
  final Color borde;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final path = Path()
      ..moveTo(11, y - 8)
      ..lineTo(0, y)
      ..lineTo(11, y + 8);
    canvas
      ..drawPath(path, Paint()..color = color)
      ..drawPath(
        path,
        Paint()
          ..color = borde
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_Pico old) => old.color != color || old.borde != borde;
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
          fontWeight: FontWeight.w700,
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
