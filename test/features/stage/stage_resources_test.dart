import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'package:proyecto_movil/features/stage/data/models/stage_board_model.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';
import 'package:proyecto_movil/features/stage/domain/usecases/create_resource.dart';

import '../../helpers/mocks.dart';

void main() {
  test('StageBoardModel lee enlaces, notas y documentos con sus vínculos', () {
    final board = StageBoardModel.fromJson({
      'resources': [
        {
          'id': 'r1',
          'title': 'Apuntes de Bloc',
          'kind': 'note',
          'content': 'Un Bloc recibe eventos.',
          'project_title': 'App móvil',
          'skill_name': 'Estudio',
        },
        {
          'id': 'r2',
          'title': 'Plan',
          'kind': 'document',
          'path': 'u/n/plan.pdf',
          'bucket': 'npc-context',
          'npc_name': 'Ada',
        },
        // Fila de antes de 035: sin tipo, es un enlace.
        {'id': 'r3', 'title': 'Guía', 'url': 'https://example.com'},
      ],
    }).toEntity();

    final [note, doc, link] = board.resources;
    expect(
      [note.kind, note.content],
      [ResourceKind.note, 'Un Bloc recibe eventos.'],
    );
    expect(note.links, ['Proyecto: App móvil', 'Área: Estudio']);
    expect(
      [doc.kind, doc.path, doc.bucket],
      [ResourceKind.document, 'u/n/plan.pdf', 'npc-context'],
    );
    expect(doc.links, ['NPC: Ada']);
    expect([link.kind, link.url], [ResourceKind.link, 'https://example.com']);
  });

  group('CreateResource', () {
    late MockStageRepository repository;
    late CreateResource create;

    setUpAll(
      () => registerFallbackValue(
        const NewResource(title: 't', kind: ResourceKind.link),
      ),
    );

    setUp(() {
      repository = MockStageRepository();
      create = CreateResource(repository);
      when(
        () => repository.createResource(any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    NewResource doc(String name, int size) => NewResource(
      title: 'Doc',
      kind: ResourceKind.document,
      fileName: name,
      bytes: Uint8List(size),
    );

    test('guarda enlaces, notas y documentos válidos', () async {
      for (final r in [
        const NewResource(
          title: 'Docs',
          kind: ResourceKind.link,
          url: 'https://docs.flutter.dev',
        ),
        const NewResource(
          title: 'Idea',
          kind: ResourceKind.note,
          content: 'Algo que recordar',
          skillId: 's1',
        ),
        doc('enunciado.PDF', 10),
        doc('foto.jpg', 10),
      ]) {
        expect(await create(r), const Right(unit));
      }
      verify(() => repository.createResource(any())).called(4);
    });

    test('rechaza lo incompleto antes de subir nada', () async {
      for (final r in [
        const NewResource(
          title: ' ',
          kind: ResourceKind.link,
          url: 'https://x',
        ),
        const NewResource(title: 'X', kind: ResourceKind.link, url: 'ftp://x'),
        const NewResource(title: 'X', kind: ResourceKind.note, content: '  '),
        NewResource(
          title: 'X',
          kind: ResourceKind.note,
          content: 'x' * (NewResource.maxNoteLength + 1),
        ),
        const NewResource(title: 'X', kind: ResourceKind.document),
        doc('virus.exe', 10),
        doc('plan.pdf', NewResource.maxBytes + 1),
      ]) {
        expect((await create(r)).isLeft(), isTrue, reason: '${r.props}');
      }
      verifyNever(() => repository.createResource(any()));
    });
  });
}
