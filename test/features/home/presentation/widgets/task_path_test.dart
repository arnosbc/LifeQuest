import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/task_path.dart';

HomeDashboard _dash({
  int done = 0,
  PriorityMission? current,
  List<TodayTask> today = const [],
  DailyChest chest = const DailyChest(),
}) => HomeDashboard(
  level: 1,
  currentXp: 0,
  xpToNextLevel: 100,
  coins: 0,
  hpCurrent: 100,
  hpMax: 100,
  isWeakened: false,
  habits: const [],
  habitsDone: 0,
  habitsTotal: 0,
  streakDays: 0,
  missionsDone: done,
  missionsTotal: done,
  focusMinutes: 0,
  priorityMission: current,
  todayTasks: today,
  chest: chest,
);

const _current = PriorityMission(
  id: 'a',
  title: 'Informe',
  priority: UrgencyLevel.high,
  xpReward: 30,
  coinReward: 9,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<(List<String>, List<String>)> pump(
    WidgetTester tester,
    HomeDashboard d, {
    VoidCallback? onClaim,
  }) async {
    final focused = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TaskPath(
              dashboard: d,
              claimingChest: false,
              onFocus: focused.add,
              onClaimChest: onClaim ?? () {},
            ),
          ),
        ),
      ),
    );
    final states = tester
        .widgetList<QuestPathNode>(find.byType(QuestPathNode))
        .map((n) => '${n.state.name}:${n.label}')
        .toList();
    return (states, focused);
  }

  testWidgets('hecho, actual, siguientes sin repetir la actual y cofre', (
    tester,
  ) async {
    final (states, focused) = await pump(
      tester,
      _dash(
        done: 2,
        current: _current,
        today: const [
          TodayTask(
            id: 'a',
            title: 'Informe',
            priority: UrgencyLevel.high,
            xpReward: 30,
          ),
          TodayTask(
            id: 'b',
            title: 'Leer',
            priority: UrgencyLevel.low,
            xpReward: 10,
          ),
        ],
      ),
    );
    expect(states, [
      'done:2 tareas hechas hoy',
      'current:Informe',
      'next:Leer',
      'locked:Cofre del día',
    ]);
    // Nodos: hecho (0), actual (1), siguiente «Leer» (2).
    await tester.tap(find.byType(QuestlyPressable).at(2));
    expect(focused, ['b']);
  });

  testWidgets('el cofre listo se cobra al tocarlo', (tester) async {
    var claims = 0;
    final (states, _) = await pump(
      tester,
      _dash(chest: const DailyChest(progress: 3)),
      onClaim: () => claims++,
    );
    expect(states, ['done:¡Abre tu cofre!']);
    await tester.tap(find.byType(QuestlyPressable));
    expect(claims, 1);
  });
}
