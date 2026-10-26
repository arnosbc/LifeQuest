import 'package:equatable/equatable.dart';

/// Meta nueva con su ficha S.M.A.R.T. (RF-014).
class NewGoal extends Equatable {
  const NewGoal({
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

  /// A: ¿por qué es realista?
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
