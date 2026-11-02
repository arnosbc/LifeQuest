import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Barra de formato del editor: inserta la sintaxis de Markdown donde está el
/// cursor o alrededor del texto seleccionado.
class MarkdownToolbar extends StatelessWidget {
  const MarkdownToolbar({super.key, required this.controller, this.onImage});

  final TextEditingController controller;

  /// Elige una imagen y devuelve el Markdown para insertarla (null: nada).
  final Future<String?> Function()? onImage;

  /// Pone [left]/[right] alrededor de la selección (o de un texto de ejemplo).
  void _wrap(String left, String right, String sample) {
    final v = controller.value;
    final sel = v.selection.isValid
        ? v.selection
        : TextSelection.collapsed(offset: v.text.length);
    final inner = sel.isCollapsed ? sample : sel.textInside(v.text);
    final text = v.text.replaceRange(sel.start, sel.end, '$left$inner$right');
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection(
        baseOffset: sel.start + left.length,
        extentOffset: sel.start + left.length + inner.length,
      ),
    );
  }

  /// Pone [prefix] al inicio de la línea del cursor.
  void _prefix(String prefix) {
    final v = controller.value;
    final at = v.selection.isValid ? v.selection.start : v.text.length;
    final lineStart = at == 0 ? 0 : v.text.lastIndexOf('\n', at - 1) + 1;
    controller.value = TextEditingValue(
      text: v.text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection.collapsed(offset: at + prefix.length),
    );
  }

  /// Inserta un bloque en su propia línea, separado del texto de alrededor.
  void _block(String block, {int cursorFromStart = 0}) {
    final v = controller.value;
    final at = v.selection.isValid ? v.selection.end : v.text.length;
    final before = at == 0 || v.text[at - 1] == '\n' ? '' : '\n';
    final insert = '$before\n$block\n';
    controller.value = TextEditingValue(
      text: v.text.replaceRange(at, at, insert),
      selection: TextSelection.collapsed(
        offset: at + before.length + 1 + cursorFromStart,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final tools = <(String, Widget, VoidCallback)>[
      ('Título', _Label('T1', q), () => _prefix('# ')),
      ('Subtítulo', _Label('T2', q), () => _prefix('## ')),
      (
        'Negrita',
        Icon(Icons.format_bold_rounded, color: q.text),
        () => _wrap('**', '**', 'texto'),
      ),
      (
        'Cursiva',
        Icon(Icons.format_italic_rounded, color: q.text),
        () => _wrap('_', '_', 'texto'),
      ),
      (
        'Lista',
        Icon(Icons.format_list_bulleted_rounded, color: q.text),
        () => _prefix('- '),
      ),
      (
        'Lista numerada',
        Icon(Icons.format_list_numbered_rounded, color: q.text),
        () => _prefix('1. '),
      ),
      (
        'Cita',
        Icon(Icons.format_quote_rounded, color: q.text),
        () => _prefix('> '),
      ),
      (
        'Código en línea',
        Icon(Icons.code_rounded, color: q.text),
        () => _wrap('`', '`', 'código'),
      ),
      (
        'Bloque de código',
        Icon(Icons.integration_instructions_outlined, color: q.text),
        () => _block('```\n\n```', cursorFromStart: 4),
      ),
      (
        'Tabla',
        Icon(Icons.grid_on_rounded, color: q.text),
        () => _block(
          '| Columna 1 | Columna 2 | Columna 3 |\n| --- | --- | --- |\n|  |  |  |\n|  |  |  |',
          cursorFromStart: 2,
        ),
      ),
      if (onImage case final pick?)
        (
          'Imagen',
          Icon(Icons.image_outlined, color: q.text),
          () async {
            final markdown = await pick();
            if (markdown != null) _block(markdown);
          },
        ),
      (
        'Separador',
        Icon(Icons.horizontal_rule_rounded, color: q.text),
        () => _block('---'),
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: q.card,
        border: Border(top: BorderSide(color: q.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            for (final (label, icon, onTap) in tools)
              IconButton(
                tooltip: label,
                onPressed: onTap,
                icon: icon,
                style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, this.q);

  final String text;
  final QuestlyPalette q;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: QText.label(q.text).copyWith(fontSize: 15));
}
