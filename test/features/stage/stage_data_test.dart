import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/stage/data/models/stage_board_model.dart';
import 'package:proyecto_movil/features/stage/data/repositories/stage_repository_impl.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

import '../../helpers/mocks.dart';
import 'stage_fixtures.dart';

void main() {
  test('StageBoardModel convierte la respuesta de stage_overview', () {
    final board = StageBoardModel.fromJson({
      'highlight': [
        {'id': 't1', 'title': 'Informe', 'bucket': 'urgent', 'due_date': null},
      ],
      'highlight_total': 3,
      'projects': [
        {
          'id': 'p1',
          'title': 'App',
          'skill_name': null,
          'goal_title': 'Ascenso',
          'end_date': '2026-11-05',
          'tasks_total': 2,
          'tasks_done': 2,
          'urgency': 'medium',
          'tasks': [
            {'id': 't9', 'title': 'Diseño', 'done': true},
          ],
        },
      ],
      'areas': [
        {
          'id': 's1',
          'name': 'Trabajo',
          'level': 4,
          'open_tasks': 2,
          'projects': 1,
          'habits': 3,
        },
      ],
      'resources': [
        {'id': 'r1', 'title': 'Guía', 'url': 'https://example.com'},
      ],
      'archive': {'projects': 1, 'goals': 2, 'resources': 0},
      'skills': [
        {'id': 's1', 'name': 'Trabajo'},
      ],
      'goals': [
        {
          'id': 'g1',
          'title': 'Ascenso',
          'skill_name': 'Trabajo',
          'due_date': '2026-12-31',
          'boss_hp': 60,
          'boss_max_hp': 100,
          'projects': 1,
          'open_tasks': 2,
        },
      ],
    }).toEntity();

    expect(board.highlight.single.bucket, StageBucket.urgent);
    expect(board.highlightTotal, 3);
    final p = board.projects.single;
    expect(
      [p.urgency, p.skillName, p.goalTitle],
      [StageUrgency.medium, null, 'Ascenso'],
    );
    expect(p.endDate, DateTime(2026, 11, 5));
    expect(p.canComplete, isTrue);
    expect(board.areas.single.habits, 3);
    expect(board.resources.single.url, 'https://example.com');
    expect(board.archive.total, 3);
    expect(
      p.tasks.single,
      const StageTask(id: 't9', title: 'Diseño', done: true),
    );
    expect(
      board.goals.single,
      StageGoal(
        id: 'g1',
        title: 'Ascenso',
        skillName: 'Trabajo',
        dueDate: DateTime(2026, 12, 31),
        bossHp: 60,
        projects: 1,
        openTasks: 2,
      ),
    );
    expect(board.goalLinks, [const StageLink(id: 'g1', name: 'Ascenso')]);
  });

  test('un proyecto sin misiones o con misiones abiertas no se completa', () {
    expect(stageBoard.projects.single.canComplete, isFalse);
    expect(
      const StageProject(
        id: 'p',
        title: 'x',
        urgency: StageUrgency.low,
      ).canComplete,
      isFalse,
    );
  });

  test('respuesta vacía usa los valores por defecto', () {
    expect(StageBoardModel.fromJson({}).toEntity(), emptyStageBoard);
  });

  group('StageRepositoryImpl', () {
    late MockStageRemoteDataSource remote;
    late StageRepositoryImpl repository;

    setUpAll(() => registerFallbackValue(newProject));

    setUp(() {
      remote = MockStageRemoteDataSource();
      repository = StageRepositoryImpl(remote);
    });

    test('pide el tablero con la fecha local', () async {
      when(
        () => remote.getBoard(any()),
      ).thenAnswer((_) async => const StageBoardModel({}));
      expect(
        await repository.getBoard(DateTime(2026, 1, 9, 23)),
        const Right(emptyStageBoard),
      );
      verify(() => remote.getBoard('2026-01-09')).called(1);
    });

    test('traduce los motivos del servidor', () async {
      when(
        () => remote.completeProject('p1'),
      ).thenThrow(const ServerException(code: 'project_has_open_tasks'));
      expect(
        await repository.completeProject('p1'),
        const Left(
          ServerFailure(
            'A este proyecto aún le quedan misiones abiertas. ¡Ya casi!',
          ),
        ),
      );
    });

    test('sin conexión devuelve NetworkFailure', () async {
      when(
        () => remote.archive(kind: StageItemKind.resource, id: 'r1'),
      ).thenThrow(const NetworkException());
      expect(
        (await repository.archive(
          kind: StageItemKind.resource,
          id: 'r1',
        )).getLeft().toNullable(),
        isA<NetworkFailure>(),
      );
    });
  });
}
