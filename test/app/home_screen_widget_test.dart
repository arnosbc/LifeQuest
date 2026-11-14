import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/home_screen_widget.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

void main() {
  test('los enlaces del widget llevan a la pantalla correcta', () {
    expect(
      HomeScreenWidget.routeFor(Uri.parse('lifequest://focus?task=t1')),
      RoutePaths.focusOn('t1'),
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
