import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/documents/domain/entities/document_template.dart';
import 'package:proyecto_movil/features/documents/domain/entities/work_document.dart';
import 'package:proyecto_movil/features/documents/presentation/blocs/documents_cubit.dart';

/// Taller de documentos (RF-117…RF-122). Necesita un [DocumentsCubit].
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key, required this.onOpen});

  /// Abre el editor del documento con ese id; termina al volver.
  final Future<void> Function(String id) onOpen;

  Future<void> _open(BuildContext context, String id) async {
    await onOpen(id);
    // Al volver, la lista refleja lo que se escribió.
    if (context.mounted) await context.read<DocumentsCubit>().load();
  }

  Future<void> _new(BuildContext context) async {
    final cubit = context.read<DocumentsCubit>();
    final choice = await showQuestlySheet<(String, DocumentTemplate)>(
      context,
      title: 'Nuevo documento',
      child: const _NewDocumentForm(),
    );
    if (choice == null) return;
    final doc = await cubit.create(choice.$1, choice.$2);
    if (doc != null && context.mounted) await _open(context, doc.id);
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<DocumentsCubit, DocumentsState>(
        listenWhen: (_, s) => s.message != null,
        listener: (context, s) => showLifeQuestMessage(context, s.message!),
        builder: (context, state) {
          final q = context.q;
          final cubit = context.read<DocumentsCubit>();
          return RefreshIndicator(
            color: q.ink,
            onRefresh: cubit.load,
            child: LifeQuestPage(
              title: 'Documentos',
              icon: QIcons.book,
              subtitle: state.syncing
                  ? 'Sincronizando con la nube…'
                  : 'Tus trabajos, guardados en el teléfono y en la nube.',
              onAction: () => _new(context),
              actionLabel: 'Nuevo documento',
              children: [
                if (state.loading)
                  Center(child: CircularProgressIndicator(color: q.ink))
                else if (state.documents.isEmpty)
                  _Empty(onCreate: () => _new(context))
                else
                  for (final doc in state.documents) ...[
                    _DocumentCard(
                      document: doc,
                      onTap: () => _open(context, doc.id),
                      onRename: (title) => cubit.rename(doc, title),
                      onDelete: () => cubit.delete(doc),
                    ),
                    const SizedBox(height: QSpace.m),
                  ],
              ],
            ),
          );
        },
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QuestlyCard(
      child: Column(
        children: [
          QIcon(QIcons.book, color: q.ink, size: 40),
          const SizedBox(height: QSpace.m),
          Text('Aún no tienes documentos', style: QText.title3(q.text)),
          const SizedBox(height: QSpace.xs),
          Text(
            'Redacta aquí tus trabajos y entrégalos en PDF o Word.',
            textAlign: TextAlign.center,
            style: QText.body(q.text2).copyWith(fontSize: 14),
          ),
          const SizedBox(height: QSpace.l),
          QuestlyButton(
            label: 'Crear documento',
            icon: QIcons.plus,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final WorkDocument document;
  final VoidCallback onTap;
  final ValueChanged<String> onRename;
  final VoidCallback onDelete;

  /// Primera línea con texto, sin la sintaxis de Markdown.
  static String _preview(String content) {
    for (final line in content.split('\n')) {
      final text = line.replaceAll(RegExp(r'^[#>\-\s*|`0-9.]+'), '').trim();
      if (text.isNotEmpty && !text.startsWith('---')) return text;
    }
    return 'Documento vacío';
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final d = document.updatedAt.toLocal();
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return QuestlyCard(
      onTap: onTap,
      semanticsLabel: '${document.title}, editado el $date',
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: q.tint,
              borderRadius: BorderRadius.circular(QRadius.control),
            ),
            alignment: Alignment.center,
            child: QIcon(
              document.taskId == null ? QIcons.book : QIcons.flag,
              color: q.ink,
              size: 22,
            ),
          ),
          const SizedBox(width: QSpace.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QText.label(q.text),
                ),
                const SizedBox(height: 2),
                Text(
                  _preview(document.content),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QText.body(q.text2).copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  document.taskId == null ? date : '$date · De una tarea',
                  style: QText.meta(q.text2).copyWith(letterSpacing: 0),
                ),
              ],
            ),
          ),
          LifeQuestItemMenu(
            name: document.title,
            maxLength: 120,
            onRename: onRename,
            onDelete: onDelete,
            deleteMessage: 'Se borra en este teléfono y en la nube.',
          ),
        ],
      ),
    );
  }
}

/// Título y plantilla del documento nuevo; devuelve (título, plantilla).
class _NewDocumentForm extends StatefulWidget {
  const _NewDocumentForm();

  @override
  State<_NewDocumentForm> createState() => _NewDocumentFormState();
}

class _NewDocumentFormState extends State<_NewDocumentForm> {
  final _title = TextEditingController();
  var _template = DocumentTemplate.blank;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _title,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        const SizedBox(height: QSpace.s),
        Text('Plantilla', style: QText.title3(q.text)),
        const SizedBox(height: QSpace.s),
        for (final t in DocumentTemplate.values)
          Padding(
            padding: const EdgeInsets.only(bottom: QSpace.s),
            child: Semantics(
              selected: t == _template,
              button: true,
              child: InkWell(
                onTap: () => setState(() => _template = t),
                borderRadius: BorderRadius.circular(QRadius.block),
                child: Container(
                  padding: const EdgeInsets.all(QSpace.m),
                  decoration: BoxDecoration(
                    color: t == _template ? q.tint : q.card,
                    borderRadius: BorderRadius.circular(QRadius.block),
                    border: Border.all(
                      color: t == _template ? q.accent : q.border,
                      width: t == _template ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.label, style: QText.label(q.text)),
                            Text(
                              t.detail,
                              style: QText.body(q.text2).copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      if (t == _template)
                        Icon(Icons.check_circle_rounded, color: q.accent),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: QSpace.s),
        QuestlyButton(
          label: 'Crear',
          onPressed: () =>
              Navigator.of(context).pop((_title.text.trim(), _template)),
        ),
      ],
    );
  }
}
