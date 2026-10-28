import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/brain_dump/data/models/brain_dump_board_model.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';
import 'package:proyecto_movil/features/brain_dump/domain/usecases/file_thought.dart';
import 'package:proyecto_movil/features/brain_dump/presentation/blocs/brain_dump_bloc.dart';

import '../../helpers/mocks.dart';

final thought = Thought(
  id: 't1',
  content: 'Llamar al dentista',
  createdAt: DateTime(2026, 10, 27),
);
final board = BrainDumpBoard(inbox: [thought]);
const conversion = Conversion(
  thoughtId: 't1',
  kind: ThoughtKind.done,
  title: 'Llamar al dentista',
);

void main() {
  test('BrainDumpBoardModel separa bandeja, Algún día y Referencia', () {
    final entity = BrainDumpBoardModel.fromJson({
      'inbox': [
        {'id': 'a', 'content': 'x', 'created_at': '2026-10-27T10:00:00+00:00'},
      ],
      'someday': [],
      'reference': [
        {'id': 'b', 'content': 'y', 'created_at': '2026-10-26T10:00:00+00:00'},
      ],
      'converted_today': 2,
    }).toEntity();
    expect(
      [entity.inbox.single.id, entity.reference.single.id, entity.someday],
      ['a', 'b', isEmpty],
    );
    expect(entity.convertedToday, 2);
  });

  group('BrainDumpBloc', () {
    late MockGetBrainDump getBoard;
    late MockFileThought file;
    late MockConvertThought convert;

    setUpAll(() {
      registerFallbackValue(const NoParams());
      registerFallbackValue(const FileThoughtParams('x', ThoughtShelf.someday));
      registerFallbackValue(conversion);
    });

    setUp(() {
      getBoard = MockGetBrainDump();
      file = MockFileThought();
      convert = MockConvertThought();
      when(() => getBoard(any())).thenAnswer((_) async => Right(board));
    });

    BrainDumpBloc build() => BrainDumpBloc(
      getBoard: getBoard,
      capture: MockCaptureThought(),
      file: file,
      convert: convert,
      delete: MockDeleteThought(),
    );

    blocTest<BrainDumpBloc, BrainDumpState>(
      'la regla de 2 minutos convierte y celebra',
      setUp: () =>
          when(() => convert(any())).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => BrainDumpSuccess(board),
      act: (bloc) => bloc.add(const ThoughtConverted(conversion)),
      expect: () => [
        BrainDumpSuccess(board, busyKey: 't1'),
        BrainDumpSuccess(board, message: '¡Hecho en un momento! Una menos.'),
      ],
      verify: (_) => verify(() => convert(conversion)).called(1),
    );

    blocTest<BrainDumpBloc, BrainDumpState>(
      'si archivar falla, conserva la bandeja y avisa',
      setUp: () => when(
        () => file(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('Ya no está.'))),
      build: build,
      seed: () => BrainDumpSuccess(board),
      act: (bloc) => bloc.add(const ThoughtFiled('t1', ThoughtShelf.reference)),
      expect: () => [
        BrainDumpSuccess(board, busyKey: 't1'),
        BrainDumpSuccess(board, message: 'Ya no está.'),
      ],
    );
  });
}
