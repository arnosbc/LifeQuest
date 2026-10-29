import 'package:equatable/equatable.dart';

/// Respuestas del formulario S.M.A.R.T. (CLAUDE.md §4). Lo comparten Stage
/// y el Brain Dump: cada feature lo convierte en su propia petición.
class SmartGoal extends Equatable {
  const SmartGoal({
    required this.title,
    required this.specific,
    required this.measurable,
    required this.achievable,
    required this.relevant,
    required this.dueDate,
    this.timebound,
    this.skillId,
  });

  final String title;

  /// S: ¿qué exactamente quieres lograr?
  final String specific;

  /// M: ¿cómo sabrás que lo lograste?
  final String measurable;

  /// A: ¿por qué es alcanzable?
  final String achievable;

  /// R: ¿por qué te importa?
  final String relevant;

  /// T: fecha límite (obligatoria) y nota opcional.
  final DateTime dueDate;
  final String? timebound;
  final String? skillId;

  @override
  List<Object?> get props => [
    title,
    specific,
    measurable,
    achievable,
    relevant,
    dueDate,
    timebound,
    skillId,
  ];
}

/// Skill (Área) que se puede vincular a una Meta.
class SkillChoice extends Equatable {
  const SkillChoice({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
