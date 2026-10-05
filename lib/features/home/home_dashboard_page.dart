import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({
    super.key,
    required this.userName,
    required this.onNavigate,
  });

  final String userName;
  final ValueChanged<int> onNavigate;

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  final Set<int> _completedHabits = {0, 1};

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(19, 12, 19, 20),
    children: [
      _greeting(context),
      const SizedBox(height: 12),
      _levelCard(),
      const SizedBox(height: 14),
      LifeQuestSectionHeading(
        'MISIÓN PRIORITARIA',
        action: 'Ver todas',
        onTap: () => widget.onNavigate(1),
      ),
      const SizedBox(height: 7),
      _missionCard(context),
      const SizedBox(height: 13),
      LifeQuestSectionHeading(
        'HÁBITOS DE HOY',
        action: '🔥 12 días',
        onTap: () => widget.onNavigate(3),
      ),
      const SizedBox(height: 7),
      _habitStrip(),
      const SizedBox(height: 14),
      const LifeQuestSectionHeading('ACCESOS RÁPIDOS'),
      const SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: _quickAction(
              Icons.add_box_outlined,
              'Nueva tarea',
              () => widget.onNavigate(1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _quickAction(
              Icons.timer_outlined,
              'Modo focus',
              () => widget.onNavigate(2),
            ),
          ),
        ],
      ),
      const SizedBox(height: 7),
      Row(
        children: [
          Expanded(
            child: _quickAction(
              Icons.monitor_heart_outlined,
              'Registrar hábito',
              () => widget.onNavigate(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _quickAction(
              Icons.auto_awesome,
              'Game Master',
              () => widget.onNavigate(2),
            ),
          ),
        ],
      ),
    ],
  );

  Widget _greeting(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Martes, 29 de septiembre',
              style: TextStyle(
                color: LifeQuestColors.deepGreen,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Buenos días, ${widget.userName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 20,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Tu siguiente avance está listo.',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 10),
            ),
          ],
        ),
      ),
      const SizedBox(width: 7),
      IconButton(
        tooltip: 'Notificaciones',
        onPressed: () =>
            showLifeQuestMessage(context, 'No tienes notificaciones nuevas.'),
        icon: const Icon(Icons.notifications_none_rounded, size: 21),
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: LifeQuestColors.line),
        ),
      ),
      const SizedBox(width: 4),
      InkWell(
        onTap: () => widget.onNavigate(4),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: LifeQuestColors.green,
          child: Text(
            widget.userName.isEmpty ? 'A' : widget.userName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _levelCard() => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nivel 24 · Estratega',
                    style: TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '4,150 XP para subir de nivel',
                    style: TextStyle(color: LifeQuestColors.muted, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: LifeQuestColors.softGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                '◉ 2,450',
                style: TextStyle(
                  color: LifeQuestColors.deepGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progreso de XP',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '7,850 / 12,000',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const LinearProgressIndicator(
          value: .65,
          minHeight: 5,
          color: LifeQuestColors.green,
          backgroundColor: Color(0xFFE3EEE7),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        const SizedBox(height: 10),
        const Row(
          children: [
            Expanded(
              child: LifeQuestStat(value: '3 / 5', label: 'Misiones'),
            ),
            SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '2 / 3', label: 'Hábitos'),
            ),
            SizedBox(width: 7),
            Expanded(
              child: LifeQuestStat(value: '45 min', label: 'En foco'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _missionCard(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LifeQuestIconTile(Icons.verified_user_outlined),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preparar presentación del proyecto',
                    style: TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hoy · 18:00 · Alta prioridad',
                    style: TextStyle(
                      color: LifeQuestColors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const Expanded(
              child: Text(
                '⚡ 350 XP    ◉ 120',
                style: TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: FilledButton.icon(
                onPressed: () => widget.onNavigate(1),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Continuar'),
                style: FilledButton.styleFrom(
                  backgroundColor: LifeQuestColors.green,
                  visualDensity: VisualDensity.compact,
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _habitStrip() => LifeQuestSurface(
    padding: const EdgeInsets.all(7),
    child: Row(
      children: [
        _habitChip(0, 'Leer', Icons.menu_book_outlined),
        _habitChip(1, 'Ejercicio', Icons.fitness_center),
        _habitChip(2, 'Agua', Icons.water_drop_outlined),
      ],
    ),
  );

  Widget _habitChip(int index, String label, IconData icon) => Expanded(
    child: InkWell(
      onTap: () => setState(
        () => _completedHabits.contains(index)
            ? _completedHabits.remove(index)
            : _completedHabits.add(index),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: _completedHabits.contains(index)
              ? LifeQuestColors.softGreen
              : Colors.white,
          border: Border.all(color: LifeQuestColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(
              _completedHabits.contains(index) ? Icons.check_circle : icon,
              color: _completedHabits.contains(index)
                  ? LifeQuestColors.green
                  : LifeQuestColors.muted,
              size: 17,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: LifeQuestColors.line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              LifeQuestIconTile(icon, size: 27),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: LifeQuestColors.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
