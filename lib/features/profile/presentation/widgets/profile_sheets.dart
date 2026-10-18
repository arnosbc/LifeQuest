import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Lo que el usuario decide en el formulario de una skill.
sealed class SkillSheetResult {
  const SkillSheetResult();
}

class SkillNameSaved extends SkillSheetResult {
  const SkillNameSaved(this.name);

  final String name;
}

class SkillDeleteRequested extends SkillSheetResult {
  const SkillDeleteRequested();
}

/// Edita el nombre y la respuesta a «¿Quién eres en este reino?».
/// Devuelve `(nombre, identidad)` o null si se cierra sin guardar.
Future<(String, String)?> showIdentitySheet(
  BuildContext context, {
  required String displayName,
  String? identityStatement,
}) => showModalBottomSheet<(String, String)>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  builder: (_) => _IdentityForm(
    displayName: displayName,
    identityStatement: identityStatement ?? '',
  ),
);

/// Crea una skill ([name] null) o renombra/elimina una existente.
Future<SkillSheetResult?> showSkillSheet(
  BuildContext context, {
  String? name,
}) => showModalBottomSheet<SkillSheetResult>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Colors.white,
  builder: (_) => _SkillForm(name: name),
);

class _IdentityForm extends StatefulWidget {
  const _IdentityForm({
    required this.displayName,
    required this.identityStatement,
  });

  final String displayName;
  final String identityStatement;

  @override
  State<_IdentityForm> createState() => _IdentityFormState();
}

class _IdentityFormState extends State<_IdentityForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.displayName);
  late final _identity = TextEditingController(text: widget.identityStatement);

  @override
  void dispose() {
    _name.dispose();
    _identity.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (_name.text.trim(), _identity.text.trim()));
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Tu identidad',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            autofocus: true,
            maxLength: 40,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            decoration: _decoration('Nombre del héroe'),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Escribe cómo quieres que te llamemos.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _identity,
            maxLength: 280,
            minLines: 3,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(
              '¿Quién eres en este reino?',
              hint: 'Ej.: Una estratega que termina lo que empieza.',
            ),
          ),
          const SizedBox(height: 8),
          _PrimaryButton(label: 'Guardar', onPressed: _save),
        ],
      ),
    ),
  );
}

class _SkillForm extends StatefulWidget {
  const _SkillForm({this.name});

  final String? name;

  @override
  State<_SkillForm> createState() => _SkillFormState();
}

class _SkillFormState extends State<_SkillForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);

  bool get _isNew => widget.name == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, SkillNameSaved(_name.text.trim()));
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar «${widget.name}»?'),
        content: const Text(
          'Se quitará de tus metas, proyectos, tareas y hábitos, y su nivel '
          'no se podrá recuperar. Tu XP y tu nivel de personaje no cambian.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: LifeQuestColors.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.pop(context, const SkillDeleteRequested());
    }
  }

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: _isNew ? 'Nueva skill' : 'Editar skill',
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isNew)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Una skill es un área de tu vida que quieres hacer crecer: '
                'Salud, Inglés, Universidad…',
                style: TextStyle(color: LifeQuestColors.muted, fontSize: 13),
              ),
            ),
          TextFormField(
            controller: _name,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _save(),
            decoration: _decoration('Nombre de la skill'),
            validator: (value) => (value ?? '').trim().isEmpty
                ? 'Ponle un nombre a tu skill.'
                : null,
          ),
          const SizedBox(height: 8),
          _PrimaryButton(
            label: _isNew ? 'Crear skill' : 'Guardar',
            onPressed: _save,
          ),
          if (!_isNew) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              label: const Text('Eliminar skill'),
              style: TextButton.styleFrom(
                foregroundColor: LifeQuestColors.error,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      // Sube con el teclado para que el botón siga a la vista.
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: LifeQuestColors.deepGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    ),
  );
}

InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
  labelText: label,
  hintText: hint,
  alignLabelWithHint: true,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: LifeQuestColors.outline),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: LifeQuestColors.outline),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: LifeQuestColors.deepGreen, width: 1.5),
  ),
);
