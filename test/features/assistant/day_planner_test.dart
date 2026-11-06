import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/assistant/domain/entities/day_planner.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';

void main() {
  // Jueves 5 nov 2026, 9:10.
  final now = DateTime(2026, 11, 5, 9, 10);
  DateTime at(int h, [int m = 0, int day = 5]) => DateTime(2026, 11, day, h, m);

  group('planDay', () {
    test('ordena vencidas → prioridad → fecha y llena desde ahora', () {
      final plan = DayPlanner.planDay([
        PlanTask(id: 'baja', title: 'Baja', due: at(20)),
        PlanTask(id: 'alta', title: 'Alta', priority: 2, minutes: 60),
        PlanTask(id: 'vencida', title: 'Vencida', due: at(8, 0, 4)),
        PlanTask(id: 'media-pronto', title: 'M1', priority: 1, due: at(12)),
        PlanTask(id: 'media-tarde', title: 'M2', priority: 1, due: at(18)),
      ], now);
      expect(plan.blocks.map((b) => (b.taskId, b.start)), [
        ('vencida', at(9, 15)),
        ('alta', at(9, 45)),
        ('media-pronto', at(10, 45)),
        ('media-tarde', at(11, 15)),
        ('baja', at(11, 45)),
      ]);
      expect(plan.left, isEmpty);
    });

    test('esquiva bloques puestos y eventos, y no mueve lo que tiene hora', () {
      final plan = DayPlanner.planDay(
        [
          PlanTask(id: 'puesta', title: 'P', scheduledAt: at(9, 30)),
          const PlanTask(id: 'nueva', title: 'N', minutes: 45),
        ],
        now,
        events: [Busy(at(10), at(11))],
      );
      // 9:15–10:00 choca con la puesta (9:30–10:00) y luego con el evento.
      expect(plan.blocks.single.taskId, 'nueva');
      expect(plan.blocks.single.start, at(11));
    });

    test('lo que no cabe antes de las 22:00 queda fuera', () {
      final plan = DayPlanner.planDay([
        const PlanTask(id: 'larga', title: 'L', minutes: 120),
      ], DateTime(2026, 11, 5, 20, 30));
      expect(plan.blocks, isEmpty);
      expect(plan.left.single.id, 'larga');
    });

    test('antes de las 8:00 empieza a las 8:00', () {
      final plan = DayPlanner.planDay([
        const PlanTask(id: 'a', title: 'A'),
      ], DateTime(2026, 11, 5, 6, 40));
      expect(plan.blocks.single.start, at(8));
    });
  });

  group('replan', () {
    test('mueve bloques pasados y vencidas sin hora; respeta lo futuro', () {
      final plan = DayPlanner.replan([
        PlanTask(id: 'pasada', title: 'P', scheduledAt: at(8), minutes: 30),
        PlanTask(id: 'vencida', title: 'V', due: at(23, 0, 4)),
        PlanTask(id: 'futura', title: 'F', scheduledAt: at(9, 15)),
        PlanTask(id: 'sin-fecha', title: 'S'),
        // En curso (9:00–9:30): no se mueve.
        PlanTask(id: 'en-curso', title: 'C', scheduledAt: at(9)),
      ], now);
      expect(plan.mode, PlanMode.replan);
      expect(plan.blocks.map((b) => (b.taskId, b.start)), [
        ('vencida', at(9, 45)),
        ('pasada', at(10, 15)),
      ]);
    });

    test('si hoy no queda hueco, pasa a mañana', () {
      final plan = DayPlanner.replan([
        PlanTask(id: 'pasada', title: 'P', scheduledAt: at(8), minutes: 60),
      ], DateTime(2026, 11, 5, 21, 30));
      expect(plan.blocks.single.start, at(8, 0, 6));
    });
  });

  group('spreadDates', () {
    test('reparte de mañana a la fecha límite, al final del día', () {
      expect(DayPlanner.spreadDates(3, now, deadline: at(10, 0, 15)), [
        DateTime(2026, 11, 6, 23, 59),
        DateTime(2026, 11, 11, 23, 59),
        DateTime(2026, 11, 15, 23, 59),
      ]);
    });

    test('sin fecha límite, una por día; con plazo corto se juntan', () {
      expect(DayPlanner.spreadDates(2, now).map((d) => d.day), [6, 7]);
      expect(DayPlanner.spreadDates(3, now, deadline: now).map((d) => d.day), [
        6,
        6,
        6,
      ]);
      expect(DayPlanner.spreadDates(0, now), isEmpty);
    });
  });
}
