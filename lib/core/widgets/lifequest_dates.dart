/// Fechas cortas en español para las pantallas ("12 oct", "12 oct · 18:00").
abstract final class LifeQuestDates {
  static const _months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static String day(DateTime date) => '${date.day} ${_months[date.month - 1]}';

  static String dayTime(DateTime date) =>
      '${day(date)} · ${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
