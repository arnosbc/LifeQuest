import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/tavern/domain/entities/tavern_board.dart';

/// Lo que el usuario eligió en [NpcDocumentsSheet].
sealed class NpcDocumentsAction {
  const NpcDocumentsAction();
}

class AttachNpcDocument extends NpcDocumentsAction {
  const AttachNpcDocument(this.document);

  final NewNpcDocument document;
}

class RemoveNpcDocumentAction extends NpcDocumentsAction {
  const RemoveNpcDocumentAction(this.document);

  final NpcDocument document;
}

/// Documentos de contexto del NPC (p. ej. el plan de la asignatura): lista,
/// quitar y adjuntar uno nuevo en PDF, Word (.docx) o Markdown.
class NpcDocumentsSheet extends StatefulWidget {
  const NpcDocumentsSheet({super.key, required this.npc});

  final Npc npc;

  @override
  State<NpcDocumentsSheet> createState() => _NpcDocumentsSheetState();
}

class _NpcDocumentsSheetState extends State<NpcDocumentsSheet> {
  bool _picking = false;
  String? _error;

  Future<void> _pick() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Documento para ${widget.npc.name}',
        type: FileType.custom,
        allowedExtensions: NewNpcDocument.extensions,
      );
      if (file == null || !mounted) return;
      // Antes de leerlo: un archivo enorme no debe cargarse entero.
      if ((await file.length() ?? 0) > NewNpcDocument.maxBytes) {
        setState(
          () => _error =
              'El documento pesa más de 10 MB. Prueba con uno más ligero.',
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      Navigator.pop(
        context,
        AttachNpcDocument(
          NewNpcDocument(
            npcId: widget.npc.id,
            fileName: file.name,
            bytes: bytes,
          ),
        ),
      );
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'No pudimos abrir ese archivo. Prueba con otro.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final npc = widget.npc;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: context.lq.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    'Documentos de ${npc.name}',
                    style: TextStyle(
                      color: context.lq.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: context.lq.ink),
              ),
            ],
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Adjunta el plan de la asignatura u otro documento del tema. '
                    'RPGenie lo lee una vez y saca de él las misiones de '
                    '${npc.name}, siguiendo sus temas.',
                    style: TextStyle(color: context.lq.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  if (npc.documents.isEmpty)
                    const LifeQuestListRow(
                      icon: Icons.description_outlined,
                      title: 'Aún sin documentos',
                      subtitle: 'PDF, Word (.docx) o Markdown · máx. 10 MB',
                    ),
                  for (final doc in npc.documents)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: LifeQuestSurface(
                        child: Row(
                          children: [
                            const LifeQuestIconTile(Icons.description_outlined),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                doc.title,
                                style: TextStyle(
                                  color: context.lq.ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Quitar ${doc.title}',
                              onPressed: () => Navigator.pop(
                                context,
                                RemoveNpcDocumentAction(doc),
                              ),
                              icon: Icon(
                                Icons.delete_outline,
                                color: context.lq.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _picking || npc.documentsFull ? null : _pick,
                      icon: _picking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_outlined),
                      label: Text(
                        npc.documentsFull
                            ? 'Máximo ${NewNpcDocument.maxPerNpc} documentos'
                            : 'Adjuntar documento',
                      ),
                    ),
                  ),
                  if (_error case final error?) ...[
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: TextStyle(color: context.lq.ink, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: context.lq.muted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'No subas documentos personales. RPGenie usa la capa '
                          'gratis de Gemini y Google puede usar el texto para '
                          'mejorar sus modelos.',
                          style: TextStyle(
                            color: context.lq.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
