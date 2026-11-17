import 'package:equatable/equatable.dart';

/// Plan de Nevi para un hábito (065): versión mínima de 2 minutos, disparador,
/// recompensa y por qué importa (Atomic Habits / Tiny Habits).
class HabitPlan extends Equatable {
  const HabitPlan({required this.tiny, this.cue, this.reward, this.why});

  final String tiny;
  final String? cue;
  final String? reward;
  final String? why;

  @override
  List<Object?> get props => [tiny, cue, reward, why];
}
