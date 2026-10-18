import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/home/data/models/home_dashboard_model.dart';
import 'package:proyecto_movil/features/home/data/repositories/home_repository_impl.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

import '../../../../helpers/mocks.dart';
import '../../home_fixtures.dart';

void main() {
  late MockHomeRemoteDataSource remote;
  late HomeRepositoryImpl repository;
  final now = DateTime(2026, 3, 7, 22, 15);

  setUp(() {
    remote = MockHomeRemoteDataSource();
    repository = HomeRepositoryImpl(remote);
  });

  group('getDashboard', () {
    test('pide el día local y su desfase con UTC', () async {
      when(
        () => remote.getDashboard(
          day: any(named: 'day'),
          utcOffsetMinutes: any(named: 'utcOffsetMinutes'),
        ),
      ).thenAnswer((_) async => HomeDashboardModel.fromJson(dashboardJson));

      final result = await repository.getDashboard(now);

      expect(result, Right<Failure, HomeDashboard>(dashboard));
      verify(
        () => remote.getDashboard(
          day: '2026-03-07',
          utcOffsetMinutes: now.timeZoneOffset.inMinutes,
        ),
      ).called(1);
    });

    test('sin conexión devuelve NetworkFailure', () async {
      when(
        () => remote.getDashboard(
          day: any(named: 'day'),
          utcOffsetMinutes: any(named: 'utcOffsetMinutes'),
        ),
      ).thenThrow(const NetworkException());

      expect(
        await repository.getDashboard(now),
        const Left<Failure, HomeDashboard>(
          NetworkFailure(
            'No hay conexión con el servidor. Revisa tu internet y reintenta.',
          ),
        ),
      );
    });
  });

  group('completeHabit', () {
    void givenThrows(Object error) => when(
      () => remote.completeHabit(
        habitId: any(named: 'habitId'),
        day: any(named: 'day'),
      ),
    ).thenThrow(error);

    test('registra el hábito con la fecha local', () async {
      when(
        () => remote.completeHabit(habitId: 'h2', day: '2026-03-07'),
      ).thenAnswer((_) async {});

      expect(
        await repository.completeHabit(habitId: 'h2', now: now),
        const Right<Failure, Unit>(unit),
      );
    });

    final cases = {
      'already_completed': 'Ese hábito ya quedó registrado hoy. ¡Bien hecho!',
      'not_scheduled': 'Este hábito no toca hoy. Te espera su próximo día.',
      'habit_not_found': 'No encontramos ese hábito. Desliza para actualizar.',
      'invalid_day':
          'La fecha de tu teléfono no coincide con la de hoy. Revísala y reintenta.',
      'algo raro': 'Algo salió mal. Inténtalo de nuevo en un momento.',
    };
    for (final MapEntry(key: code, value: message) in cases.entries) {
      test('el motivo "$code" se explica al usuario', () async {
        givenThrows(ServerException(code: code));

        expect(
          await repository.completeHabit(habitId: 'h2', now: now),
          Left<Failure, Unit>(ServerFailure(message)),
        );
      });
    }
  });
}
