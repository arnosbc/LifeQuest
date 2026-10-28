import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/vision/data/models/vision_board_model.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';
import 'package:proyecto_movil/features/vision/domain/usecases/set_vision_link.dart';
import 'package:proyecto_movil/features/vision/presentation/blocs/vision_bloc.dart';

import '../../helpers/mocks.dart';

const item = VisionItem(
  kind: VisionItemKind.project,
  id: 'p1',
  title: 'Mudanza',
);
const board = VisionBoard(content: 'Vivir con calma', items: [item]);

void main() {
  test('VisionBoardModel convierte vision_overview', () {
    final entity = VisionBoardModel.fromJson({
      'content': 'Vivir con calma',
      'identity': 'Un aprendiz constante',
      'items': [
        {'kind': 'goal', 'id': 'g1', 'title': 'Maratón', 'linked': true},
      ],
    }).toEntity();
    expect(entity.identity, 'Un aprendiz constante');
    expect(
      entity.items.single,
      const VisionItem(
        kind: VisionItemKind.goal,
        id: 'g1',
        title: 'Maratón',
        linked: true,
      ),
    );
  });

  late MockGetVisionBoard getBoard;
  late MockSetVisionLink setLink;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const VisionLinkParams(item, linked: true));
  });

  setUp(() {
    getBoard = MockGetVisionBoard();
    setLink = MockSetVisionLink();
    when(() => getBoard(any())).thenAnswer((_) async => const Right(board));
    when(() => setLink(any())).thenAnswer((_) async => const Right(unit));
  });

  blocTest<VisionBloc, VisionState>(
    'vincular un proyecto envía el cambio y vuelve a leer',
    build: () => VisionBloc(
      getBoard: getBoard,
      save: MockSaveVision(),
      setLink: setLink,
    ),
    seed: () => const VisionSuccess(board),
    act: (bloc) => bloc.add(const VisionLinkToggled(item, linked: true)),
    expect: () => [
      const VisionSuccess(board, busyKey: 'p1'),
      const VisionSuccess(board, message: 'Ahora sirve a tu visión.'),
    ],
    verify: (_) => verify(
      () => setLink(const VisionLinkParams(item, linked: true)),
    ).called(1),
  );
}
