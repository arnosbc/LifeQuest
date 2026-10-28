import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/habits/domain/entities/habits_board.dart';
import 'package:proyecto_movil/features/habits/domain/entities/new_habit.dart';

/// Contrato de Hábitos. La capa data lo implementa.
abstract class HabitsRepository {
  /// [now] es la hora local del dispositivo: define qué es "hoy".
  Future<Either<Failure, HabitsBoard>> getBoard(DateTime now);

  Future<Either<Failure, Unit>> createHabit(NewHabit habit);

  /// Registra el hábito bueno como cumplido hoy; el servidor da la recompensa.
  Future<Either<Failure, Unit>> completeGoodHabit({
    required String habitId,
    required DateTime now,
  });

  /// Registra un evento del hábito malo; el servidor resta la vida.
  Future<Either<Failure, Unit>> registerBadHabit(String habitId);

  Future<Either<Failure, Unit>> renameHabit(String habitId, String name);

  Future<Either<Failure, Unit>> deleteHabit(String habitId);
}
