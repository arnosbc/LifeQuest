import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/documents/data/datasources/documents_local_datasource.dart';
import 'package:proyecto_movil/features/documents/data/datasources/documents_remote_datasource.dart';
import 'package:proyecto_movil/features/documents/data/exporters/markdown_export.dart';
import 'package:proyecto_movil/features/documents/domain/code_highlight.dart';
import 'package:proyecto_movil/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:proyecto_movil/features/documents/domain/entities/document_template.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';
import 'package:proyecto_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:proyecto_movil/features/documents/domain/usecases/documents_usecases.dart';
import 'package:proyecto_movil/features/documents/presentation/blocs/document_editor_cubit.dart';

class _MockRepo extends Mock implements DocumentsRepository {}

class _MockRemote extends Mock implements DocumentsRemoteDataSource {}

/// Historial en memoria para probar el repositorio sin tocar el disco.
class _FakeLocal implements DocumentsLocalDataSource {
  final saved = <WorkDocument>[];

  @override
  Future<void> addVersion(WorkDocument document, {int keep = 30}) async =>
      saved.add(document);

  @override
  Future<List<WorkDocument>> versions(String documentId) async =>
      saved.reversed.toList();

  @override
  Future<List<WorkDocument>> readAll() async => const [];

  @override
  Future<void> write(WorkDocument document) async {}

  @override
  Future<Directory> exportDir() async => Directory.systemTemp;

  // Imágenes: nombre → subida o no.
  final images = <String, bool>{};

  @override
  Future<String> addImage(String documentId, String sourcePath) async {
    images['foto.jpg'] = false;
    return 'foto.jpg';
  }

  @override
  Future<File?> imageFile(String documentId, String name) async =>
      images.containsKey(name) ? File(name) : null;

  @override
  Future<File> saveImage(String documentId, String name, List<int> b) async {
    images[name] = true;
    return File(name);
  }

  @override
  Future<List<(String, String, File)>> pendingImages() async => [
    for (final e in images.entries)
      if (!e.value) ('d', e.key, File(e.key)),
  ];

  @override
  Future<void> markUploaded(String documentId, String name) async =>
      images[name] = true;
}

WorkDocument doc(String id, int minute, {bool deleted = false}) => WorkDocument(
  id: id,
  title: 'Doc $id',
  content: '# $id',
  updatedAt: DateTime.utc(2026, 10, 31, 12, minute),
  deletedAt: deleted ? DateTime.utc(2026, 10, 31, 12, minute) : null,
);

