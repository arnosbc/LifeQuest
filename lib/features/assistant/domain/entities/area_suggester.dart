import 'dart:math' as math;

import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';

/// Sugiere el área de una tarea por reglas, sin IA ni datos nuevos.
/// 1) El título nombra el área («Salud: correr» → Salud).
/// 2) Si no, comparte al menos 2 palabras con tareas anteriores de esa área.
/// Empate o nada claro → null (no se pone área).
class AreaSuggester {
  const AreaSuggester._();

  static DraftArea? suggest(
    String title,
    List<DraftArea> areas,
    List<({String title, String areaName})> history,
  ) {
    if (areas.isEmpty) return null;
    final words = _tokens(title);

    final named = [
      for (final a in areas)
        if (_tokens(a.name) case final t
            when t.isNotEmpty && t.every(words.contains))
          a,
    ];
    if (named.isNotEmpty) return _unique(named, (a) => _tokens(a.name).length);

    final scores = <DraftArea, int>{};
    for (final a in areas) {
      final past = {
        for (final h in history)
          if (_norm(h.areaName) == _norm(a.name)) ..._tokens(h.title),
      };
      scores[a] = words.intersection(past).length;
    }
    final best = scores.values.fold(0, math.max);
    if (best < 2) return null;
    return _unique(
      [for (final e in scores.entries) if (e.value == best) e.key],
      (_) => 0,
    );
  }

  /// El único con mayor puntaje; si dos empatan, null.
  static DraftArea? _unique(List<DraftArea> list, int Function(DraftArea) s) {
    if (list.isEmpty) return null;
    final top = list.map(s).fold(0, math.max);
    final leaders = list.where((a) => s(a) == top).toList();
    return leaders.length == 1 ? leaders.single : null;
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp('[áàä]'), 'a')
      .replaceAll(RegExp('[éèë]'), 'e')
      .replaceAll(RegExp('[íìï]'), 'i')
      .replaceAll(RegExp('[óòö]'), 'o')
      .replaceAll(RegExp('[úùü]'), 'u')
      .replaceAll('ñ', 'n');

  /// Palabras de 3 letras o más; las cortas («de», «la») no dicen nada.
  static Set<String> _tokens(String s) => _norm(s)
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.length >= 3)
      .toSet();
}
