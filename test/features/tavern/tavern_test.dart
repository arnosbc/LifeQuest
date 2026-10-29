import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/tavern/data/models/tavern_board_model.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/accept_npc_mission.dart';
import 'package:proyecto_movil/features/tavern/domain/usecases/add_npc_document.dart';
import 'package:proyecto_movil/features/tavern/presentation/blocs/tavern_bloc.dart';

import '../../helpers/mocks.dart';

const vera = Npc(id: 'n1', name: 'Vera', skillName: 'Salud');
const board = TavernBoard(npcs: [vera], npcLimit: 3);

void main() {
  test('TavernBoardModel convierte tavern_overview', () {
    final entity = TavernBoardModel.fromJson({
      'npcs': [
        {
          'id': 'n1',
          'name': 'Vera',
          'noble_mission': 'Que corras',
          'frequency': 'daily',
          'skill_name': 'Salud',
          'free_at': '2026-10-27T18:00:00+00:00',
          'open_mission': {
            'id': 't1',
            'title': 'Correr 5 km',
            'description': 'Calienta 5 minutos antes de correr',
            'xp_reward': 10,
          },
          'completed': 2,
          'documents': [
            {'id': 'd1', 'title': 'Plan de asignatura'},
          ],
        },
      ],
      'npc_limit': 4,
      'instant_cost': 15,
      'coins': 88,
      'skills': [
        {'id': 's1', 'name': 'Salud'},
      ],
    }).toEntity();

    final npc = entity.npcs.single;
    expect(npc.frequency, NpcFrequency.daily);
    expect(
      npc.openMission,
      const NpcMission(
        id: 't1',
        title: 'Correr 5 km',
        description: 'Calienta 5 minutos antes de correr',
        xpReward: 10,
      ),
    );
    expect(npc.isFree(DateTime.utc(2026, 10, 27, 17)), isFalse);
    expect(npc.isFree(DateTime.utc(2026, 10, 27, 19)), isTrue);
    expect([entity.npcLimit, entity.full], [4, false]);
    expect(npc.documents, const [
      NpcDocument(id: 'd1', title: 'Plan de asignatura'),
    ]);
    expect(npc.documentsFull, isFalse);
  });

  group('AddNpcDocument', () {
    late MockTavernRepository repository;
    late AddNpcDocument add;
    NewNpcDocument file(String name, [int size = 10]) =>
        NewNpcDocument(npcId: 'n1', fileName: name, bytes: Uint8List(size));

    setUpAll(() => registerFallbackValue(file('x.pdf')));

    setUp(() {
      repository = MockTavernRepository();
      add = AddNpcDocument(repository);
      when(
        () => repository.addDocument(any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    test('acepta PDF, Word y Markdown y usa el nombre como título', () async {
      for (final name in ['Plan.PDF', 'plan.docx', 'notas.md']) {
        expect(await add(file(name)), const Right(unit));
      }
      expect(file('Plan de asignatura.docx').title, 'Plan de asignatura');
      verify(() => repository.addDocument(any())).called(3);
    });

    test(
      'rechaza otros formatos, vacíos y de más de 10 MB sin subirlos',
      () async {
        expect((await add(file('viejo.doc'))).isLeft(), isTrue);
        expect((await add(file('foto.png'))).isLeft(), isTrue);
        expect((await add(file('plan.pdf', 0))).isLeft(), isTrue);
        expect(
          (await add(file('plan.pdf', NewNpcDocument.maxBytes + 1))).isLeft(),
          isTrue,
        );
        expect((await add(file('.pdf'))).isLeft(), isTrue);
        verifyNever(() => repository.addDocument(any()));
      },
    );
  });

  group('TavernBloc', () {
    late MockGetTavernBoard getBoard;
    late MockAcceptNpcMission accept;
    late MockCompleteNpcMission complete;
    late MockSuggestNpcMission suggest;
    late MockAddNpcDocument addDocument;
    late MockRemoveNpcDocument removeDocument;
    final plan = NewNpcDocument(
      npcId: 'n1',
      fileName: 'Plan.docx',
      bytes: Uint8List(4),
    );

    setUpAll(() {
      registerFallbackValue(const NoParams());
      registerFallbackValue(
        const AcceptNpcMissionParams(npcId: 'n', title: 't'),
      );
      registerFallbackValue(plan);
    });

    setUp(() {
      getBoard = MockGetTavernBoard();
      accept = MockAcceptNpcMission();
      complete = MockCompleteNpcMission();
      suggest = MockSuggestNpcMission();
      addDocument = MockAddNpcDocument();
      removeDocument = MockRemoveNpcDocument();
      when(() => getBoard(any())).thenAnswer((_) async => const Right(board));
    });

    TavernBloc build() => TavernBloc(
      getBoard: getBoard,
      createNpc: MockCreateNpc(),
      suggestMission: suggest,
      acceptMission: accept,
      completeMission: complete,
      renameNpc: MockRenameNpc(),
      deleteNpc: MockDeleteNpc(),
      addDocument: addDocument,
      removeDocument: removeDocument,
    );

    blocTest<TavernBloc, TavernState>(
      'adjuntar un documento lo envía y avisa cuando RPGenie lo leyó',
      setUp: () => when(
        () => addDocument(any()),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) => bloc.add(NpcDocumentAdded(plan)),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(
          board,
          message:
              'RPGenie leyó «Plan». Las próximas misiones saldrán de sus temas.',
        ),
      ],
      verify: (_) => verify(() => addDocument(plan)).called(1),
    );

    blocTest<TavernBloc, TavernState>(
      'si RPGenie no pudo leer el documento, conserva la Taverna y avisa',
      setUp: () => when(() => addDocument(any())).thenAnswer(
        (_) async => const Left(ServerFailure('No logramos leerlo.')),
      ),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) => bloc.add(NpcDocumentAdded(plan)),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(board, message: 'No logramos leerlo.'),
      ],
    );

    blocTest<TavernBloc, TavernState>(
      'quitar un documento lo borra y vuelve a leer',
      setUp: () => when(
        () => removeDocument('d1'),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) =>
          bloc.add(const NpcDocumentRemoved(npcId: 'n1', documentId: 'd1')),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(board, message: 'Documento quitado.'),
      ],
    );

    blocTest<TavernBloc, TavernState>(
      'aceptar una misión la crea y vuelve a leer',
      setUp: () =>
          when(() => accept(any())).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) =>
          bloc.add(const NpcMissionAccepted(npcId: 'n1', title: 'Correr')),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(
          board,
          message: 'Misión aceptada. Ya está en tu Stage.',
        ),
      ],
      verify: (_) => verify(
        () =>
            accept(const AcceptNpcMissionParams(npcId: 'n1', title: 'Correr')),
      ).called(1),
    );

    blocTest<TavernBloc, TavernState>(
      'pedir misión: RPGenie la redacta con su guía y se acepta sola',
      setUp: () {
        when(() => suggest('n1')).thenAnswer(
          (_) async => const Right(
            NpcMissionSuggestion(
              title: 'Diseña 3 logos',
              guide: 'Empieza en blanco y negro',
            ),
          ),
        );
        when(() => accept(any())).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) => bloc.add(const NpcMissionRequested(vera)),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(
          board,
          message: 'Nueva misión de Vera: Diseña 3 logos',
        ),
      ],
      verify: (_) => verify(
        () => accept(
          const AcceptNpcMissionParams(
            npcId: 'n1',
            title: 'Diseña 3 logos',
            description: 'Empieza en blanco y negro',
          ),
        ),
      ).called(1),
    );

    blocTest<TavernBloc, TavernState>(
      'si RPGenie falla, avisa y no crea ni cobra nada',
      setUp: () => when(
        () => suggest('n1'),
      ).thenAnswer((_) async => const Left(ServerFailure('sin cupo'))),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) => bloc.add(const NpcMissionRequested(vera)),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(board, message: 'sin cupo'),
      ],
      verify: (_) => verifyNever(() => accept(any())),
    );

    blocTest<TavernBloc, TavernState>(
      'si cumplir falla, conserva los datos y avisa',
      setUp: () => when(() => complete(any())).thenAnswer(
        (_) async => const Left(ServerFailure('Ya estaba cerrada.')),
      ),
      build: build,
      seed: () => const TavernSuccess(board),
      act: (bloc) =>
          bloc.add(const NpcMissionCompleted(npcId: 'n1', taskId: 't1')),
      expect: () => [
        const TavernSuccess(board, busyKey: 'n1'),
        const TavernSuccess(board, message: 'Ya estaba cerrada.'),
      ],
    );
  });
}
