import 'package:equatable/equatable.dart';

enum GuidedStepAssessment { supports, partial, insufficient }

/// Revisión orientativa de la evidencia. Nunca bloquea: si es `supports`, el
/// bloc marca el paso (con las reglas de siempre); si no, solo aconseja.
class GuidedStepReview extends Equatable {
  const GuidedStepReview({
    required this.assessment,
    required this.feedback,
    required this.nextAction,
  });

  final GuidedStepAssessment assessment;
  final String feedback;
  final String nextAction;

  @override
  List<Object?> get props => [assessment, feedback, nextAction];
}