void main() {
  group('planSync', () {
    test('gana el más reciente y copia lo que falta de cada lado', () {
      final plan = planSync(
        [doc('a', 5), doc('b', 1), doc('local', 3)],
        [doc('a', 2), doc('b', 9), doc('nube', 4)],
      );
      expect(plan.push.map((d) => d.id), unorderedEquals(['a', 'local']));
      expect(plan.pull.map((d) => d.id), unorderedEquals(['b', 'nube']));
      expect(plan.merged.map((d) => d.id), ['b', 'a', 'nube', 'local']);
    });

    test('un borrado más nuevo se sincroniza y no se muestra', () {
      final plan = planSync([doc('a', 8, deleted: true)], [doc('a', 2)]);
      expect(plan.push.single.isDeleted, isTrue);
      expect(plan.merged, isEmpty);
    });

    test('iguales: no se mueve nada', () {
      final plan = planSync([doc('a', 1)], [doc('a', 1)]);
      expect(plan.push, isEmpty);
      expect(plan.pull, isEmpty);
      expect(plan.merged.single.id, 'a');
    });
  });

  group('exportación', () {
    const markdown =
        '# Informe\n\nTexto con **negrita** y `código`.\n\n'
        '- uno\n- dos\n  - anidado\n\n1. primero\n\n> una cita\n\n'
        '| A | B |\n| --- | --- |\n| 1 | 2 |\n\n```dart\nvoid main() {}\n```\n\n---\n';

    test('los bloques reconocen títulos, listas, tablas, código y citas', () {
      final blocks = parseBlocks(markdown);
      expect(blocks.whereType<HeadingBlock>().single.level, 1);
      expect(blocks.whereType<ListItemBlock>().map((b) => b.marker), [
        '•',
        '•',
        '•',
        '1.',
      ]);
      expect(blocks.whereType<ListItemBlock>().elementAt(2).depth, 1);
      expect(blocks.whereType<TableBlock>().single.rows.length, 2);
      expect(blocks.whereType<CodeBlock>().single.lines, ['void main() {}']);
      expect(blocks.whereType<QuoteBlock>(), hasLength(1));
      expect(blocks.whereType<RuleBlock>(), hasLength(1));
    });

    test('el .docx es un zip válido con el contenido y sus estilos', () {
      final zip = ZipDecoder().decodeBytes(buildDocx(markdown: markdown));
      final names = zip.files.map((f) => f.name).toSet();
      expect(
        names,
        containsAll([
          '[Content_Types].xml',
          '_rels/.rels',
          'word/document.xml',
          'word/styles.xml',
          'word/_rels/document.xml.rels',
        ]),
      );
      final xml = utf8.decode(zip.findFile('word/document.xml')!.content);
      expect(xml, contains('<w:pStyle w:val="Heading1"/>'));
      expect(xml, contains('<w:tbl>'));
      expect(xml, contains('<w:pStyle w:val="Code"/>'));
      expect(xml, contains('<w:b/>'));
      expect(xml, contains('negrita'));
    });

    test('cada salto de línea se respeta en el .docx', () {
      final zip = ZipDecoder().decodeBytes(
        buildDocx(markdown: '**Materia:** Física\n**Fecha:** hoy'),
      );
      final xml = utf8.decode(zip.findFile('word/document.xml')!.content);
      expect(xml, contains('<w:br/>'));
    });

    test('los caracteres especiales se escapan en el .docx', () {
      final zip = ZipDecoder().decodeBytes(buildDocx(markdown: 'a < b & c'));
      final xml = utf8.decode(zip.findFile('word/document.xml')!.content);
      expect(xml, contains('a &lt; b &amp; c'));
    });

    test('el PDF se genera', () async {
      final font = pw.Font.helvetica();
      final bytes = await buildPdf(
        title: 'Informe',
        markdown: markdown,
        fonts: PdfFonts(regular: font, bold: font, mono: pw.Font.courier()),
      );
      expect(utf8.decode(bytes.sublist(0, 5), allowMalformed: true), '%PDF-');
    });
  });

  test('las plantillas rellenan título y fecha', () {
    final body = DocumentTemplate.report.body(
      title: 'Fotosíntesis',
      date: DateTime(2026, 10, 31),
    );
    expect(body, startsWith('# Fotosíntesis'));
    expect(body, contains('31/10/2026'));
    expect(body, contains('| Variable | Valor |'));
  });

  test('el código se colorea según el lenguaje y respeta las líneas', () {
    final lines = highlightLines("void main() {\n  print('hola');\n}", 'dart');
    expect(lines, hasLength(3));
    final first = lines.first;
    expect(first.firstWhere((t) => t.text == 'void').color, isNotNull);
    final plain = highlightLines('x = 1', 'lenguaje-inventado');
    expect(plain.single.single.color, isNull);
  });

  test('el contador de palabras ignora la sintaxis de Markdown', () {
    final d = doc('a', 0).copyWith(
      content: '# Título\n\n**Hola** mundo, ¿qué tal? | celda |\n- uno',
    );
    expect(d.wordCount, 7);
  });

  group('imágenes', () {
    setUpAll(() => registerFallbackValue(Uint8List(0)));

    test('se encuentran en el texto y se vuelven bloques', () {
      const text =
          'Hola\n\n![Gráfica](img/a.png)\n\n![otra](https://x.com/b.png)';
      expect(imageNames(text), ['a.png']);
      final img = parseBlocks(text).whereType<ImageBlock>().single;
      expect((img.name, img.alt), ('a.png', 'Gráfica'));
    });

    test('lee ancho y alto de PNG y JPEG', () {
      final png = Uint8List(32)
        ..setAll(0, [0x89, 0x50, 0x4E, 0x47])
        ..setAll(16, [0, 0, 0x01, 0x40, 0, 0, 0, 0xF0]); // 320 × 240
      expect(imageSize(png), (320, 240));
      final jpg = Uint8List.fromList([
        0xFF, 0xD8, // SOI
        0xFF, 0xE0, 0x00, 0x04, 0x00, 0x00, // APP0 de 4 bytes
        0xFF,
        0xC0,
        0x00,
        0x11,
        0x08,
        0x01,
        0xE0,
        0x02,
        0x80,
        0,
        0,
        0, // 640 × 480
      ]);
      expect(imageSize(jpg), (640, 480));
    });

    test('el .docx incrusta la imagen con su relación', () {
      final png = Uint8List(32)
        ..setAll(0, [0x89, 0x50, 0x4E, 0x47])
        ..setAll(16, [0, 0, 0, 100, 0, 0, 0, 50]);
      final zip = ZipDecoder().decodeBytes(
        buildDocx(markdown: '![Mapa](img/m.png)', images: {'m.png': png}),
      );
      expect(zip.findFile('word/media/image1.png'), isNotNull);
      final rels = utf8.decode(
        zip.findFile('word/_rels/document.xml.rels')!.content,
      );
      expect(rels, contains('Target="media/image1.png"'));
      final xml = utf8.decode(zip.findFile('word/document.xml')!.content);
      expect(xml, contains('r:embed="rIdImg1"'));
      expect(xml, contains('cx="952500" cy="476250"'));
    });

    test('sin la imagen, el .docx deja su descripción', () {
      final zip = ZipDecoder().decodeBytes(
        buildDocx(markdown: '![Mapa](img/m.png)'),
      );
      final xml = utf8.decode(zip.findFile('word/document.xml')!.content);
      expect(xml, contains('[Mapa]'));
      expect(zip.findFile('word/media/image1.png'), isNull);
    });

    test('agregar una imagen sin red no falla y queda pendiente', () async {
      final local = _FakeLocal();
      final remote = _MockRemote();
      when(
        () => remote.uploadImage(any(), any(), any()),
      ).thenThrow(const NetworkException('sin red'));
      final repo = DocumentsRepositoryImpl(local, remote);
      final result = await repo.addImage('d', '/galeria/foto.jpg');
      expect(result.toNullable(), 'foto.jpg');
      expect(await local.pendingImages(), hasLength(1));
    });
  });

  group('historial (repositorio)', () {
    test('no guarda una copia igual a la última', () async {
      final local = _FakeLocal();
      final repo = DocumentsRepositoryImpl(local, _MockRemote());
      final d = doc('a', 1);
      await repo.snapshot(d);
      await repo.snapshot(d.copyWith(updatedAt: DateTime.utc(2027)));
      await repo.snapshot(d.copyWith(content: 'cambio'));
      expect(local.saved.map((v) => v.content), ['# a', 'cambio']);
    });
  });

  group('DocumentEditorCubit', () {
    late _MockRepo repo;

    setUpAll(() {
      registerFallbackValue(DocumentTemplate.blank);
      registerFallbackValue(doc('x', 0));
    });

    setUp(() {
      repo = _MockRepo();
      when(
        () => repo.snapshot(any()),
      ).thenAnswer((_) async => const Right(unit));
    });

    DocumentEditorCubit build() => DocumentEditorCubit(
      getLocal: GetLocalDocuments(repo),
      create: CreateDocument(repo),
      save: SaveDocument(repo),
      export: ExportDocument(repo),
      snapshot: SnapshotDocument(repo),
      versions: GetDocumentVersions(repo),
      addImage: AddDocumentImage(repo),
      resolveImage: ResolveDocumentImage(repo),
    );

    test(
      'restaurar guarda lo actual en el historial y vuelve a la copia',
      () async {
        when(
          () => repo.getLocal(),
        ).thenAnswer((_) async => Right([doc('a', 1)]));
        when(() => repo.save(any())).thenAnswer(
          (i) async => Right(i.positionalArguments.first as WorkDocument),
        );
        final cubit = build();
        await cubit.open(id: 'a');
        cubit.edit(content: 'versión nueva');
        final old = doc('a', 0).copyWith(content: 'versión vieja');
        await cubit.restore(old);
        expect(cubit.state.document!.content, 'versión vieja');
        expect(cubit.state.revision, 1);
        expect(cubit.state.status, SaveStatus.saved);
        final snaps = verify(() => repo.snapshot(captureAny())).captured;
        expect(
          snaps.map((d) => (d as WorkDocument).content),
          contains('versión nueva'),
        );
        await cubit.close();
      },
    );

    test('abrir una tarea sin documento lo crea con el título', () async {
      final created = WorkDocument(
        id: 'n',
        title: 'Ensayo',
        content: '',
        updatedAt: DateTime.utc(2026),
        taskId: 't1',
      );
      when(() => repo.getLocal()).thenAnswer((_) async => const Right([]));
      when(
        () => repo.create(
          title: any(named: 'title'),
          template: any(named: 'template'),
          taskId: any(named: 'taskId'),
        ),
      ).thenAnswer((_) async => Right(created));
      final cubit = build();
      await cubit.open(taskId: 't1', title: 'Ensayo');
      expect(cubit.state.document, created);
      verify(
        () => repo.create(
          title: 'Ensayo',
          template: DocumentTemplate.blank,
          taskId: 't1',
        ),
      ).called(1);
      await cubit.close();
    });

    test('escribir guarda una sola vez tras la pausa', () async {
      when(() => repo.getLocal()).thenAnswer((_) async => Right([doc('a', 1)]));
      when(() => repo.save(any())).thenAnswer(
        (i) async => Right(i.positionalArguments.first as WorkDocument),
      );
      final cubit = build();
      await cubit.open(id: 'a');
      cubit
        ..edit(content: 'h')
        ..edit(content: 'ho')
        ..edit(content: 'hola');
      expect(cubit.state.status, SaveStatus.pending);
      await Future<void>.delayed(
        DocumentEditorCubit.debounce + const Duration(milliseconds: 100),
      );
      expect(cubit.state.status, SaveStatus.saved);
      final saved =
          verify(() => repo.save(captureAny())).captured.single as WorkDocument;
      expect(saved.content, 'hola');
      await cubit.close();
    });

    test('un id que no existe avisa', () async {
      when(() => repo.getLocal()).thenAnswer((_) async => const Right([]));
      final cubit = build();
      await cubit.open(id: 'nada');
      expect(cubit.state.notFound, isTrue);
      await cubit.close();
    });
  });
}
