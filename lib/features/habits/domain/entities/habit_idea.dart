import 'package:equatable/equatable.dart';

/// Hábito bueno que Nevi propone (npc-mission, modo ideas). Solo sugiere:
/// la persona elige cuál crear.
class HabitIdea extends Equatable {
  const HabitIdea({required this.name, required this.why, this.time});

  final String name;

  /// Por qué le ayuda, en una frase.
  final String why;

  /// Hora sugerida «HH:MM»; null si la IA no dio una válida.
  final String? time;

  @override
  List<Object?> get props => [name, why, time];
}
