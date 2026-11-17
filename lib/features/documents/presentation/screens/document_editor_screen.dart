import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:share_plus/share_plus.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/documents/domain/code_highlight.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';
import 'package:proyecto_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:proyecto_movil/features/documents/presentation/blocs/document_editor_cubit.dart';
import 'package:proyecto_movil/features/documents/presentation/widgets/markdown_toolbar.dart';

/// Editor de un documento: escribir con la barra de formato o ver la vista
/// previa, y exportar a PDF o Word. Necesita un [DocumentEditorCubit] ya
/// abierto (lo provee el router).
class DocumentEditorScreen extends StatefulWidget {
  const DocumentEditorScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  final _controller = TextEditingController();
  var _preview = false;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    final doc = context.read<DocumentEditorCubit>().state.document;
    if (_loaded && doc != null && doc.content != _controller.text) {
      context.read<DocumentEditorCubit>().edit(content: _controller.text);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Imagen de la galería, ya guardada con el documento.
  Future<String?> _pickImage() async {
    final cubit = context.read<DocumentEditorCubit>();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return null;
    return cubit.addImage(file.path);
  }

  Future<void> _rename(String current) async {
    final cubit = context.read<DocumentEditorCubit>();
    final title = await askLifeQuestText(
      context,
      title: 'Título del documento',
      label: 'Título',
      confirmLabel: 'Guardar',
      initial: current,
      maxLength: 120,
    );
    if (title != null && title.trim().isNotEmpty) {
      cubit.edit(title: title.trim());
    }
  }

  /// Lista de copias; elegir una pide confirmación y la restaura.
  Future<void> _history() async {
    final cubit = context.read<DocumentEditorCubit>();
    final versions = await cubit.versions();
    if (!mounted) return;
    String when(DateTime t) {
      final d = t.toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    }

    final picked = await showQuestlySheet<WorkDocument>(
      context,
      title: 'Historial de versiones',
      child: Builder(
        builder: (context) {
          final q = context.q;
          if (versions.isEmpty) {
            return Text(
              'Aún no hay copias. Se guarda una cada vez que abres y '
              'cierras el documento.',
              style: QText.body(q.text2),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Toca una copia para volver a ella. Lo que tienes ahora se '
                'guarda antes en el historial.',
                style: QText.body(q.text2).copyWith(fontSize: 13),
              ),
              const SizedBox(height: QSpace.m),
              for (final v in versions)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.history_rounded, color: q.ink),
                  title: Text(when(v.updatedAt), style: QText.label(q.text)),
                  subtitle: Text(
                    '${v.title} · ${v.wordCount} palabras',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QText.body(q.text2).copyWith(fontSize: 13),
                  ),
                  onTap: () => Navigator.of(context).pop(v),
                ),
            ],
          );
        },
      ),
    );
    if (picked == null || !mounted) return;
    final ok = await confirmLifeQuest(
      context,
      title: '¿Volver a esta versión?',
      message:
          'El documento quedará como estaba el ${when(picked.updatedAt)}. '
          'Lo de ahora se guarda en el historial, por si lo necesitas.',
      confirmLabel: 'Restaurar',
    );
    if (ok) await cubit.restore(picked);
  }

  Future<void> _export() async {
    final cubit = context.read<DocumentEditorCubit>();
    final format = await showQuestlySheet<ExportFormat>(
      context,
      title: 'Descargar o compartir',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (context) => QuestlyButton(
              label: 'PDF',
              icon: QIcons.share,
              onPressed: () => Navigator.of(context).pop(ExportFormat.pdf),
            ),
          ),
          const SizedBox(height: QSpace.m),
          Builder(
            builder: (context) => QuestlyButton(
              label: 'Word (.docx)',
              icon: QIcons.share,
              variant: QuestlyButtonVariant.tonal,
              onPressed: () => Navigator.of(context).pop(ExportFormat.docx),
            ),
          ),
          const SizedBox(height: QSpace.s),
          Text(
            'Se abre el menú para guardarlo en Archivos o Drive, o enviarlo '
            'por WhatsApp o correo.',
            textAlign: TextAlign.center,
            style: QText.body(context.q.text2).copyWith(fontSize: 13),
          ),
        ],
      ),
    );
    if (format == null) return;
    final path = await cubit.export(format);
    if (path == null) return;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(path)], title: cubit.state.document?.title),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<DocumentEditorCubit, DocumentEditorState>(
    listenWhen: (a, b) =>
        (b.message != null) ||
        (a.document == null && b.document != null) ||
        a.revision != b.revision,
    listener: (context, state) {
      if (state.message != null) {
        showLifeQuestMessage(context, state.message!);
      }
      if (state.document != null &&
          (!_loaded || _controller.text != state.document!.content)) {
        // Al abrir o al restaurar una versión, el texto viene del cubit.
        _controller.text = state.document!.content;
        _loaded = true;
      }
    },
    builder: (context, state) {
      final q = context.q;
      final doc = state.document;
      if (state.notFound) {
        return LifeQuestErrorView(
          message: 'Este documento ya no existe.',
          onRetry: widget.onBack,
        );
      }
      if (doc == null) {
        return Center(child: CircularProgressIndicator(color: q.ink));
      }
      final status = switch (state.status) {
        SaveStatus.saved => 'Guardado',
        SaveStatus.pending => 'Guardando…',
        SaveStatus.failed => 'No se pudo guardar',
      };
      return Column(
        children: [
          QuestlyHero(
            kicker: '',
            heading: doc.title,
            onBack: widget.onBack,
            onAction: state.exporting ? null : _export,
            actionLabel: 'Descargar o compartir',
            actionIcon: QIcons.share,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: QuestlySegmented<bool>(
                    segments: const [(false, 'Editar'), (true, 'Vista previa')],
                    selected: _preview,
                    onChanged: (v) {
                      FocusScope.of(context).unfocus();
                      setState(() => _preview = v);
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Historial de versiones',
                  onPressed: _history,
                  icon: Icon(Icons.history_rounded, color: q.ink),
                ),
                IconButton(
                  tooltip: 'Cambiar título',
                  onPressed: () => _rename(doc.title),
                  icon: Icon(Icons.edit_outlined, color: q.ink),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Icon(
                  state.status == SaveStatus.failed
                      ? Icons.error_outline_rounded
                      : Icons.cloud_done_outlined,
                  size: 16,
                  color: state.status == SaveStatus.failed
                      ? q.coralInk
                      : q.text2,
                ),
                const SizedBox(width: 6),
                Text(
                  state.exporting
                      ? 'Preparando el archivo…'
                      : '$status · ${doc.wordCount} '
                            '${doc.wordCount == 1 ? 'palabra' : 'palabras'}',
                  style: QText.body(q.text2).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: QSpace.s),
          Expanded(
            child: _preview
                ? _Preview(
                    content: doc.content,
                    resolve: context.read<DocumentEditorCubit>().resolveImage,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _controller,
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: QText.body(q.text).copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        hintText:
                            'Empieza a escribir…\n\nUsa la barra de abajo '
                            'para títulos, listas, tablas y código.',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        hintStyle: QText.body(q.text2),
                      ),
                    ),
                  ),
          ),
          if (!_preview)
            MarkdownToolbar(controller: _controller, onImage: _pickImage),
        ],
      );
    },
  );
}

