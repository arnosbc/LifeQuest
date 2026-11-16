import 'package:flutter/material.dart';

/// «20:00» → «8:00 p. m.».
String habitTimeLabel(String hhmm) {
  final [h, m] = hhmm.split(':').map(int.parse).toList();
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} ${h < 12 ? 'a. m.' : 'p. m.'}';
}

/// Reloj del sistema; devuelve «HH:MM» o null si se cancela.
Future<String?> pickHabitTime(BuildContext context, String? current) async {
  final [h, m] = (current ?? '20:00').split(':').map(int.parse).toList();
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: h, minute: m),
    helpText: '¿A qué hora harás este hábito?',
  );
  if (picked == null) return null;
  return '${picked.hour.toString().padLeft(2, '0')}:'
      '${picked.minute.toString().padLeft(2, '0')}';
}
