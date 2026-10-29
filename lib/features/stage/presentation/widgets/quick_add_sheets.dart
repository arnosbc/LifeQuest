import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// Qué eligió el usuario en Quick Add.
enum QuickAddKind { mission, project, goal, resource }

/// Hoja de Quick Add (RF-014): elige qué capturar.
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: '¿Qué quieres añadir?',
    children: [
      _option(
        context,
        QuickAddKind.mission,
        Icons.flag_outlined,
        'Misión',
        'Un paso concreto que puedes completar',
      ),
      _option(
        context,
        QuickAddKind.project,
        Icons.work_outline,
        'Proyecto',
        'Un resultado de semanas con varias misiones',
      ),
      _option(
        context,
        QuickAddKind.goal,
        Icons.emoji_events_outlined,
        'Meta',
        'Un logro de meses: se convierte en un jefe a derrotar',
      ),
      _option(
        context,
        QuickAddKind.resource,
        Icons.bookmark_border,
        'Recurso',
        'Un enlace de referencia para tus áreas',
      ),
    ],
  );

  Widget _option(
    BuildContext context,
    QuickAddKind kind,
    IconData icon,
    String title,
    String subtitle,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: LifeQuestIconTile(icon),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
    onTap: () => Navigator.pop(context, kind),
  );
}

/// Alta de proyecto; devuelve [NewProject] al guardar.
class CreateProjectSheet extends StatefulWidget {
  const CreateProjectSheet({
    super.key,
    required this.skills,
    required this.goals,
  });

  final List<StageLink> skills;
  final List<StageLink> goals;

  @override
  State<CreateProjectSheet> createState() => _CreateProjectSheetState();
}

class _CreateProjectSheetState extends State<CreateProjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  DateTime? _endDate;
  String? _skillId;
  String? _goalId;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      initialDate: _endDate ?? now.add(const Duration(days: 14)),
    );
    if (date != null && mounted) setState(() => _endDate = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      NewProject(
        title: _title.text.trim(),
        description: _description.text.trim(),
        endDate: _endDate,
        skillId: _skillId,
        goalId: _goalId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _formKey,
    child: _SheetFrame(
      title: 'Nuevo proyecto',
      children: [
        TextFormField(
          controller: _title,
          autofocus: true,
          maxLength: 200,
          decoration: const InputDecoration(
            labelText: 'Nombre del proyecto *',
            hintText: 'Lanzamiento de la app',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Escribe un nombre para el proyecto'
              : null,
        ),
        TextFormField(
          controller: _description,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Resultado esperado',
            hintText: '¿Cómo sabrás que terminó?',
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.event),
          label: Text(
            _endDate == null
                ? 'Fecha de fin (calcula la urgencia)'
                : 'Termina el ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
          ),
        ),
        const SizedBox(height: 8),
        _linkDropdown(
          'Área / skill',
          _skillId,
          widget.skills,
          (v) => setState(() => _skillId = v),
        ),
        const SizedBox(height: 8),
        _linkDropdown(
          'Meta (completarlo le resta vida al jefe)',
          _goalId,
          widget.goals,
          (v) => setState(() => _goalId = v),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('Crear proyecto'),
          ),
        ),
      ],
    ),
  );

  Widget _linkDropdown(
    String label,
    String? value,
    List<StageLink> links,
    ValueChanged<String?> onChanged,
  ) => DropdownButtonFormField<String?>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      const DropdownMenuItem(value: null, child: Text('Sin vincular')),
      for (final link in links)
        DropdownMenuItem(
          value: link.id,
          child: Text(link.name, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );
}

/// Marco común de las hojas: fondo, título y espacio para el teclado.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.lq.background,
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    padding: EdgeInsets.fromLTRB(
      20,
      16,
      20,
      24 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: context.lq.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
}
