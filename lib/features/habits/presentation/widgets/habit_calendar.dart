import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Mapa de calor del mes (Habitos.dc.html): 4 intensidades según cuántos
/// hábitos buenos se cumplieron cada día, con su leyenda. La semana empieza
/// en lunes. El color nunca va solo: cada día dice su cifra a TalkBack.
class HabitCalendar extends StatelessWidget {
  const HabitCalendar({super.key, required this.month, required this.heat});

  final DateTime month;

  /// Día del mes → hábitos buenos cumplidos.
  final Map<int, int> heat;

  static const _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// 0 · 1 · 2 · 3 o más.
  static Color _shade(QuestlyPalette q, int n) => switch (n) {
    0 => q.track,
    1 => Color.alphaBlend(q.accent.withValues(alpha: .35), q.card),
    2 => Color.alphaBlend(q.accent.withValues(alpha: .65), q.card),
    _ => q.accent,
  };

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Columna del día 1 con la semana en lunes (weekday 1 → 0).
    final offset = DateTime(month.year, month.month).weekday - 1;
    final cells = offset + daysInMonth;
    final active = heat.values.where((n) => n > 0).length;
    return QuestlyCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Mapa de calor · ${_months[month.month - 1]}',
              style: QText.title3(q.text).copyWith(fontSize: 17),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$active ${active == 1 ? 'día' : 'días'} con hábitos cumplidos',
            style: QText.body(q.text2).copyWith(fontSize: 13),
          ),
          const SizedBox(height: QSpace.m),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final d in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
                  Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: QText.body(q.text2).copyWith(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < cells; i++)
                if (i < offset)
                  const SizedBox.shrink()
                else
                  _cell(context, i - offset + 1),
            ],
          ),
          const SizedBox(height: QSpace.m),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Menos',
                  style: QText.body(q.text2).copyWith(fontSize: 12),
                ),
                for (var n = 0; n < 4; n++)
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: _shade(q, n),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                const SizedBox(width: 4),
                Text('Más', style: QText.body(q.text2).copyWith(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, int day) {
    final q = context.q;
    final n = heat[day] ?? 0;
    final today = day == month.day;
    final strong = n >= 2;
    return Semantics(
      label: n == 0
          ? 'Día $day: sin hábitos'
          : 'Día $day: $n ${n == 1 ? 'hábito' : 'hábitos'}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(
          color: _shade(q, n),
          borderRadius: BorderRadius.circular(8),
          border: today ? Border.all(color: q.text, width: 2) : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: QText.label(
            strong ? q.onAccent : q.text,
          ).copyWith(fontSize: 11),
        ),
      ),
    );
  }
}
