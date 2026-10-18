import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/domain/usecases/complete_habit.dart';
import 'package:proyecto_movil/features/home/domain/usecases/get_home_dashboard.dart';

import '../../../../helpers/mocks.dart';
import '../../home_fixtures.dart';

void main() {
  late MockHomeRepository repository;
  final now = DateTime(2026, 10, 17, 9);

  setUp(() => repository = MockHomeRepository());

  test('GetHomeDashboard delega en el repositorio', () async {
    when(
      () => repository.getDashboard(now),
    ).thenAnswer((_) async => Right(dashboard));

    expect(
      await GetHomeDashboard(repository)(now),
      Right<Failure, HomeDashboard>(dashboard),
    );
  });

  test('CompleteHabit delega en el repositorio', () async {
    when(
      () => repository.completeHabit(habitId: 'h2', now: now),
    ).thenAnswer((_) async => const Right(unit));

    expect(
      await CompleteHabit(repository)(
        CompleteHabitParams(habitId: 'h2', now: now),
      ),
      const Right<Failure, Unit>(unit),
    );
  });
}
