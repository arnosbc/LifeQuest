import 'package:highlight/highlight.dart' show Node, highlight;

/// Trozo de código con su color (ARGB) o null si va en el color del texto.
typedef CodeToken = ({String text, int? color});

// Paleta legible sobre el fondo lavanda claro de los bloques de código.
const _colors = {
  'keyword': 0xFF7C3AED,
  'built_in': 0xFF0E7490,
  'type': 0xFF0E7490,
  'class': 0xFF0E7490,
  'literal': 0xFFB45309,
  'number': 0xFFB45309,
  'string': 0xFF15803D,
  'regexp': 0xFF15803D,
  'comment': 0xFF6B7280,
  'doctag': 0xFF6B7280,
  'title': 0xFF1D4ED8,
  'function': 0xFF1D4ED8,
  'meta': 0xFFBE185D,
  'attr': 0xFFB45309,
  'attribute': 0xFFB45309,
  'tag': 0xFF7C3AED,
  'name': 0xFF7C3AED,
  'symbol': 0xFFBE185D,
  'variable': 0xFFBE185D,
};

// Nombres que la gente escribe tras ``` y que highlight conoce con otro.
const _aliases = {
  'js': 'javascript',
  'ts': 'typescript',
  'py': 'python',
  'c++': 'cpp',
  'html': 'xml',
  'sh': 'bash',
  'shell': 'bash',
  'kt': 'kotlin',
  'c#': 'cs',
  'csharp': 'cs',
  'rb': 'ruby',
  'yml': 'yaml',
};

/// Código coloreado por línea. Sin lenguaje (o uno desconocido) queda en un
/// solo color.
List<List<CodeToken>> highlightLines(String code, String? language) {
  final tokens = <CodeToken>[];
  final lang = _aliases[language?.toLowerCase()] ?? language?.toLowerCase();
  List<Node>? nodes;
  if (lang != null && lang.isNotEmpty) {
    try {
      nodes = highlight.parse(code, language: lang).nodes;
    } catch (_) {
      nodes = null; // lenguaje que highlight no conoce
    }
  }
  void walk(List<Node> list, int? inherited) {
    for (final n in list) {
      final color = _colors[n.className] ?? inherited;
      if (n.value != null) tokens.add((text: n.value!, color: color));
      if (n.children != null) walk(n.children!, color);
    }
  }

  if (nodes == null) {
    tokens.add((text: code, color: null));
  } else {
    walk(nodes, null);
  }

  // Se parte en líneas sin perder el color de un trozo que cruza varias.
  final lines = <List<CodeToken>>[[]];
  for (final t in tokens) {
    final parts = t.text.split('\n');
    for (final (i, part) in parts.indexed) {
      if (i > 0) lines.add([]);
      if (part.isNotEmpty) lines.last.add((text: part, color: t.color));
    }
  }
  return lines;
}
