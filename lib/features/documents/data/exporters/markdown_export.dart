import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:proyecto_movil/features/documents/domain/code_highlight.dart';

/// Convierte el Markdown de un documento a PDF y a Word (.docx) (RF-120).
/// Primero se pasa a bloques simples; los dos formatos dibujan esos bloques.

/// Trozo de texto con su formato.
class Run {
  const Run(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool code;
}

sealed class Block {
  const Block();
}

class HeadingBlock extends Block {
  const HeadingBlock(this.level, this.runs);
  final int level;
  final List<Run> runs;
}

class ParagraphBlock extends Block {
  const ParagraphBlock(this.runs);
  final List<Run> runs;
}

class ListItemBlock extends Block {
  const ListItemBlock(this.runs, {required this.marker, required this.depth});
  final List<Run> runs;

  /// «•» o «3.».
  final String marker;
  final int depth;
}

class QuoteBlock extends Block {
  const QuoteBlock(this.runs);
  final List<Run> runs;
}

class CodeBlock extends Block {
  const CodeBlock(this.lines, {this.language});
  final List<String> lines;

  /// El de ```dart, ```python…; null si no se indicó.
  final String? language;

  /// Líneas coloreadas según el lenguaje.
  List<List<CodeToken>> get highlighted =>
      highlightLines(lines.join('\n'), language);
}

class TableBlock extends Block {
  const TableBlock(this.rows);

  /// La primera fila es el encabezado.
  final List<List<List<Run>>> rows;
}

class RuleBlock extends Block {
  const RuleBlock();
}

/// Imagen del documento: `![alt](img/nombre)`.
class ImageBlock extends Block {
  const ImageBlock(this.name, this.alt);
  final String name;
  final String alt;
}

/// Prefijo de las imágenes guardadas con el documento.
const imagePrefix = 'img/';

/// Nombres de las imágenes que usa el texto.
Iterable<String> imageNames(String markdown) => RegExp(
  r'!\[[^\]]*\]\(img/([^)\s]+)\)',
).allMatches(markdown).map((m) => m.group(1)!).toSet();

/// Ancho y alto de una imagen PNG, JPEG o GIF leyendo su cabecera.
(int, int)? imageSize(Uint8List b) {
  int be16(int i) => (b[i] << 8) | b[i + 1];
  if (b.length > 24 && b[0] == 0x89 && b[1] == 0x50) {
    return ((be16(16) << 16) | be16(18), (be16(20) << 16) | be16(22));
  }
  if (b.length > 10 && b[0] == 0x47 && b[1] == 0x49) {
    return (b[6] | (b[7] << 8), b[8] | (b[9] << 8));
  }
  if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8) {
    var i = 2;
    while (i + 9 < b.length) {
      if (b[i] != 0xFF) return null;
      final marker = b[i + 1];
      final isSof =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isSof) return (be16(i + 7), be16(i + 5));
      i += 2 + be16(i + 2);
    }
  }
  return null;
}

/// Markdown (con tablas de GitHub) → bloques.
List<Block> parseBlocks(String markdown) {
  final nodes = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  ).parseLines(const LineSplitter().convert(markdown));
  final out = <Block>[];
  for (final node in nodes) {
    _block(node, out, depth: 0);
  }
  return out;
}

