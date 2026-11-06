import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';

/// Entiende notas cortas en español sin IA: «gym mañana 6pm cada lunes»,
/// «llamar a mamá en 20 min», «pagar luz el 15 cada mes, urgente».
/// Lo que reconoce se quita del título.
abstract final class LocalParser {
  static const _days =
      r'(lunes|martes|mi[eé]rcoles|jueves|viernes|s[aá]bados?|domingos?)';
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
  static const _unit = r'(min(?:utos?)?|h(?:oras?)?)';

  static RegExp _re(String p) => RegExp(p, caseSensitive: false);

  static TaskDraft parse(String text, DateTime now) {
    var rest = ' ${text.trim()} ';
    String? take(RegExp re, void Function(RegExpMatch m) on) {
      final m = re.firstMatch(rest);
      if (m == null) return null;
      on(m);
      rest = rest.replaceRange(m.start, m.end, ' ');
      return m[0];
    }

    String? repeat;
    DateTime? day;
    DateTime? at;
    int? hour;
    int? minute;
    int? meridiem; // 0 = mañana, 12 = tarde/noche
    int? estimate;
    int? reminder;
    var priority = 0;
    int? monthDay;

    int minutes(String n, String unit) =>
        int.parse(n) * (unit.toLowerCase().startsWith('h') ? 60 : 1);

    // Repetición -------------------------------------------------------------
    take(
      _re(r'\b(cada d[ií]a|todos los d[ií]as|diariamente|a diario)\b'),
      (_) => repeat = 'daily',
    );
    take(
      _re(r'\b(entre semana|de lunes a viernes|d[ií]as h[aá]biles)\b'),
      (_) => repeat = 'weekdays',
    );
    take(_re('\\b(?:cada|todos los)\\s+($_days(?:\\s*(?:,|y)\\s*$_days)*)'), (
      m,
    ) {
      final list = [
        for (final d in _re(_days).allMatches(m[1]!)) _weekday(d[0]!) % 7,
      ]..sort();
      repeat = 'weekly:${list.toSet().join(',')}';
    });
    take(_re(r'\bcada mes(?:\s+el\s+(?:d[ií]a\s+)?(\d{1,2}))?\b'), (m) {
      repeat = 'monthly:';
      if (m[1] case final d?) monthDay = int.parse(d);
    });
    take(_re(r'\bcada semana\b'), (_) => repeat = 'weekly:');

    // Tiempos relativos y duración -------------------------------------------
    take(_re('\\ben\\s+(\\d{1,3})\\s*$_unit\\b'), (m) {
      at = now.add(Duration(minutes: minutes(m[1]!, m[2]!)));
    });
    take(_re('\\b(?:durante|por)\\s+(\\d{1,3})\\s*$_unit\\b'), (m) {
      estimate = minutes(m[1]!, m[2]!);
    });
    take(_re('\\bav[ií]same\\s+(\\d{1,3})\\s*$_unit\\s+antes\\b'), (m) {
      reminder = minutes(m[1]!, m[2]!);
    });
    take(
      _re(r'[,\s]*\b(urgente|importante|prioridad alta)\b'),
      (_) => priority = 2,
    );

    // Hora ------------------------------------------------------------------
    take(_re(r'\b(?:de|en|por) la (ma[ñn]ana|tarde|noche)\b'), (m) {
      meridiem = m[1]!.toLowerCase().startsWith('ma') ? 0 : 12;
    });
    take(
          _re(
            r'\b(?:a las?\s+)?(\d{1,2})(?::(\d{2}))?\s*([ap])\.?\s?m\.?(?=\W)',
          ),
          (m) {
            hour =
                int.parse(m[1]!) % 12 + (m[3]!.toLowerCase() == 'p' ? 12 : 0);
            minute = int.parse(m[2] ?? '0');
          },
        ) ??
        take(_re(r'\ba las?\s+(\d{1,2})(?::(\d{2}))?\b'), (m) {
          hour = int.parse(m[1]!);
          minute = int.parse(m[2] ?? '0');
          meridiem ??= hour! < 7 ? 12 : null; // «a las 6» = 18:00
        }) ??
        take(_re(r'\b(\d{1,2}):(\d{2})\b'), (m) {
          hour = int.parse(m[1]!);
          minute = int.parse(m[2]!);
        });
    if (hour != null && meridiem == 12 && hour! < 12) hour = hour! + 12;

    // Día -----------------------------------------------------------------------
    final today = DateTime(now.year, now.month, now.day);
    take(
          _re(r'\bpasado\s+ma[ñn]ana\b'),
          (_) => day = today.add(const Duration(days: 2)),
        ) ??
        take(
          _re(r'\bma[ñn]ana\b'),
          (_) => day = today.add(const Duration(days: 1)),
        ) ??
        take(_re(r'\bhoy\b'), (_) => day = today) ??
        take(_re('\\b(?:el\\s+|este\\s+)?$_days\\b'), (m) {
          final ahead = (_weekday(m[1]!) - now.weekday) % 7;
          day = today.add(Duration(days: ahead == 0 ? 7 : ahead));
        }) ??
        take(
          _re('\\bel\\s+(\\d{1,2})(?:\\s+de\\s+(${_months.join('|')}))?\\b'),
          (m) {
            final d = int.parse(m[1]!);
            final month = m[2] == null
                ? null
                : _months.indexOf(m[2]!.toLowerCase()) + 1;
            var date = DateTime(now.year, month ?? now.month, d);
            if (date.isBefore(today)) {
              date = month == null
                  ? DateTime(now.year, now.month + 1, d)
                  : DateTime(now.year + 1, month, d);
            }
            day = date;
            monthDay ??= d;
          },
        );

    // Reglas que dependen del día -------------------------------------------
    if (repeat case final r? when r.startsWith('weekly:') && r.length > 7) {
      // «cada lunes» sin fecha: el próximo lunes (u hoy si toca hoy).
      if (day == null) {
        final first = int.parse(r.substring(7).split(',').first);
        final ahead = ((first == 0 ? 7 : first) - now.weekday) % 7;
        day = today.add(Duration(days: ahead));
      }
    }
    final base = day ?? today;
    if (repeat == 'weekly:') repeat = 'weekly:${base.weekday % 7}';
    if (repeat == 'monthly:') repeat = 'monthly:${monthDay ?? base.day}';

    if (hour != null && hour! < 24 && minute! < 60) {
      var when = DateTime(base.year, base.month, base.day, hour!, minute!);
      // Hora sin día que ya pasó: mañana.
      if (day == null && !when.isAfter(now)) {
        when = when.add(const Duration(days: 1));
      }
      at = when;
    }
    final dueDay = at ?? day;
    final title = _title(rest);
    return TaskDraft(
      title: title.isEmpty ? text.trim() : title,
      scheduledAt: at,
      dueDate: dueDay == null
          ? null
          : DateTime(dueDay.year, dueDay.month, dueDay.day, 23, 59),
      estimatedMinutes: estimate,
      reminderMinutes: at == null ? null : (reminder ?? 10),
      repeatRule: repeat,
      priority: priority,
    );
  }

  /// Lunes = 1 … domingo = 7.
  static int _weekday(String name) {
    final n = name.toLowerCase();
    return switch (n.substring(0, 2)) {
      'lu' => 1,
      'ma' => 2,
      'mi' => 3,
      'ju' => 4,
      'vi' => 5,
      'sá' || 'sa' => 6,
      _ => 7,
    };
  }

  /// Quita conectores sueltos al final («a las», «el», «,») y pone mayúscula.
  static String _title(String rest) {
    var t = rest.replaceAll(RegExp(r'\s+'), ' ').trim();
    final tail = _re(r'(?:[\s,.\-]+|\b(?:a|el|la|de|para|y|las?)\b)+$');
    t = t.replaceAll(tail, '').trim();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1);
  }
}
