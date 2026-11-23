import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/tasks/presentation/widgets/tasks_format.dart';

void main() {
  final now = DateTime(2026, 11, 22, 15);

  test('con hora muestra el día y la hora', () {
    expect(TasksFormat.due(DateTime(2026, 11, 22, 18), now), 'Hoy · 18:00');
    expect(
      TasksFormat.due(DateTime(2026, 11, 23, 9, 30), now),
      'Mañana · 09:30',
    );
    expect(TasksFormat.time(DateTime(2026, 11, 22, 18)), '18:00');
  });

  test('solo con día (23:59 interno) no muestra la hora', () {
    expect(TasksFormat.due(DateTime(2026, 11, 22, 23, 59), now), 'Hoy');
    expect(TasksFormat.due(DateTime(2026, 11, 23, 23, 59), now), 'Mañana');
    expect(TasksFormat.due(DateTime(2026, 11, 27, 23, 59), now), '27 nov');
    expect(TasksFormat.time(DateTime(2026, 11, 22, 23, 59)), '');
  });
}
