import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

class DungeonPage extends StatefulWidget {
  const DungeonPage({super.key});

  @override
  State<DungeonPage> createState() => _DungeonPageState();
}

class _DungeonPageState extends State<DungeonPage> {
  Timer? _timer;
  int _remainingSeconds = 25 * 60;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Mazmorra',
    subtitle: 'DEEP WORKING · Ciclo 2 / 4',
    children: [
      Center(
        child: SizedBox(
          width: 184,
          height: 184,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: _remainingSeconds / (25 * 60),
                  strokeWidth: 5,
                  backgroundColor: LifeQuestColors.line,
                  color: LifeQuestColors.deepGreen,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'TIEMPO RESTANTE',
                    style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
                  ),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: LifeQuestColors.softGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'MAZMORRA ACTIVA',
                      style: TextStyle(
                        color: LifeQuestColors.deepGreen,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sesión total: 1 h 45 m restante',
                    style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      LifeQuestSurface(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DURACIÓN DEL CICLO',
              style: TextStyle(
                color: LifeQuestColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                _duration('25 min', selected: true),
                _duration('30 min'),
                _duration('45 min'),
                _duration('5 min descanso'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 9),
      LifeQuestSurface(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SESIÓN DEEP WORKING',
              style: TextStyle(
                color: LifeQuestColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Estudiar para el parcial de Ingeniería de Software',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(
                  child: LifeQuestStat(value: '3 h', label: 'Duración total'),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: LifeQuestStat(value: '1 h 15 m', label: 'Completado'),
                ),
              ],
            ),
            const SizedBox(height: 11),
            const Text(
              'TAREAS ASIGNADAS · 3 tareas · 2 avanzadas',
              style: TextStyle(
                color: LifeQuestColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            _task('Revisar casos de uso y diagramas de secuencia', .75),
            _task('Resolver ejercicios de patrones de diseño', .4),
            _task('Repasar conceptos de testing y refactor', .2),
          ],
        ),
      ),
      const SizedBox(height: 9),
      LifeQuestSurface(
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RECOMPENSAS ESTIMADAS',
              style: TextStyle(
                color: LifeQuestColors.muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Row(
              children: [
                Expanded(
                  child: LifeQuestStat(value: '150 XP', label: 'XP ganada'),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: LifeQuestStat(value: '60 ◉', label: 'Monedas ganadas'),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Row(
              children: [
                Expanded(
                  child: LifeQuestStat(
                    value: '2 🔥',
                    label: 'Ciclos completados',
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: LifeQuestStat(
                    value: '1 h 15 m',
                    label: 'Tiempo efectivo',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 11),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _toggleTimer,
              icon: Icon(_running ? Icons.pause : Icons.play_arrow),
              label: Text(_running ? 'Pausar' : 'Continuar'),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _startBreak,
              icon: const Icon(Icons.skip_next),
              label: const Text('Saltar descanso'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: double.infinity,
        height: 42,
        child: FilledButton.icon(
          onPressed: _finishSession,
          icon: const Icon(Icons.stop),
          label: const Text('Finalizar sesión'),
          style: FilledButton.styleFrom(
            backgroundColor: LifeQuestColors.deepGreen,
          ),
        ),
      ),
    ],
  );

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _duration(String label, {bool selected = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: selected ? LifeQuestColors.softGreen : const Color(0xFFF6FAF7),
      border: Border.all(
        color: selected ? LifeQuestColors.deepGreen : LifeQuestColors.line,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: LifeQuestColors.deepGreen,
        fontSize: 9,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _task(String title, double progress) => Container(
    margin: const EdgeInsets.only(top: 7),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: LifeQuestColors.background,
      border: Border.all(color: LifeQuestColors.line),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: LifeQuestColors.deepGreen,
                backgroundColor: LifeQuestColors.line,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '${(progress * 4).ceil()}/4',
              style: const TextStyle(color: LifeQuestColors.muted, fontSize: 9),
            ),
          ],
        ),
      ],
    ),
  );

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _running = false;
        });
        showLifeQuestMessage(context, '¡Ciclo completado! Toma un descanso.');
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _startBreak() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 5 * 60;
      _running = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 25 * 60;
          _running = false;
        });
        showLifeQuestMessage(context, 'Descanso completado.');
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _finishSession() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remainingSeconds = 25 * 60;
    });
    showLifeQuestMessage(context, 'Sesión finalizada. ¡Buen trabajo!');
  }
}
