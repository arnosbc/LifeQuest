import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/core/errors/failures.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/marketplace/data/datasources/marketplace_remote_datasource.dart';
import 'package:proyecto_movil/features/marketplace/data/models/market_board_model.dart';
import 'package:proyecto_movil/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:proyecto_movil/features/marketplace/domain/entities/market_board.dart';
import 'package:proyecto_movil/features/marketplace/domain/usecases/buy_black_market_item.dart';
import 'package:proyecto_movil/features/marketplace/presentation/blocs/marketplace_bloc.dart';

import '../../helpers/mocks.dart';

class _MockRemote extends Mock implements MarketplaceRemoteDataSource {}

const board = MarketBoard(
  coins: 120,
  items: [
    MarketItem(code: 'siesta', category: 'hotel', name: 'Siesta', cost: 30),
  ],
);

void main() {
  test('MarketBoardModel convierte market_overview', () {
    final entity = MarketBoardModel.fromJson({
      'coins': 250,
      'treasury': 10,
      'hp_current': 50,
      'hp_max': 100,
      'items': [
        {
          'code': 'elixir',
          'category': 'mercado',
          'name': 'Elixir de enfoque',
          'description': '×1,5',
          'cost': 40,
          'available': false,
        },
      ],
      'black_market': [
        {
          'code': 'pase_recuperacion',
          'name': 'Pase',
          'cost': 90,
          'available': true,
        },
      ],
      'elixirs_stored': 1,
      'elixir_active': false,
      'passes': 1,
      'broken_streaks': [
        {
          'habit_id': 'h1',
          'name': 'Leer',
          'streak': 6,
          'deadline': '2026-10-28T00:00:00+00:00',
        },
      ],
      'refuge': [
        {'building': 'huerto', 'level': 4, 'max_level': 4, 'price': null},
      ],
    }).toEntity();

    expect(entity.coins, 250);
    expect(entity.items.single.available, isFalse);
    expect(entity.blackMarket.single.category, 'mercado_negro');
    expect(entity.brokenStreaks.single.streak, 6);
    expect(entity.refuge.single.price, isNull);
  });

  test('MarketplaceRepositoryImpl traduce la falta de Monedas', () async {
    final remote = _MockRemote();
    when(
      () => remote.purchase('banquete'),
    ).thenThrow(const ServerException(code: 'not_enough_coins'));
    final result = await MarketplaceRepositoryImpl(remote).buyItem('banquete');
    expect(
      result,
      const Left<Failure, Unit>(
        ServerFailure(
          'Aún te faltan Monedas. Cada misión te acerca a este premio.',
        ),
      ),
    );
  });

  group('MarketplaceBloc', () {
    late MockGetMarketBoard getBoard;
    late MockBuyMarketItem buyItem;
    late MockBuyBlackMarketItem buyBlack;
    const failure = ServerFailure('Ya lo compraste hoy.');

    setUpAll(() {
      registerFallbackValue(const NoParams());
      registerFallbackValue(const BlackMarketParams('x'));
    });

    setUp(() {
      getBoard = MockGetMarketBoard();
      buyItem = MockBuyMarketItem();
      buyBlack = MockBuyBlackMarketItem();
      when(() => getBoard(any())).thenAnswer((_) async => const Right(board));
    });

    MarketplaceBloc build() => MarketplaceBloc(
      getBoard: getBoard,
      buyItem: buyItem,
      buyBlackMarket: buyBlack,
      usePass: MockUseRecoveryPass(),
      upgradeRefuge: MockUpgradeRefuge(),
      activateElixir: MockActivateElixir(),
    );

    blocTest<MarketplaceBloc, MarketplaceState>(
      'carga la Tienda',
      build: build,
      act: (bloc) => bloc.add(const MarketplaceRequested()),
      expect: () => [
        const MarketplaceLoading(),
        const MarketplaceSuccess(board),
      ],
    );

    blocTest<MarketplaceBloc, MarketplaceState>(
      'comprar marca el ítem ocupado y vuelve a leer la bolsa',
      setUp: () =>
          when(() => buyItem(any())).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const MarketplaceSuccess(board),
      act: (bloc) => bloc.add(const MarketItemBought('siesta')),
      expect: () => [
        const MarketplaceSuccess(board, busyKey: 'siesta'),
        const MarketplaceSuccess(board, message: '¡Disfrútalo! Te lo ganaste.'),
      ],
      verify: (_) => verify(() => getBoard(any())).called(1),
    );

    blocTest<MarketplaceBloc, MarketplaceState>(
      'si la compra falla, conserva los datos y avisa',
      setUp: () => when(
        () => buyItem(any()),
      ).thenAnswer((_) async => const Left(failure)),
      build: build,
      seed: () => const MarketplaceSuccess(board),
      act: (bloc) => bloc.add(const MarketItemBought('siesta')),
      expect: () => [
        const MarketplaceSuccess(board, busyKey: 'siesta'),
        MarketplaceSuccess(board, message: failure.message),
      ],
      verify: (_) => verifyNever(() => getBoard(any())),
    );

    blocTest<MarketplaceBloc, MarketplaceState>(
      'Recuperar racha envía el hábito',
      setUp: () => when(
        () => buyBlack(any()),
      ).thenAnswer((_) async => const Right(unit)),
      build: build,
      seed: () => const MarketplaceSuccess(board),
      act: (bloc) => bloc.add(
        const BlackMarketItemBought('recuperar_racha', habitId: 'h1'),
      ),
      verify: (_) => verify(
        () =>
            buyBlack(const BlackMarketParams('recuperar_racha', habitId: 'h1')),
      ).called(1),
    );
  });
}