/// Colorea los bloques de código que indican lenguaje (```dart, ```python…).
/// El código en línea y los bloques sin lenguaje usan el estilo normal.
class _CodeBuilder extends MarkdownElementBuilder {
  _CodeBuilder(this.style);

  final TextStyle style;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final cls = element.attributes['class'] ?? '';
    if (!cls.startsWith('language-')) return null;
    final lines = highlightLines(
      element.textContent.replaceAll(RegExp(r'\n$'), ''),
      cls.substring(9),
    );
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (final (i, line) in lines.indexed) ...[
            if (i > 0) const TextSpan(text: '\n'),
            for (final t in line)
              TextSpan(
                text: t.text,
                style: t.color == null
                    ? null
                    : TextStyle(color: Color(t.color!)),
              ),
          ],
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.content, required this.resolve});

  final String content;

  /// Ruta local de una imagen del documento por su nombre.
  final Future<String?> Function(String name) resolve;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final theme = Theme.of(context);
    final code = QText.number(q.text, size: 13);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: content.trim().isEmpty
          ? Text('El documento está vacío.', style: QText.body(q.text2))
          : MarkdownBody(
              data: content,
              selectable: true,
              // Como en Word: cada Enter es una línea nueva.
              softLineBreak: true,
              builders: {'code': _CodeBuilder(code)},
              imageBuilder: (uri, title, alt) {
                final src = uri.toString();
                if (!src.startsWith('img/')) {
                  return Text(alt ?? '', style: QText.body(q.text2));
                }
                return FutureBuilder<String?>(
                  future: resolve(src.substring(4)),
                  builder: (context, snap) => switch (snap) {
                    AsyncSnapshot(:final String data) => ClipRRect(
                      borderRadius: BorderRadius.circular(QRadius.control),
                      child: Image.file(File(data), fit: BoxFit.contain),
                    ),
                    AsyncSnapshot(connectionState: ConnectionState.done) =>
                      Text(
                        'Imagen no disponible sin conexión',
                        style: QText.body(q.text2).copyWith(fontSize: 13),
                      ),
                    _ => SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(color: q.ink),
                      ),
                    ),
                  },
                );
              },
              styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: QText.body(q.text).copyWith(fontSize: 15),
                h1: QText.title1(q.ink).copyWith(fontSize: 26),
                h2: QText.title2(q.text),
                h3: QText.title3(q.text),
                code: code.copyWith(backgroundColor: q.tint),
                codeblockDecoration: BoxDecoration(
                  color: q.tint,
                  borderRadius: BorderRadius.circular(QRadius.control),
                ),
                codeblockPadding: const EdgeInsets.all(12),
                blockquoteDecoration: BoxDecoration(
                  border: Border(left: BorderSide(color: q.accent, width: 4)),
                ),
                blockquotePadding: const EdgeInsets.only(left: 12),
                tableBorder: TableBorder.all(color: q.border),
                tableHead: QText.label(q.text),
                tableBody: QText.body(q.text).copyWith(fontSize: 14),
                horizontalRuleDecoration: BoxDecoration(
                  border: Border(top: BorderSide(color: q.border, width: 1.5)),
                ),
              ),
            ),
    );
  }
}
