import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_review.dart';

class GuidedStepReviewModel {
  const GuidedStepReviewModel(this.json);

  final Map<String, dynamic> json;

  GuidedStepReview toEntity() {
    final assessment = switch (json['assessment']) {
      'supports' => GuidedStepAssessment.supports,
      'partial' => GuidedStepAssessment.partial,
      'insufficient' => GuidedStepAssessment.insufficient,
      _ => throw const FormatException('Invalid step review assessment'),
    };
    final feedback = json['feedback'];
    final nextAction = json['next_action'];
    if (feedback is! String || nextAction is! String) {
      throw const FormatException('Invalid step review response');
    }
    return GuidedStepReview(
      assessment: assessment,
      feedback: feedback,
      nextAction: nextAction,
    );
  }
}