void _block(md.Node node, List<Block> out, {required int depth}) {
  if (node is md.Text) {
    if (node.text.trim().isNotEmpty) out.add(ParagraphBlock(_inline([node])));
    return;
  }
  if (node is! md.Element) return;
  switch (node.tag) {
    case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
      out.add(HeadingBlock(int.parse(node.tag[1]), _inline(node.children)));
    case 'p':
      final kids = node.children ?? const <md.Node>[];
      final images = kids.whereType<md.Element>().where(
        (e) =>
            e.tag == 'img' &&
            (e.attributes['src'] ?? '').startsWith(imagePrefix),
      );
      final onlyImages = kids.every(
        (k) =>
            (k is md.Element && k.tag == 'img') ||
            (k is md.Text && k.text.trim().isEmpty),
      );
      if (images.isNotEmpty && onlyImages) {
        for (final img in images) {
          out.add(
            ImageBlock(
              img.attributes['src']!.substring(imagePrefix.length),
              img.attributes['alt'] ?? '',
            ),
          );
        }
      } else {
        out.add(ParagraphBlock(_inline(node.children)));
      }
    case 'blockquote':
      final text = <Run>[];
      for (final child in node.children ?? const <md.Node>[]) {
        if (text.isNotEmpty) text.add(const Run('\n'));
        text.addAll(
          child is md.Element && child.tag == 'p'
              ? _inline(child.children)
              : _inline([child]),
        );
      }
      out.add(QuoteBlock(text));
    case 'pre':
      final code = node.textContent.replaceAll(RegExp(r'\n$'), '');
      final inner = node.children?.whereType<md.Element>().firstOrNull;
      final cls = inner?.attributes['class'] ?? '';
      out.add(
        CodeBlock(
          code.split('\n'),
          language: cls.startsWith('language-') ? cls.substring(9) : null,
        ),
      );
    case 'hr':
      out.add(const RuleBlock());
    case 'ul' || 'ol':
      var n = int.tryParse(node.attributes['start'] ?? '') ?? 1;
      for (final li in node.children ?? const <md.Node>[]) {
        if (li is! md.Element) continue;
        final runs = <Run>[];
        final nested = <md.Node>[];
        for (final child in li.children ?? const <md.Node>[]) {
          if (child is md.Element && (child.tag == 'ul' || child.tag == 'ol')) {
            nested.add(child);
          } else if (child is md.Element && child.tag == 'p') {
            runs.addAll(_inline(child.children));
          } else {
            runs.addAll(_inline([child]));
          }
        }
        out.add(
          ListItemBlock(
            runs,
            marker: node.tag == 'ol' ? '${n++}.' : '•',
            depth: depth,
          ),
        );
        for (final child in nested) {
          _block(child, out, depth: depth + 1);
        }
      }
    case 'table':
      final rows = <List<List<Run>>>[];
      void addRows(md.Element section) {
        for (final tr in section.children ?? const <md.Node>[]) {
          if (tr is! md.Element) continue;
          rows.add([
            for (final cell in tr.children ?? const <md.Node>[])
              if (cell is md.Element) _inline(cell.children),
          ]);
        }
      }
      for (final section in node.children ?? const <md.Node>[]) {
        if (section is md.Element) addRows(section);
      }
      if (rows.isNotEmpty) out.add(TableBlock(rows));
    default:
      out.add(ParagraphBlock(_inline(node.children)));
  }
}

List<Run> _inline(
  List<md.Node>? nodes, {
  bool bold = false,
  bool italic = false,
}) {
  final runs = <Run>[];
  for (final node in nodes ?? const <md.Node>[]) {
    if (node is md.Text) {
      runs.add(Run(node.text, bold: bold, italic: italic));
    } else if (node is md.Element) {
      switch (node.tag) {
        case 'strong':
          runs.addAll(_inline(node.children, bold: true, italic: italic));
        case 'em':
          runs.addAll(_inline(node.children, bold: bold, italic: true));
        case 'code':
          runs.add(Run(node.textContent, code: true));
        case 'br':
          runs.add(const Run('\n'));
        case 'input':
          runs.add(Run(node.attributes['checked'] != null ? '☑ ' : '☐ '));
        default:
          runs.addAll(_inline(node.children, bold: bold, italic: italic));
      }
    }
  }
  return runs;
}

// ---------------------------------------------------------------- PDF ----

/// Fuentes del PDF (DM Sans y DM Mono, ya incluidas en la app).
class PdfFonts {
  const PdfFonts({
    required this.regular,
    required this.bold,
    required this.mono,
  });

  final pw.Font regular;
  final pw.Font bold;
  final pw.Font mono;
}

