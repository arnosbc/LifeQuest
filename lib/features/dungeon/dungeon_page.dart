import 'dart:async';

import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';
import 'widgets/cycle_duration_card.dart';
import 'widgets/deep_work_session_card.dart';
import 'widgets/dungeon_timer_ring.dart';
import 'widgets/session_rewards_card.dart';

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
      DungeonTimerRing(
        remainingSeconds: _remainingSeconds,
        totalSeconds: 25 * 60,
      ),
      const SizedBox(height: 14),
      const CycleDurationCard(),
      const SizedBox(height: 9),
      const DeepWorkSessionCard(),
      const SizedBox(height: 9),
      const SessionRewardsCard(),
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
