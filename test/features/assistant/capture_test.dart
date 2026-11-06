import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/assistant/data/models/task_draft_model.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/interpretation.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/break_down_task.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/interpret_capture.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/save_capture.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';

class _Repo extends Mock implements AssistantRepository {}

void main() {
  late _Repo repo;
  // Jueves 5 nov 2026, 14:00.
  final now = DateTime(2026, 11, 5, 14);
  const aiDraft = TaskDraft(title: 'Gimnasio', priority: 2);

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const TaskDraft(title: ''));
    registerFallbackValue(<DraftStep>[]);
  });
  setUp(() => repo = _Repo());

  void givenStatus(AiStatus status) =>
      when(repo.getAiStatus).thenAnswer((_) async => Right(status));

  group('InterpretCapture', () {
    InterpretCapture interpret() => InterpretCapture(repo, clock: () => now);

    test('con la IA apagada usa las reglas y no llama a la IA', () async {
      givenStatus(AiStatus.off);
      final r = (await interpret()('gym mañana 6pm')).getOrElse((_) => throw 0);
      expect(r.usedAi, isFalse);
      expect(r.draft.scheduledAt, DateTime(2026, 11, 6, 18));
      verifyNever(() => repo.parseWithAi(any(), any()));
    });

    test('con IA activa y cupo usa la IA', () async {
      givenStatus(const AiStatus(enabled: true, callsLeft: 5));
      when(
        () => repo.parseWithAi('gym', now),
      ).thenAnswer((_) async => const Right(aiDraft));
      final r = (await interpret()('gym')).getOrElse((_) => throw 0);
      expect(r.usedAi, isTrue);
      expect(r.draft, aiDraft);
      expect(r.aiAvailable, isTrue);
    });

    test('si la IA falla cae a las reglas y avisa', () async {
      givenStatus(const AiStatus(enabled: true, callsLeft: 5));
      when(() => repo.parseWithAi(any(), any())).thenAnswer(
        (_) async => const Left(ServerFailure('La IA no respondió.')),
      );
      final r = (await interpret()('leer hoy')).getOrElse((_) => throw 0);
      expect(r.usedAi, isFalse);
      expect(r.notice, 'La IA no respondió.');
      expect(r.draft.title, 'Leer');
    });

    test('sin cupo no intenta la IA', () async {
      givenStatus(const AiStatus(enabled: true, callsLeft: 0));
      final r = (await interpret()('leer')).getOrElse((_) => throw 0);
      expect(r.usedAi, isFalse);
      expect(r.aiAvailable, isFalse);
      verifyNever(() => repo.parseWithAi(any(), any()));
    });
  });

  test('BreakDownTask reparte los pasos hasta la fecha límite', () async {
    when(
      () => repo.breakdown('Informe'),
    ).thenAnswer((_) async => const Right(['Investigar', 'Escribir']));
    final steps = await BreakDownTask(repo, clock: () => now)(
      TaskDraft(title: 'Informe', dueDate: DateTime(2026, 11, 10, 23, 59)),
    );
    expect(steps.getOrElse((_) => const []), [
      DraftStep('Investigar', DateTime(2026, 11, 6, 23, 59)),
      DraftStep('Escribir', DateTime(2026, 11, 10, 23, 59)),
    ]);
  });

  group('CaptureBloc', () {
    CaptureBloc build() => CaptureBloc(
      interpret: InterpretCapture(repo, clock: () => now),
      breakDown: BreakDownTask(repo, clock: () => now),
      save: SaveCapture(repo),
    );

    blocTest<CaptureBloc, CaptureState>(
      'escribir → vista previa → crear tarea',
      setUp: () {
        givenStatus(AiStatus.off);
        when(
          () => repo.createTask(any(), any()),
        ).thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const CaptureSubmitted('comprar pan'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CaptureConfirmed());
      },
      expect: () => [
        const CaptureWriting(busy: true),
        const CapturePreview(
          draft: TaskDraft(title: 'Comprar pan'),
          usedAi: false,
          aiAvailable: false,
        ),
        const CapturePreview(
          draft: TaskDraft(title: 'Comprar pan'),
          usedAi: false,
          aiAvailable: false,
          busy: true,
        ),
        const CaptureSaved(toInbox: false),
      ],
      verify: (_) => verify(
        () => repo.createTask(const TaskDraft(title: 'Comprar pan'), const []),
      ).called(1),
    );

    blocTest<CaptureBloc, CaptureState>(
      '«A la Bandeja» guarda el texto como pensamiento',
      setUp: () => when(
        () => repo.saveToInbox('Idea'),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const CapturePreview(
        draft: TaskDraft(title: 'Idea'),
        usedAi: false,
        aiAvailable: false,
      ),
      act: (bloc) => bloc.add(const CaptureConfirmed(toInbox: true)),
      skip: 1,
      expect: () => [const CaptureSaved(toInbox: true)],
    );

    blocTest<CaptureBloc, CaptureState>(
      'si guardar falla conserva la vista previa y avisa',
      setUp: () => when(
        () => repo.createTask(any(), any()),
      ).thenAnswer((_) async => const Left(NetworkFailure('sin red'))),
      build: build,
      seed: () => const CapturePreview(
        draft: TaskDraft(title: 'Leer'),
        usedAi: false,
        aiAvailable: false,
      ),
      act: (bloc) => bloc.add(const CaptureConfirmed()),
      skip: 1,
      expect: () => [
        const CapturePreview(
          draft: TaskDraft(title: 'Leer'),
          usedAi: false,
          aiAvailable: false,
          message: 'sin red',
        ),
      ],
    );
  });

  group('TaskDraftModel', () {
    test('lee la respuesta de la IA y pone fecha y aviso por defecto', () {
      final d = TaskDraftModel({
        'kind': 'task',
        'title': ' ',
        'scheduled_at': '2026-11-06T23:00:00.000Z',
        'priority': 'medium',
        'repeat_rule': 'weekly:1',
      }, 'gym').toEntity();
      final at = DateTime.utc(2026, 11, 6, 23).toLocal();
      expect(d.title, 'gym');
      expect(d.scheduledAt, at);
      expect(d.dueDate, DateTime(at.year, at.month, at.day, 23, 59));
      expect(d.reminderMinutes, 10);
      expect(d.priority, 1);
      expect(TaskDraftModel({'kind': 'note'}, 'x').toEntity().isNote, isTrue);
    });

    test('localIso incluye el desfase horario', () {
      final iso = TaskDraftModel.localIso(DateTime(2026, 11, 5, 14));
      expect(iso, startsWith('2026-11-05T14:00:00'));
      expect(iso, matches(RegExp(r'[+-]\d\d:\d\d$')));
    });
  });
}
