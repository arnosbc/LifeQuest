import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_evidence.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_step_review.dart';
import 'package:proyecto_movil/features/guided_task/domain/entities/guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/complete_guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/generate_guided_steps.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/get_guided_task.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/review_guided_step.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/set_guided_steps.dart';
import 'package:proyecto_movil/features/guided_task/domain/usecases/toggle_guided_step.dart';
import 'package:proyecto_movil/features/guided_task/presentation/blocs/guided_task_bloc.dart';

class _Get extends Mock implements GetGuidedTask {}

class _Generate extends Mock implements GenerateGuidedSteps {}

void main() {
  late _Get getTask;
  late _Generate generate;
  final plain = GuidedTask(
    id: 't1',
    title: 'Estudiar para el parcial',
    xpReward: 20,
    coinReward: 6,
    createdAt: DateTime(2026, 11, 15),
  );
  final guided = GuidedTask(
    id: 't1',
    title: 'Estudiar para el parcial',
    xpReward: 20,
    coinReward: 6,
    createdAt: DateTime(2026, 11, 15),
    steps: const [
      GuidedStep(id: 's1', position: 1, title: 'Lista los 3 temas'),
      GuidedStep(id: 's2', position: 2, title: 'Resume el primero'),
    ],
  );

  late _ToggleStub toggle;
  late _ReviewStub review;
  final evidence = [
    GuidedStepEvidence(
      name: 'foto.jpg',
      mimeType: 'image/jpeg',
      bytes: Uint8List.fromList([1, 2, 3]),
    ),
  ];
  GuidedStepReview reviewOf(GuidedStepAssessment a) =>
      GuidedStepReview(assessment: a, feedback: 'Se ve bien.', nextAction: '');

  setUpAll(() {
    registerFallbackValue(
      ReviewGuidedStepParams(stepId: 's1', evidence: const []),
    );
  });

  setUp(() {
    getTask = _Get();
    generate = _Generate();
    toggle = _ToggleStub();
    review = _ReviewStub();
  });

  GuidedTaskBloc build() => GuidedTaskBloc(
    getTask: getTask,
    toggleStep: toggle,
    completeTask: _CompleteStub(),
    reviewStep: review,
    setSteps: _SetStub(),
    generateSteps: generate,
  );

  blocTest<GuidedTaskBloc, GuidedTaskState>(
    'Nevi arma los pasos: recarga la tarea ya guiada y lo avisa',
    setUp: () {
      when(
        () => generate(const GenerateGuidedStepsParams(taskId: 't1')),
      ).thenAnswer((_) async => const Right(null));
      when(() => getTask('t1')).thenAnswer((_) async => Right(guided));
    },
    build: build,
    seed: () => GuidedTaskSuccess(plain),
    act: (bloc) => bloc.add(const GuidedStepsGenerated()),
    expect: () => [
      GuidedTaskSuccess(plain, completing: true),
      isA<GuidedTaskSuccess>()
          .having((s) => s.task.steps.length, 'pasos', 2)
          .having((s) => s.message, 'aviso', contains('Nevi armó tus pasos')),
    ],
  );

  blocTest<GuidedTaskBloc, GuidedTaskState>(
    'si la IA falla, la tarea queda igual y explica qué hacer',
    setUp: () =>
        when(
          () => generate(const GenerateGuidedStepsParams(taskId: 't1')),
        ).thenAnswer(
          (_) async =>
              const Left(ServerFailure('Nevi no pudo armar los pasos ahora.')),
        ),
    build: build,
    seed: () => GuidedTaskSuccess(plain),
    act: (bloc) => bloc.add(const GuidedStepsGenerated()),
    expect: () => [
      GuidedTaskSuccess(plain, completing: true),
      GuidedTaskSuccess(plain, message: 'Nevi no pudo armar los pasos ahora.'),
    ],
  );

  blocTest<GuidedTaskBloc, GuidedTaskState>(
    '«Hablar con Nevi»: manda la nota y muestra su respuesta',
    setUp: () {
      when(
        () => generate(
          const GenerateGuidedStepsParams(
            taskId: 't1',
            note: 'No tengo escritorio',
          ),
        ),
      ).thenAnswer((_) async => const Right('Entiendo, usemos tu cama.'));
      when(() => getTask('t1')).thenAnswer((_) async => Right(guided));
    },
    build: build,
    seed: () => GuidedTaskSuccess(guided),
    act: (bloc) =>
        bloc.add(const GuidedStepsGenerated(note: 'No tengo escritorio')),
    skip: 1,
    expect: () => [
      isA<GuidedTaskSuccess>().having(
        (s) => s.message,
        'respuesta de Nevi',
        'Entiendo, usemos tu cama.',
      ),
    ],
  );

  blocTest<GuidedTaskBloc, GuidedTaskState>(
    'evidencia que coincide: Nevi tacha el paso y lo avisa',
    setUp: () {
      when(() => review(any())).thenAnswer(
        (_) async => Right(reviewOf(GuidedStepAssessment.supports)),
      );
      when(() => toggle('s1')).thenAnswer((_) async => const Right(false));
      when(() => getTask('t1')).thenAnswer((_) async => Right(guided));
    },
    build: build,
    seed: () => GuidedTaskSuccess(guided),
    act: (bloc) =>
        bloc.add(GuidedStepReviewRequested(stepId: 's1', evidence: evidence)),
    expect: () => [
      GuidedTaskSuccess(guided, reviewingStepId: 's1'),
      GuidedTaskSuccess(guided, busyStepId: 's1'),
      GuidedTaskSuccess(
        guided,
        message: 'Nevi confirmó el paso. ¡Sigue con el siguiente!',
      ),
    ],
    verify: (_) => verify(() => toggle('s1')).called(1),
  );

  blocTest<GuidedTaskBloc, GuidedTaskState>(
    'avance parcial: solo muestra la revisión, no marca nada',
    setUp: () => when(() => review(any())).thenAnswer(
      (_) async => Right(reviewOf(GuidedStepAssessment.partial)),
    ),
    build: build,
    seed: () => GuidedTaskSuccess(guided),
    act: (bloc) =>
        bloc.add(GuidedStepReviewRequested(stepId: 's1', evidence: evidence)),
    expect: () => [
      GuidedTaskSuccess(guided, reviewingStepId: 's1'),
      GuidedTaskSuccess(
        guided,
        review: reviewOf(GuidedStepAssessment.partial),
      ),
    ],
    verify: (_) => verifyNever(() => toggle(any())),
  );

  blocTest<GuidedTaskBloc, GuidedTaskState>(
    'coincide pero sin Foco: deja la revisión y explica por qué no avanzó',
    setUp: () {
      when(() => review(any())).thenAnswer(
        (_) async => Right(reviewOf(GuidedStepAssessment.supports)),
      );
      when(() => toggle('s1')).thenAnswer(
        (_) async => const Left(ServerFailure('Empieza en Foco para avanzar.')),
      );
    },
    build: build,
    seed: () => GuidedTaskSuccess(guided),
    act: (bloc) =>
        bloc.add(GuidedStepReviewRequested(stepId: 's1', evidence: evidence)),
    skip: 2,
    expect: () => [
      GuidedTaskSuccess(
        guided,
        review: reviewOf(GuidedStepAssessment.supports),
        message: 'Empieza en Foco para avanzar.',
      ),
    ],
  );
}

class _ToggleStub extends Mock implements ToggleGuidedStep {}

class _CompleteStub extends Mock implements CompleteGuidedTask {}

class _ReviewStub extends Mock implements ReviewGuidedStep {}

class _SetStub extends Mock implements SetGuidedSteps {}
