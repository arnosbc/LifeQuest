import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/journal/data/models/journal_board_model.dart';
import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';
import 'package:proyecto_movil/features/journal/presentation/blocs/journal_bloc.dart';

import '../../helpers/mocks.dart';

void main() {
  test(
    'JournalBoardModel convierte journal_overview y omite orígenes nuevos',
    () {
      final board = JournalBoardModel.fromJson({
        'summary': {'xp': 40, 'xp_prev': 10, 'missions': 2, 'best_streak': 5},
        'entries': [
          {
            'id': 'e1',
            'source': 'daily_chest',
            'result': 'completed',
            'coins': 15,
            'occurred_at': '2026-10-27T10:00:00+00:00',
          },
          {
            'id': 'e2',
            'source': 'habit',
            'result': 'failed',
            'hp': -5,
            'title': 'Pantallas',
            'occurred_at': '2026-10-27T09:00:00+00:00',
          },
          {
            'id': 'e3',
            'source': 'algo_futuro',
            'occurred_at': '2026-10-27T08:00:00+00:00',
          },
        ],
      }).toEntity();

      expect(board.summary.xp, 40);
      expect(board.summary.bestStreak, 5);
      expect(board.entries.map((e) => e.source), [
        JournalSource.dailyChest,
        JournalSource.habit,
      ]);
      expect(board.entries.last.completed, isFalse);
      expect(board.entries.last.hp, -5);
    },
  );

  final now = DateTime(2026, 10, 27, 9);

  blocTest<JournalBloc, JournalState>(
    'si la primera carga falla, muestra el error',
    build: () {
      final getJournal = MockGetJournal();
      when(
        () => getJournal(now),
      ).thenAnswer((_) async => const Left(ServerFailure('Sin Diario.')));
      return JournalBloc(getJournal: getJournal, clock: () => now);
    },
    act: (bloc) => bloc.add(const JournalRequested()),
    expect: () => [const JournalLoading(), const JournalFailure('Sin Diario.')],
  );
}