Future<Uint8List> buildPdf({
  required String title,
  required String markdown,
  required PdfFonts fonts,

  /// Bytes de cada imagen por su nombre (las que falten se omiten).
  Map<String, Uint8List> images = const {},
}) {
  const ink = PdfColor.fromInt(0xFF2A2346);
  const accent = PdfColor.fromInt(0xFF5B3FA8);
  const soft = PdfColor.fromInt(0xFFF4F1FA);
  const line = PdfColor.fromInt(0xFFD9D2EA);

  pw.TextStyle base({double size = 11}) => pw.TextStyle(
    font: fonts.regular,
    fontSize: size,
    color: ink,
    lineSpacing: 2,
  );

  pw.Widget rich(
    List<Run> runs, {
    pw.TextStyle? style,
    bool bold = false,
  }) => pw.RichText(
    text: pw.TextSpan(
      style: style ?? base(),
      children: [
        for (final r in runs)
          pw.TextSpan(
            text: r.text,
            style: pw.TextStyle(
              font: r.code ? fonts.mono : (r.bold || bold ? fonts.bold : null),
              fontStyle: r.italic ? pw.FontStyle.italic : null,
              background: r.code ? const pw.BoxDecoration(color: soft) : null,
            ),
          ),
      ],
    ),
  );

  Iterable<pw.Widget> draw(Block b) sync* {
    switch (b) {
      case HeadingBlock(:final level, :final runs):
        final size = switch (level) {
          1 => 22.0,
          2 => 17.0,
          3 => 14.0,
          _ => 12.0,
        };
        yield pw.Padding(
          padding: pw.EdgeInsets.only(top: level == 1 ? 6 : 12, bottom: 6),
          child: rich(
            runs,
            style: pw.TextStyle(
              font: fonts.bold,
              fontSize: size,
              color: level == 1 ? accent : ink,
            ),
          ),
        );
      case ParagraphBlock(:final runs):
        yield pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: rich(runs),
        );
      case ListItemBlock(:final runs, :final marker, :final depth):
        yield pw.Padding(
          padding: pw.EdgeInsets.only(left: 16.0 * depth, bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(width: 18, child: pw.Text(marker, style: base())),
              pw.Expanded(child: rich(runs)),
            ],
          ),
        );
      case QuoteBlock(:final runs):
        yield pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.only(left: 10, top: 2, bottom: 2),
          decoration: const pw.BoxDecoration(
            border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
          ),
          child: rich(
            runs,
            style: base().copyWith(fontStyle: pw.FontStyle.italic),
          ),
        );
      case CodeBlock(:final lines, :final highlighted):
        // Una fila por línea: así un bloque largo se reparte entre páginas.
        for (final (i, tokens) in highlighted.indexed) {
          yield pw.Container(
            // A todo el ancho: el fondo del bloque queda parejo.
            width: double.infinity,
            color: soft,
            padding: pw.EdgeInsets.fromLTRB(
              10,
              i == 0 ? 8 : 0,
              10,
              i == lines.length - 1 ? 8 : 0,
            ),
            child: pw.RichText(
              text: pw.TextSpan(
                style: pw.TextStyle(
                  font: fonts.mono,
                  fontSize: 9.5,
                  color: ink,
                ),
                children: tokens.isEmpty
                    ? [const pw.TextSpan(text: ' ')]
                    : [
                        for (final t in tokens)
                          pw.TextSpan(
                            text: t.text,
                            style: t.color == null
                                ? null
                                : pw.TextStyle(
                                    color: PdfColor.fromInt(t.color!),
                                  ),
                          ),
                      ],
              ),
            ),
          );
        }
        yield pw.SizedBox(height: 8);
      case TableBlock(:final rows):
        yield pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Table(
            border: pw.TableBorder.all(color: line, width: 0.8),
            children: [
              for (final (i, row) in rows.indexed)
                pw.TableRow(
                  decoration: i == 0
                      ? const pw.BoxDecoration(color: soft)
                      : null,
                  children: [
                    for (final cell in row)
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: rich(cell, bold: i == 0),
                      ),
                  ],
                ),
            ],
          ),
        );
      case RuleBlock():
        yield pw.Divider(color: line, thickness: 0.8);
      case ImageBlock(:final name, :final alt):
        final bytes = images[name];
        if (bytes == null) {
          // Sin la imagen (sin red, borrada): queda su descripción.
          if (alt.isNotEmpty) yield pw.Text('[$alt]', style: base());
          break;
        }
        yield pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 8),
          child: pw.Center(
            child: pw.ConstrainedBox(
              constraints: const pw.BoxConstraints(maxHeight: 320),
              child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
            ),
          ),
        );
    }
  }

  final doc = pw.Document(title: title, creator: 'LifeQuest');
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(56),
      theme: pw.ThemeData.withFont(base: fonts.regular, bold: fonts.bold),
      build: (_) => [for (final b in parseBlocks(markdown)) ...draw(b)],
    ),
  );
  return doc.save();
}

// --------------------------------------------------------------- DOCX ----

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _runs(List<Run> runs, {bool bold = false}) {
  final b = StringBuffer();
  for (final r in runs) {
    final props = StringBuffer();
    if (r.bold || bold) props.write('<w:b/>');
    if (r.italic) props.write('<w:i/>');
    if (r.code) {
      props.write(
        '<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas" w:cs="Consolas"/>'
        '<w:shd w:val="clear" w:color="auto" w:fill="F4F1FA"/>',
      );
    }
    final parts = r.text.split('\n');
    for (final (i, part) in parts.indexed) {
      if (i > 0) b.write('<w:r><w:br/></w:r>');
      if (part.isEmpty) continue;
      b.write(
        '<w:r><w:rPr>$props</w:rPr>'
        '<w:t xml:space="preserve">${_esc(part)}</w:t></w:r>',
      );
    }
  }
  return b.toString();
}

