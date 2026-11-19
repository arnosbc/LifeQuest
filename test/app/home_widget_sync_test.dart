import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/app/home_widget_sync.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

import '../features/home/home_fixtures.dart';

void main() {
  test('dayKey: fecha local que entiende LocalDate.parse', () {
    expect(HomeWidgetSync.dayKey(DateTime(2026, 3, 7, 23, 59)), '2026-03-07');
  });

  test('dayDone: hay algo para hoy y todo está hecho', () {
    // Sin nada para hoy no hay día que cumplir.
    expect(HomeWidgetSync.dayDone(emptyDashboard), isFalse);
    // 3/5 tareas y 1/2 hábitos.
    expect(HomeWidgetSync.dayDone(dashboard), isFalse);
    const allDone = HomeDashboard(
      level: 1,
      currentXp: 0,
      xpToNextLevel: 100,
      coins: 0,
      hpCurrent: 100,
      hpMax: 100,
      isWeakened: false,
      habits: [],
      habitsDone: 2,
      habitsTotal: 2,
      streakDays: 3,
      tasksDone: 4,
      tasksTotal: 4,
      focusMinutes: 0,
    );
    expect(HomeWidgetSync.dayDone(allDone), isTrue);
  });
}
