import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/assistant/domain/entities/area_suggester.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';

void main() {
  const salud = DraftArea(id: '1', name: 'Salud');
  const trabajo = DraftArea(id: '2', name: 'Trabajo');
  const estudio = DraftArea(id: '3', name: 'Estudio');
  const areas = [salud, trabajo, estudio];

  test('sin áreas no sugiere nada', () {
    expect(AreaSuggester.suggest('correr 5 km', const [], const []), isNull);
  });

  test('el título nombra el área (sin acentos ni mayúsculas)', () {
    expect(
      AreaSuggester.suggest('Ir al SALUD check', areas, const []),
      salud,
    );
    const musica = DraftArea(id: '4', name: 'Música');
    expect(
      AreaSuggester.suggest('musica para estudiar', [musica], const []),
      musica,
    );
  });

  test('si el título nombra dos áreas a la vez, no sugiere', () {
    expect(
      AreaSuggester.suggest('trabajo y salud', [salud, trabajo], const []),
      isNull,
    );
  });

  test('usa tareas anteriores del área cuando comparten 2 palabras', () {
    final history = [
      (title: 'preparar presentación comercial', areaName: 'Trabajo'),
      (title: 'revisar presentación cliente', areaName: 'Trabajo'),
    ];
    expect(
      AreaSuggester.suggest('presentación para cliente', areas, history),
      trabajo,
    );
  });

  test('una sola palabra compartida no basta', () {
    final history = [(title: 'comprar pan', areaName: 'Salud')];
    expect(AreaSuggester.suggest('comprar lentes', areas, history), isNull);
  });

  test('empate entre áreas no sugiere nada', () {
    final history = [
      (title: 'llamar banco', areaName: 'Salud'),
      (title: 'llamar banco', areaName: 'Trabajo'),
    ];
    expect(
      AreaSuggester.suggest('llamar banco hoy', [salud, trabajo], history),
      isNull,
    );
  });

  test('palabras cortas no cuentan', () {
    final history = [(title: 'ir de la casa', areaName: 'Salud')];
    expect(
      AreaSuggester.suggest('ir de la oficina', areas, history),
      isNull,
    );
  });
}
