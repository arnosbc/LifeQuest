import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/habits/domain/entities/habit.dart';

/// Datos que el usuario escribe al crear un hábito.
class NewHabit extends Equatable {
  const NewHabit({
    required this.name,
    required this.type,
    this.specificDays = const [],
    this.hpPenalty = 0,
    this.skillId,
  });

  final String name;
  final HabitType type;

  /// Solo hábitos buenos; vacío = diario.
  final List<int> specificDays;

  /// Solo hábitos malos: gravedad 3, 5 u 8.
  final int hpPenalty;
  final String? skillId;

  @override
  List<Object?> get props => [name, type, specificDays, hpPenalty, skillId];
}
