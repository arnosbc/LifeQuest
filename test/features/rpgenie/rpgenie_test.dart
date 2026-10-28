import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/rpgenie/data/models/rpgenie_board_model.dart';
import 'package:proyecto_movil/features/rpgenie/domain/entities/current_mission.dart';
import 'package:proyecto_movil/features/rpgenie/presentation/blocs/rpgenie_bloc.dart';

import '../../helpers/mocks.dart';

const board = RpgenieBoard(
  mission: CurrentMission(id: 't1', title: 'Pagar luz'),
  openCount: 2,
);

void main() {
  test('RpgenieBoardModel convierte current_mission', () {
    final entity = RpgenieBoardModel.fromJson({
      'mission': {
        'id': 't1',
        'title': 'Pagar luz',
        'reason': 'critical',
        'due_date': '2026-10-27T18:00:00+00:00',
        'xp_reward': 10,
        'coin_reward': 3,
      },
      'open_count': 3,
      'skipped_count': 1,
    }).toEntity();
    expect(entity.mission!.reason, MissionReason.critical);
    expect([entity.openCount, entity.skippedCount], [3, 1]);
    expect(
      RpgenieBoardModel.fromJson({'mission': null}).toEntity().mission,
      isNull,
    );
  });

  group('RpgenieBloc', () {
    late MockGetCurrentMission getMission;

    setUpAll(() => registerFallbackValue(<String>[]));

    setUp(() {
      getMission = MockGetCurrentMission();
      when(() => getMission(any())).thenAnswer((_) async => const Right(board));
    });

    RpgenieBloc build() => RpgenieBloc(
      getMission: getMission,
      completeMission: MockCompleteCurrentMission(),
    );

    blocTest<RpgenieBloc, RpgenieState>(
      '"Ahora no" pide otra sin la apartada, y limpiar las vuelve a incluir',
      build: build,
      seed: () => const RpgenieSuccess(board),
      act: (bloc) async {
        bloc.add(const MissionSkipped('t1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SkipsCleared());
      },
      verify: (_) {
        verifyInOrder([
          () => getMission(['t1']),
          () => getMission([]),
        ]);
      },
    );
  });
}