/// Trozos de código con su color (el estilo Code ya pone Consolas).
String _codeRuns(List<CodeToken> tokens) => [
  for (final t in tokens)
    '<w:r><w:rPr>'
        '${t.color == null ? '' : '<w:color w:val="${_hex(t.color!)}"/>'}'
        '</w:rPr><w:t xml:space="preserve">${_esc(t.text)}</w:t></w:r>',
].join();

String _hex(int argb) =>
    (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

String _p(String content, {String? style, String extra = ''}) =>
    '<w:p><w:pPr>${style == null ? '' : '<w:pStyle w:val="$style"/>'}$extra'
    '</w:pPr>$content</w:p>';

/// Word (.docx) mínimo y válido: documento, estilos y relaciones.
Uint8List buildDocx({
  required String markdown,
  Map<String, Uint8List> images = const {},
}) {
  final body = StringBuffer();
  // Imágenes incrustadas: (nombre en word/media, bytes). Word no abre WebP.
  final media = <(String, Uint8List)>[];
  for (final b in parseBlocks(markdown)) {
    switch (b) {
      case HeadingBlock(:final level, :final runs):
        body.write(_p(_runs(runs), style: 'Heading${level.clamp(1, 3)}'));
      case ParagraphBlock(:final runs):
        body.write(_p(_runs(runs)));
      case ListItemBlock(:final runs, :final marker, :final depth):
        body.write(
          _p(
            _runs([Run('$marker '), ...runs]),
            extra: '<w:ind w:left="${360 * (depth + 1)}" w:hanging="360"/>',
          ),
        );
      case QuoteBlock(:final runs):
        body.write(_p(_runs(runs), style: 'Quote'));
      case CodeBlock(:final highlighted):
        for (final tokens in highlighted) {
          body.write(_p(_codeRuns(tokens), style: 'Code'));
        }
      case TableBlock(:final rows):
        final cols = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
        body.write(
          '<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/>'
          '<w:tblW w:w="5000" w:type="pct"/></w:tblPr><w:tblGrid>',
        );
        for (var i = 0; i < cols; i++) {
          body.write('<w:gridCol w:w="${9000 ~/ (cols == 0 ? 1 : cols)}"/>');
        }
        body.write('</w:tblGrid>');
        for (final (i, row) in rows.indexed) {
          body.write('<w:tr>');
          for (var c = 0; c < cols; c++) {
            final cell = c < row.length ? row[c] : const <Run>[];
            final shade = i == 0
                ? '<w:shd w:val="clear" w:color="auto" w:fill="F4F1FA"/>'
                : '';
            body.write(
              '<w:tc><w:tcPr>$shade</w:tcPr>'
              '${_p(_runs(cell, bold: i == 0))}</w:tc>',
            );
          }
          body.write('</w:tr>');
        }
        body.write('</w:tbl>${_p('')}');
      case RuleBlock():
        body.write(
          _p(
            '',
            extra:
                '<w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" '
                'w:color="D9D2EA"/></w:pBdr>',
          ),
        );
      case ImageBlock(:final name, :final alt):
        final bytes = images[name];
        final size = bytes == null ? null : imageSize(bytes);
        final ext = name.split('.').last.toLowerCase();
        if (bytes == null || size == null || ext == 'webp') {
          if (alt.isNotEmpty) body.write(_p(_runs([Run('[$alt]')])));
          break;
        }
        media.add(('image${media.length + 1}.$ext', bytes));
        final n = media.length;
        // 96 ppp → 9525 EMU por píxel; como mucho 15 cm de ancho.
        const maxCx = 5400000;
        var cx = size.$1 * 9525;
        var cy = size.$2 * 9525;
        if (cx > maxCx) {
          cy = cy * maxCx ~/ cx;
          cx = maxCx;
        }
        body.write(
          '<w:p><w:pPr><w:jc w:val="center"/></w:pPr><w:r><w:drawing>'
          '<wp:inline distT="0" distB="0" distL="0" distR="0">'
          '<wp:extent cx="$cx" cy="$cy"/>'
          '<wp:docPr id="$n" name="Imagen $n" descr="${_esc(alt)}"/>'
          '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
          '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
          '<pic:nvPicPr><pic:cNvPr id="$n" name="image$n.$ext"/><pic:cNvPicPr/>'
          '</pic:nvPicPr><pic:blipFill><a:blip r:embed="rIdImg$n"/>'
          '<a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
          '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/>'
          '</a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr>'
          '</pic:pic></a:graphicData></a:graphic></wp:inline></w:drawing></w:r></w:p>',
        );
    }
  }

  const ns =
      'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"';
  final document =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document $ns '
      'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
      'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
      '<w:body>$body'
      '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
      '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" '
      'w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>'
      '</w:body></w:document>';

  String heading(int n, int size) =>
      '<w:style w:type="paragraph" w:styleId="Heading$n">'
      '<w:name w:val="heading $n"/><w:basedOn w:val="Normal"/>'
      '<w:next w:val="Normal"/><w:qFormat/>'
      '<w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/>'
      '<w:outlineLvl w:val="${n - 1}"/></w:pPr>'
      '<w:rPr><w:b/><w:color w:val="${n == 1 ? '5B3FA8' : '2A2346'}"/>'
      '<w:sz w:val="$size"/></w:rPr></w:style>';

  final styles =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:styles $ns>'
      '<w:docDefaults><w:rPrDefault><w:rPr>'
      '<w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>'
      '<w:sz w:val="22"/><w:lang w:val="es-CO"/></w:rPr></w:rPrDefault>'
      '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="276" '
      'w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>'
      '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
      '<w:name w:val="Normal"/><w:qFormat/></w:style>'
      '${heading(1, 36)}${heading(2, 28)}${heading(3, 24)}'
      '<w:style w:type="paragraph" w:styleId="Quote"><w:name w:val="Quote"/>'
      '<w:basedOn w:val="Normal"/><w:pPr><w:ind w:left="720"/>'
      '<w:pBdr><w:left w:val="single" w:sz="18" w:space="8" w:color="5B3FA8"/>'
      '</w:pBdr></w:pPr><w:rPr><w:i/><w:color w:val="555066"/></w:rPr>'
      '</w:style>'
      '<w:style w:type="paragraph" w:styleId="Code"><w:name w:val="Code"/>'
      '<w:basedOn w:val="Normal"/><w:pPr><w:spacing w:after="0" w:line="240" '
      'w:lineRule="auto"/><w:shd w:val="clear" w:color="auto" w:fill="F4F1FA"/>'
      '</w:pPr><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas" '
      'w:cs="Consolas"/><w:sz w:val="19"/></w:rPr></w:style>'
      '<w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/>'
      '<w:tblPr><w:tblBorders>'
      '<w:top w:val="single" w:sz="4" w:space="0" w:color="BFB5D9"/>'
      '<w:left w:val="single" w:sz="4" w:space="0" w:color="BFB5D9"/>'
      '<w:bottom w:val="single" w:sz="4" w:space="0" w:color="BFB5D9"/>'
      '<w:right w:val="single" w:sz="4" w:space="0" w:color="BFB5D9"/>'
      '<w:insideH w:val="single" w:sz="4" w:space="0" w:color="BFB5D9"/>'
      '<w:insideV w:val="single" w:sz="4" w:space="0" w:color="BFB5D9"/>'
      '</w:tblBorders><w:tblCellMar><w:left w:w="100" w:type="dxa"/>'
      '<w:right w:w="100" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>'
      '</w:styles>';

  final contentTypes =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Default Extension="jpg" ContentType="image/jpeg"/>'
      '<Default Extension="jpeg" ContentType="image/jpeg"/>'
      '<Default Extension="png" ContentType="image/png"/>'
      '<Default Extension="gif" ContentType="image/gif"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
      '</Types>';
  const rels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';
  final docRels =
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
      '${[for (final (i, (file, _)) in media.indexed) '<Relationship Id="rIdImg${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/$file"/>'].join()}'
      '</Relationships>';

  final archive = Archive()
    ..add(ArchiveFile.string('[Content_Types].xml', contentTypes))
    ..add(ArchiveFile.string('_rels/.rels', rels))
    ..add(ArchiveFile.string('word/_rels/document.xml.rels', docRels))
    ..add(ArchiveFile.string('word/document.xml', document))
    ..add(ArchiveFile.string('word/styles.xml', styles));
  for (final (file, bytes) in media) {
    archive.add(ArchiveFile.bytes('word/media/$file', bytes));
  }
  return ZipEncoder().encodeBytes(archive);
}
