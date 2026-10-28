import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/inventory/data/models/inventory_board_model.dart';
import 'package:proyecto_movil/features/inventory/presentation/blocs/inventory_bloc.dart';

import '../../helpers/mocks.dart';

void main() {
  test('InventoryBoardModel convierte inventory_overview', () {
    final b = InventoryBoardModel.fromJson({
      'elixirs': 1,
      'elixir_active': true,
      'chests': 0,
      'passes': 2,
      'achievements': [
        {
          'id': 'a1',
          'name': 'Primer paso',
          'reward_coins': 50,
          'unlocked_at': '2026-10-27T10:00:00+00:00',
        },
        {'id': 'a2', 'name': 'Constante', 'reward_coins': 0},
      ],
      'titles': [
        {
          'id': 't1',
          'name': 'Matajefes',
          'earned_at': '2026-10-20T10:00:00+00:00',
        },
      ],
    }).toEntity();
    expect([b.elixirs, b.elixirActive, b.passes], [1, true, 2]);
    expect(b.achievements.map((a) => a.unlockedAt != null), [true, false]);
    expect(b.titles.single.name, 'Matajefes');
  });

  setUpAll(() => registerFallbackValue(const NoParams()));

  blocTest<InventoryBloc, InventoryState>(
    'si la primera carga falla, muestra el error',
    build: () {
      final getInventory = MockGetInventory();
      when(
        () => getInventory(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('Sin mochila.')));
      return InventoryBloc(getInventory: getInventory);
    },
    act: (bloc) => bloc.add(const InventoryRequested()),
    expect: () => [
      const InventoryLoading(),
      const InventoryFailure('Sin mochila.'),
    ],
  );
}
