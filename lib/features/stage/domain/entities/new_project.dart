import 'package:equatable/equatable.dart';

/// Datos que el usuario escribe al crear un proyecto desde Quick Add.
class NewProject extends Equatable {
  const NewProject({
    required this.title,
    this.description,
    this.endDate,
    this.skillId,
    this.goalId,
  });

  final String title;
  final String? description;

  /// Sin fecha de fin la urgencia queda en baja.
  final DateTime? endDate;
  final String? skillId;
  final String? goalId;

  @override
  List<Object?> get props => [title, description, endDate, skillId, goalId];
}
