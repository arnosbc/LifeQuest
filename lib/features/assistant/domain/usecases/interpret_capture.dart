import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/interpretation.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/local_parser.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';

/// Entiende una nota: con IA si el usuario la activó y queda cupo; si no, o
/// si la IA falla, con [LocalParser]. Nunca falla: siempre hay borrador.
class InterpretCapture implements UseCase<Interpretation, String> {
  InterpretCapture(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AssistantRepository _repository;
  final DateTime Function() _clock;

  @override
  Future<Either<Failure, Interpretation>> call(String text) async {
    final now = _clock();
    final status = (await _repository.getAiStatus()).getOrElse(
      (_) => AiStatus.off,
    );
    Interpretation local([String? notice]) => Interpretation(
      draft: LocalParser.parse(text, now),
      usedAi: false,
      aiAvailable: status.available,
      notice: notice,
    );
    if (!status.available) return Right(local());
    final ai = await _repository.parseWithAi(text, now);
    return Right(
      ai.match(
        (failure) => local(failure.message),
        (draft) => Interpretation(
          draft: draft,
          usedAi: true,
          aiAvailable: status.callsLeft > 1,
        ),
      ),
    );
  }
}
