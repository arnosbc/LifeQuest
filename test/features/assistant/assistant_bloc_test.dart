import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/features/assistant/domain/entities/plan_entities.dart';
import 'package:proyecto_movil/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/apply_day_plan.dart';
import 'package:proyecto_movil/features/assistant/domain/usecases/get_day_plan.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/assistant_bloc.dart';

class _Repo extends Mock implements AssistantRepository {}

void main() {
  late _Repo repo;
  final now = DateTime(2026, 11, 5, 9);
  const task = PlanTask(id: 't', title: 'Leer');
  final block = ProposedBlock(
    taskId: 't',
    title: 'Leer',
    start: DateTime(2026, 11, 5, 9),
    minutes: 30,
  );
  final plan = DayPlan(mode: PlanMode.planDay, blocks: [block]);

  setUpAll(() {
    registerFallbackValue(<ProposedBlock>[]);
    registerFallbackValue(DateTime(2026));
  });
  setUp(() {
    repo = _Repo();
    when(repo.getOpenTasks).thenAnswer((_) async => const Right([task]));
    when(() => repo.getBusy(any(), any())).thenAnswer((_) async => const []);
  });

  AssistantBloc build() => AssistantBloc(
    getDayPlan: GetDayPlan(repo, clock: () => now),
    applyDayPlan: ApplyDayPlan(repo),
  );

  blocTest<AssistantBloc, AssistantState>(
    'calcula la propuesta con las reglas',
    build: build,
    act: (bloc) => bloc.add(const AssistantPlanRequested(PlanMode.planDay)),
    expect: () => [const AssistantLoading(), AssistantProposal(plan)],
  );

  blocTest<AssistantBloc, AssistantState>(
    'aceptar guarda los bloques y termina en Applied',
    setUp: () => when(
      () => repo.applyBlocks(any()),
    ).thenAnswer((_) async => const Right(unit)),
    build: build,
    seed: () => AssistantProposal(plan),
    act: (bloc) => bloc.add(const AssistantPlanAccepted()),
    expect: () => [
      AssistantProposal(plan, saving: true),
      const AssistantApplied(1),
    ],
    verify: (_) => verify(() => repo.applyBlocks([block])).called(1),
  );

  blocTest<AssistantBloc, AssistantState>(
    'si guardar falla, conserva la propuesta y avisa',
    setUp: () => when(
      () => repo.applyBlocks(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('sin red'))),
    build: build,
    seed: () => AssistantProposal(plan),
    act: (bloc) => bloc.add(const AssistantPlanAccepted()),
    expect: () => [
      AssistantProposal(plan, saving: true),
      AssistantProposal(plan, message: 'sin red'),
    ],
  );

  test('armar el día esquiva los eventos del calendario', () async {
    when(() => repo.getBusy(any(), any())).thenAnswer(
      (_) async => [Busy(DateTime(2026, 11, 5, 9), DateTime(2026, 11, 5, 10))],
    );
    final plan = await GetDayPlan(repo, clock: () => now)(PlanMode.planDay);
    expect(
      plan.getOrElse((_) => throw StateError('falló')).blocks.single.start,
      DateTime(2026, 11, 5, 10),
    );
    verify(
      () => repo.getBusy(DateTime(2026, 11, 5), DateTime(2026, 11, 7)),
    ).called(1);
  });
}
