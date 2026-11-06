import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/assistant/domain/entities/local_parser.dart';

void main() {
  // Jueves 5 nov 2026, 14:00.
  final now = DateTime(2026, 11, 5, 14);
  DateTime d(int day, [int h = 0, int m = 0]) => DateTime(2026, 11, day, h, m);

  test('gym mañana 6pm cada lunes', () {
    final r = LocalParser.parse('gym mañana 6pm cada lunes', now);
    expect(r.title, 'Gym');
    expect(r.scheduledAt, d(6, 18));
    expect(r.dueDate, d(6, 23, 59));
    expect(r.repeatRule, 'weekly:1');
    expect(r.reminderMinutes, 10);
  });

  test('llamar a mamá en 20 min', () {
    final r = LocalParser.parse('llamar a mamá en 20 min', now);
    expect(r.title, 'Llamar a mamá');
    expect(r.scheduledAt, d(5, 14, 20));
  });

  test('hora sin día: hoy si no ha pasado, si no mañana', () {
    expect(
      LocalParser.parse('leer a las 9 de la noche', now).scheduledAt,
      d(5, 21),
    );
    expect(LocalParser.parse('correr 07:30', now).scheduledAt, d(6, 7, 30));
    expect(LocalParser.parse('reunión a las 4', now).scheduledAt, d(5, 16));
  });

  test('día de la semana, fecha del mes y prioridad', () {
    final r = LocalParser.parse('Pagar la luz el 15, urgente', now);
    expect(r.title, 'Pagar la luz');
    expect(r.dueDate, d(15, 23, 59));
    expect(r.priority, 2);
    expect(r.scheduledAt, isNull);
    expect(r.reminderMinutes, isNull);

    expect(
      LocalParser.parse('dentista el martes 10am', now).scheduledAt,
      d(10, 10),
    );
    // Hoy es jueves: «el jueves» es el de la semana que viene.
    expect(LocalParser.parse('informe el jueves', now).dueDate, d(12, 23, 59));
    expect(
      LocalParser.parse('cita el 3', now).dueDate,
      DateTime(2026, 12, 3, 23, 59),
    );
  });

  test('repeticiones', () {
    expect(LocalParser.parse('agua todos los días', now).repeatRule, 'daily');
    expect(
      LocalParser.parse('standup entre semana 9am', now).repeatRule,
      'weekdays',
    );
    expect(
      LocalParser.parse(
        'inglés cada martes y jueves a las 7pm',
        now,
      ).repeatRule,
      'weekly:2,4',
    );
    // «cada jueves» sin fecha: hoy, porque hoy es jueves.
    expect(
      LocalParser.parse('yoga cada jueves 6pm', now).scheduledAt,
      d(5, 18),
    );
    expect(
      LocalParser.parse('arriendo cada mes el 1', now).repeatRule,
      'monthly:1',
    );
    expect(
      LocalParser.parse('revisar cada semana', now).repeatRule,
      'weekly:4',
    );
  });

  test('duración y aviso', () {
    final r = LocalParser.parse(
      'estudiar mañana 3pm durante 2 horas avísame 30 min antes',
      now,
    );
    expect(r.title, 'Estudiar');
    expect(r.estimatedMinutes, 120);
    expect(r.reminderMinutes, 30);
  });

  test('sin nada que entender devuelve el texto como título', () {
    final r = LocalParser.parse('comprar pan', now);
    expect(r.title, 'Comprar pan');
    expect(r.scheduledAt, isNull);
    expect(r.dueDate, isNull);
    expect(r.repeatRule, isNull);
    expect(LocalParser.parse('mañana', now).title, 'mañana');
  });
}
