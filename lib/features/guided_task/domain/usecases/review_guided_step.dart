import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_evidence.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_review.dart';
import 'package:proyecto_movil/features/guided_task/domain/repositories/guided_task_repository.dart';

class ReviewGuidedStep
    implements UseCase<GuidedStepReview, ReviewGuidedStepParams> {
  const ReviewGuidedStep(this._repository);

  final GuidedTaskRepository _repository;

  @override
  Future<Either<Failure, GuidedStepReview>> call(
    ReviewGuidedStepParams params,
  ) {
    if (params.evidence.isEmpty ||
        params.evidence.length > GuidedStepEvidence.maxFiles) {
      return Future.value(
        const Left(ValidationFailure('Selecciona de 1 a 5 archivos.')),
      );
    }
    const mimeTypes = {
      'image/jpeg',
      'image/png',
      'image/heic',
      'image/heif',
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'text/plain',
    };
    var totalBytes = 0;
    for (final file in params.evidence) {
      if (!mimeTypes.contains(file.mimeType) ||
          file.bytes.isEmpty ||
          file.bytes.length > GuidedStepEvidence.maxBytes) {
        return Future.value(
          const Left(
            ValidationFailure(
              'Usa imágenes JPG/PNG/HEIC, PDF, DOCX, TXT o Markdown '
              'de hasta 10 MB.',
            ),
          ),
        );
      }
      totalBytes += file.bytes.length;
    }
    if (totalBytes > GuidedStepEvidence.maxTotalBytes) {
      return Future.value(
        const Left(
          ValidationFailure('El total de archivos no puede superar 10 MB.'),
        ),
      );
    }
    return _repository.reviewStep(params.stepId, params.evidence);
  }
}

class ReviewGuidedStepParams extends Equatable {
  const ReviewGuidedStepParams({required this.stepId, required this.evidence});

  final String stepId;
  final List<GuidedStepEvidence> evidence;

  @override
  List<Object?> get props => [stepId, evidence];
}
