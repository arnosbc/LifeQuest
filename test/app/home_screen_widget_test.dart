import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/home_screen_widget.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

void main() {
  const taskId = '7f1c2b0e-4a5d-4e2f-9b1a-3c4d5e6f7a8b';

  test('los enlaces del widget llevan a la pantalla correcta', () {
    expect(
      HomeScreenWidget.routeFor(Uri.parse('lifequest://focus?task=$taskId')),
      RoutePaths.focusOn(taskId),
    );
    expect(
      HomeScreenWidget.routeFor(Uri.parse('lifequest://focus')),
      RoutePaths.dungeon,
    );
    expect(
      HomeScreenWidget.routeFor(Uri.parse('lifequest://home')),
      RoutePaths.home,
    );
    expect(HomeScreenWidget.routeFor(Uri.parse('https://x.com')), isNull);
    expect(HomeScreenWidget.routeFor(null), isNull);
  });

  // H-05 (OWASP M4): cualquier app puede abrir lifequest://focus?task=…; solo
  // un UUID llega como id de tarea, lo demás abre Foco sin tarea.
  test('H-05: un id de tarea que no es UUID no llega a la ruta', () {
    for (final evil in [
      "1' OR '1'='1",
      '../../admin',
      'abc&task=otra',
      '%00',
      'x' * 5000,
    ]) {
      final uri = Uri(
        scheme: 'lifequest',
        host: 'focus',
        queryParameters: {'task': evil},
      );
      expect(HomeScreenWidget.routeFor(uri), RoutePaths.dungeon, reason: evil);
    }
  });
  HomeDashboard dash({
    int done = 0,
    int total = 0,
    int chest = 0,
    int tasks = 0,
  }) => HomeDashboard(
    level: 1,
    currentXp: 0,
    xpToNextLevel: 100,
    coins: 0,
    hpCurrent: 100,
    hpMax: 100,
    isWeakened: false,
    habits: const [],
    habitsDone: done,
    habitsTotal: total,
    streakDays: 3,
    missionsDone: 0,
    missionsTotal: 0,
    focusMinutes: 0,
    todayTasks: [
      for (var i = 0; i < tasks; i++)
        TodayTask(
          id: '$i',
          title: 't',
          priority: UrgencyLevel.low,
          xpReward: 10,
        ),
    ],
    chest: DailyChest(progress: chest),
  );

  test('datos del ánimo de la mascota', () {
    expect(HomeScreenWidget.dayKey(DateTime(2026, 3, 7)), '2026-03-07');
    // Con hábitos manda la racha; sin hábitos, el cofre.
    expect(HomeScreenWidget.dayDone(dash(done: 2, total: 2)), isTrue);
    expect(
      HomeScreenWidget.dayDone(dash(done: 1, total: 2, chest: 3)),
      isFalse,
    );
    expect(HomeScreenWidget.dayDone(dash(chest: 3)), isTrue);
    expect(HomeScreenWidget.dayDone(dash(chest: 2)), isFalse);
    expect(HomeScreenWidget.pending(dash(done: 1, total: 3, tasks: 2)), 4);
  });
}
