import 'package:fpdart/fpdart.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/reminders/domain/entities/reminder_plan.dart';

/// Contrato de Recordatorios. La capa data lo implementa.
abstract class RemindersRepository {
  /// Envía la zona horaria del teléfono y trae lo que hay que avisar.
  Future<Either<Failure, ReminderPlan>> getPlan();

  /// Reemplaza todos los avisos programados por [reminders].
  Future<Either<Failure, Unit>> replaceAll(List<LocalReminder> reminders);
}
