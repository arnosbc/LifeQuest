import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
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

  setUp(() {
    getTask = _Get();
    generate = _Generate();
  });

  GuidedTaskBloc build() => GuidedTaskBloc(
    getTask: getTask,
    toggleStep: _ToggleStub(),
    completeTask: _CompleteStub(),
    reviewStep: _ReviewStub(),
    setSteps: _SetStub(),
    generateSteps: generate,
  );

  blocTest<GuidedTaskBloc, GuidedTaskState>(
    'Nevi arma los pasos: recarga la tarea ya guiada y lo avisa',
    setUp: () {
      when(() => generate('t1')).thenAnswer((_) async => const Right(unit));
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
    setUp: () => when(() => generate('t1')).thenAnswer(
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
}

class _ToggleStub extends Mock implements ToggleGuidedStep {}

class _CompleteStub extends Mock implements CompleteGuidedTask {}

class _ReviewStub extends Mock implements ReviewGuidedStep {}

class _SetStub extends Mock implements SetGuidedSteps {}
