import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/features/assistant/data/models/task_draft_model.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/interpretation.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/step_templates.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/break_down_task.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/interpret_capture.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/plan_goal.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/save_capture.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';

import '../../helpers/mocks.dart';

class _Repo extends Mock implements AssistantRepository {}

class _Resources extends Mock implements ResourceRepository {}

void main() {
  late _Repo repo;
  late _Resources resources;
  late MockListenVoice voice;
  // Jueves 5 nov 2026, 14:00.
  final now = DateTime(2026, 11, 5, 14);
  const aiDraft = TaskDraft(title: 'Gimnasio', priority: 2);

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const TaskDraft(title: ''));
    registerFallbackValue(<DraftStep>[]);
    registerFallbackValue(const ResourceTarget.task(''));
    registerFallbackValue(ResourceDraft.note('x'));
    registerFallbackValue(
      const SmartGoal(
        specific: '',
        measurable: '',
        achievable: '',
        relevant: '',
      ),
    );
  });
  setUp(() {
    repo = _Repo();
    resources = _Resources();
    voice = MockListenVoice();
  });

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
    final steps = await BreakDownTask(repo, resources, clock: () => now)(
      TaskDraft(title: 'Informe', dueDate: DateTime(2026, 11, 10, 23, 59)),
    );
    expect(steps.getOrElse((_) => const []), [
      DraftStep('Investigar', DateTime(2026, 11, 6, 23, 59)),
      DraftStep('Escribir', DateTime(2026, 11, 10, 23, 59)),
    ]);
  });

  test('sin IA, BreakDownTask propone pasos por reglas', () async {
    when(
      () => repo.breakdown(any()),
    ).thenAnswer((_) async => const Left(ServerFailure('La IA está apagada.')));
    final titles = await BreakDownTask(
      repo,
      resources,
    ).titles('Realizar pruebas finales y desplegar la aplicación');
    expect(
      titles.getOrElse((_) => const []).first,
      'Definir qué debe funcionar',
    );
  });

  test('StepTemplates: inicio de palabra y plantilla genérica', () {
    expect(
      StepTemplates.forTitle('Estudiar para el parcial').first,
      'Reunir apuntes y temas',
    );
    // «apagar» no debe tomarse como «pagar».
    expect(
      StepTemplates.forTitle('Apagar el router').first,
      'Definir cómo se ve terminado',
    );
  });

  group('CaptureBloc', () {
    CaptureBloc build() => CaptureBloc(
      interpret: InterpretCapture(repo, clock: () => now),
      breakDown: BreakDownTask(repo, resources, clock: () => now),
      planGoal: PlanGoal(repo, clock: () => now),
      save: SaveCapture(repo, resources),
      listen: voice,
      clock: () => now,
    );

    blocTest<CaptureBloc, CaptureState>(
      'escribir → vista previa → crear tarea',
      setUp: () {
        givenStatus(AiStatus.off);
        when(
          () => repo.createTask(any(), any()),
        ).thenAnswer((_) async => const Right('t1'));
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
      'meta: la IA escribe el S.M.A.R.T. y los pasos; se crea la meta con ellos',
      setUp: () {
        when(() => repo.planGoal(any())).thenAnswer(
          (_) async => const Right((
            title: 'Correr 10 km',
            smart: SmartGoal(
              specific: 'a',
              measurable: 'b',
              achievable: 'c',
              relevant: 'd',
            ),
            steps: ['Correr 3 km', 'Correr 5 km'],
          )),
        );
        when(
          () => repo.createGoal(any(), any(), any()),
        ).thenAnswer((_) async => const Right('g1'));
      },
      build: build,
      act: (bloc) async {
        bloc.add(const CaptureKindChanged(CaptureKind.goal));
        bloc.add(const CaptureSubmitted('correr 10k'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CaptureConfirmed());
      },
      skip: 1,
      verify: (bloc) {
        final saved = verify(
          () => repo.createGoal(captureAny(), any(), captureAny()),
        ).captured;
        final draft = saved[0] as TaskDraft;
        expect(draft.title, 'Correr 10 km');
        // Sin fecha dicha: vence en 90 días; los pasos se reparten hasta ahí.
        expect(
          draft.dueDate,
          now.add(const Duration(days: PlanGoal.defaultDays)),
        );
        expect((saved[1] as List<DraftStep>).length, 2);
        expect(bloc.state, const CaptureSaved(toInbox: false));
      },
    );

    blocTest<CaptureBloc, CaptureState>(
      'dictar muestra lo que oye y al terminar lo interpreta',
      setUp: () {
        givenStatus(AiStatus.off);
        when(
          () => voice(),
        ).thenAnswer((_) => Stream.fromIterable(['leer', 'leer hoy']));
      },
      build: build,
      act: (bloc) => bloc.add(const CaptureListenRequested()),
      expect: () => [
        const CaptureWriting(listening: true),
        const CaptureWriting(listening: true, heard: 'leer'),
        const CaptureWriting(listening: true, heard: 'leer hoy'),
        const CaptureWriting(busy: true),
        CapturePreview(
          draft: TaskDraft(
            title: 'Leer',
            dueDate: DateTime(2026, 11, 5, 23, 59),
          ),
          usedAi: false,
          aiAvailable: false,
        ),
      ],
    );

    blocTest<CaptureBloc, CaptureState>(
      'si el micrófono falla avisa y deja escribir',
      setUp: () => when(
        () => voice(),
      ).thenAnswer((_) => Stream<String>.error('Sin micrófono.')),
      build: build,
      act: (bloc) => bloc.add(const CaptureListenRequested()),
      expect: () => [
        const CaptureWriting(listening: true),
        const CaptureWriting(heard: '', message: 'Sin micrófono.'),
      ],
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

  group('Recursos al crear', () {
    test('SaveCapture adjunta cada recurso a la tarea creada', () async {
      when(() => repo.createTask(any(), any()))
          .thenAnswer((_) async => const Right('t1'));
      when(() => resources.attach(any(), any()))
          .thenAnswer((_) async => const Right(unit));
      final link = ResourceDraft.link('https://ejemplo.com/guia');
      final note = ResourceDraft.note('Usar el capítulo 3');
      final r = await SaveCapture(repo, resources)((
        draft: const TaskDraft(title: 'Estudiar'),
        steps: const [],
        toInbox: false,
        kind: CaptureKind.task,
        smart: null,
        attachments: [link, note],
      ));
      expect(r, const Right<Failure, String?>(null));
      verify(() => resources.attach(const ResourceTarget.task('t1'), link)).called(1);
      verify(() => resources.attach(const ResourceTarget.task('t1'), note)).called(1);
    });

    test('si un recurso falla, lo creado queda y se avisa', () async {
      when(() => repo.createTask(any(), any()))
          .thenAnswer((_) async => const Right('t1'));
      when(() => resources.attach(any(), any()))
          .thenAnswer((_) async => const Left(ServerFailure('x')));
      final r = await SaveCapture(repo, resources)((
        draft: const TaskDraft(title: 'Estudiar'),
        steps: const [],
        toInbox: false,
        kind: CaptureKind.task,
        smart: null,
        attachments: [ResourceDraft.note('a')],
      ));
      expect(r.getOrElse((_) => null), contains('1 recurso'));
    });

    test('la Bandeja no recibe recursos', () async {
      when(() => repo.saveToInbox(any()))
          .thenAnswer((_) async => const Right(unit));
      await SaveCapture(repo, resources)((
        draft: const TaskDraft(title: 'Idea'),
        steps: const [],
        toInbox: true,
        kind: CaptureKind.task,
        smart: null,
        attachments: [ResourceDraft.note('a')],
      ));
      verifyNever(() => resources.attach(any(), any()));
    });

    test('Dividir en pasos manda el material subido a la IA', () async {
      const ai = AiContext(paths: ['u/x.pdf'], context: ['nota']);
      when(() => resources.prepareForAi(any()))
          .thenAnswer((_) async => const Right(ai));
      when(() => repo.breakdown('Informe', ai: ai))
          .thenAnswer((_) async => const Right(['Leer guía', 'Escribir']));
      final steps = await BreakDownTask(repo, resources, clock: () => now)
          .withAttachments(const TaskDraft(title: 'Informe'), [ResourceDraft.note('nota')]);
      expect(steps.getOrElse((_) => const []).map((s) => s.title), ['Leer guía', 'Escribir']);
    });
  });

  test('ResourceDraft valida enlace, tipo y tamaño', () {
    expect(ResourceDraft.link('ftp://x').problem, isNotNull);
    expect(ResourceDraft.link('https://ejemplo.com/a').title, 'ejemplo.com');
    expect(ResourceDraft.file(localPath: '/a', name: 'a.docx', size: 1).problem, isNotNull);
    expect(ResourceDraft.file(localPath: '/a', name: 'g.pdf', size: 20 << 20).problem, isNotNull);
    expect(ResourceDraft.file(localPath: '/a', name: 'f.JPG', size: 100).kind, ResourceKind.image);
    expect(ResourceDraft.file(localPath: '/a', name: 'f.JPG', size: 100).problem, isNull);
  });
}
