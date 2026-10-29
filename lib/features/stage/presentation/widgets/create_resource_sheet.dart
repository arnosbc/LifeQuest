import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_resource.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// Alta de recurso (035): un enlace, una nota o un documento, vinculado si se
/// quiere a un Proyecto, una Meta o una Skill. Devuelve [NewResource].
class CreateResourceSheet extends StatefulWidget {
  const CreateResourceSheet({
    super.key,
    this.projects = const [],
    this.goals = const [],
    this.skills = const [],
  });

  final List<StageLink> projects;
  final List<StageLink> goals;
  final List<StageLink> skills;

  @override
  State<CreateResourceSheet> createState() => _CreateResourceSheetState();
}

class _CreateResourceSheetState extends State<CreateResourceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _content = TextEditingController();
  ResourceKind _kind = ResourceKind.link;
  String? _fileName;
  Uint8List? _bytes;
  String? _fileError;
  bool _picking = false;
  String? _projectId;
  String? _goalId;
  String? _skillId;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() {
      _picking = true;
      _fileError = null;
    });
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Documento para tus Recursos',
        type: FileType.custom,
        allowedExtensions: NewResource.extensions,
      );
      if (file == null || !mounted) return;
      if ((await file.length() ?? 0) > NewResource.maxBytes) {
        setState(
          () => _fileError =
              'El documento pesa más de 10 MB. Prueba con uno más ligero.',
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _bytes = bytes;
        // Sin nombre escrito, el del archivo (sin extensión).
        if (_title.text.trim().isEmpty) {
          final dot = file.name.lastIndexOf('.');
          _title.text = dot > 0 ? file.name.substring(0, dot) : file.name;
        }
      });
    } on Exception {
      if (mounted) {
        setState(
          () => _fileError = 'No pudimos abrir ese archivo. Prueba con otro.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _save() {
    final valid = _formKey.currentState!.validate();
    final missingFile = _kind == ResourceKind.document && _bytes == null;
    if (missingFile) {
      setState(() => _fileError = 'Elige el documento que quieres guardar.');
    }
    if (!valid || missingFile) return;
    Navigator.pop(
      context,
      NewResource(
        title: _title.text.trim(),
        kind: _kind,
        url: _kind == ResourceKind.link ? _url.text.trim() : null,
        content: _kind == ResourceKind.note ? _content.text.trim() : null,
        fileName: _kind == ResourceKind.document ? _fileName : null,
        bytes: _kind == ResourceKind.document ? _bytes : null,
        projectId: _projectId,
        goalId: _goalId,
        skillId: _skillId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.lq.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
    ),
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            Text(
              'Nuevo recurso',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.lq.ink,
              ),
            ),
            SegmentedButton<ResourceKind>(
              segments: const [
                ButtonSegment(
                  value: ResourceKind.link,
                  icon: Icon(Icons.link),
                  label: Text('Enlace'),
                ),
                ButtonSegment(
                  value: ResourceKind.note,
                  icon: Icon(Icons.notes),
                  label: Text('Nota'),
                ),
                ButtonSegment(
                  value: ResourceKind.document,
                  icon: Icon(Icons.description_outlined),
                  label: Text('Documento'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() {
                _kind = s.first;
                _fileError = null;
              }),
            ),
            TextFormField(
              controller: _title,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Nombre *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Escribe un nombre' : null,
            ),
            ...switch (_kind) {
              ResourceKind.link => [
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Enlace *',
                    hintText: 'https://…',
                  ),
                  validator: (v) =>
                      RegExp(
                        r'^https?://\S+$',
                        caseSensitive: false,
                      ).hasMatch(v?.trim() ?? '')
                      ? null
                      : 'Escribe un enlace que empiece por http:// o https://',
                ),
              ],
              ResourceKind.note => [
                TextFormField(
                  controller: _content,
                  minLines: 5,
                  maxLines: 12,
                  maxLength: NewResource.maxNoteLength,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Nota *',
                    hintText: 'Apuntes, ideas, lo que quieras recordar…',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Escribe el contenido de la nota'
                      : null,
                ),
              ],
              ResourceKind.document => [_filePicker(context)],
            },
            _chips(
              context,
              'Proyecto',
              widget.projects,
              _projectId,
              (id) => setState(() => _projectId = id),
            ),
            _chips(
              context,
              'Meta',
              widget.goals,
              _goalId,
              (id) => setState(() => _goalId = id),
            ),
            _chips(
              context,
              'Área / skill',
              widget.skills,
              _skillId,
              (id) => setState(() => _skillId = id),
            ),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Guardar recurso'),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _filePicker(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 6,
    children: [
      SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: _picking ? null : _pickFile,
          icon: _picking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined),
          label: Text(
            _fileName ?? 'Elegir documento *',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Text(
        _fileError ??
            'PDF, Word, Excel, PowerPoint, Markdown, texto o imagen · máx. 10 MB',
        style: TextStyle(
          color: _fileError == null ? context.lq.muted : context.lq.error,
          fontSize: 12,
        ),
      ),
    ],
  );

  /// Vínculo opcional como chips: todo a la vista, «Sin vincular» por defecto.
  /// Si no hay opciones no se muestra.
  Widget _chips(
    BuildContext context,
    String label,
    List<StageLink> options,
    String? selected,
    ValueChanged<String?> onSelected,
  ) => options.isEmpty
      ? const SizedBox.shrink()
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(
              'Vincular a $label',
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Sin vincular'),
                  selected: selected == null,
                  onSelected: (_) => onSelected(null),
                ),
                for (final o in options)
                  ChoiceChip(
                    label: Text(o.name, overflow: TextOverflow.ellipsis),
                    selected: selected == o.id,
                    onSelected: (_) => onSelected(o.id),
                  ),
              ],
            ),
          ],
        );
}
