import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';
import 'package:proyecto_movil/features/vision/presentation/blocs/vision_bloc.dart';

/// Vision Board: el propósito y lo que lo sirve. Necesita un [VisionBloc].
class VisionScreen extends StatefulWidget {
  const VisionScreen({super.key});

  @override
  State<VisionScreen> createState() => _VisionScreenState();
}

class _VisionScreenState extends State<VisionScreen> {
  final _text = TextEditingController();
  String? _loaded;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<VisionBloc, VisionState>(
    listenWhen: (_, s) => s is VisionSuccess,
    listener: (context, s) {
      s as VisionSuccess;
      // Rellena el campo con lo guardado sin pisar lo que el usuario escribe.
      final saved = s.board.content ?? '';
      if (_loaded != saved && (_loaded == null || _text.text == _loaded)) {
        _text.text = saved;
      }
      _loaded = saved;
      if (s.message != null) showLifeQuestMessage(context, s.message!);
    },
    builder: (context, state) => switch (state) {
      VisionInitial() || VisionLoading() => Center(
        child: CircularProgressIndicator(color: context.lq.deepGreen),
      ),
      VisionFailure(:final message) => LifeQuestErrorView(
        message: message,
        onRetry: () => context.read<VisionBloc>().add(const VisionRequested()),
      ),
      VisionSuccess() => _content(context, state),
    },
  );

  Widget _content(BuildContext context, VisionSuccess state) {
    final bloc = context.read<VisionBloc>();
    final idle = state.busyKey == null;
    final identity = state.board.identity;
    return LifeQuestPage(
      title: 'Vision Board',
      subtitle: 'Hacia dónde va tu aventura.',
      children: [
        if (identity != null && identity.isNotEmpty) ...[
          LifeQuestSurface(
            color: context.lq.softGreen,
            child: Text(
              '“$identity”',
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        const LifeQuestSectionHeading('MI VISIÓN'),
        const SizedBox(height: 7),
        TextField(
          controller: _text,
          minLines: 4,
          maxLines: 10,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText:
                '¿Cómo es tu vida dentro de unos años? Escríbelo con calma.',
            border: OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: idle ? () => bloc.add(VisionSaved(_text.text)) : null,
            icon: state.busyKey == 'save'
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Guardar'),
          ),
        ),
        const SizedBox(height: 14),
        const LifeQuestSectionHeading('LO QUE SIRVE A TU VISIÓN'),
        const SizedBox(height: 7),
        if (state.board.items.isEmpty)
          const LifeQuestListRow(
            icon: Icons.flag_outlined,
            title: 'Aún no hay metas ni proyectos abiertos',
            subtitle: 'Créalos en Stage y vincúlalos aquí.',
          ),
        for (final item in state.board.items)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: LifeQuestIconTile(
              item.kind == VisionItemKind.goal
                  ? Icons.flag_outlined
                  : Icons.folder_outlined,
            ),
            title: Text(
              item.title,
              style: TextStyle(color: context.lq.ink, fontSize: 13),
            ),
            subtitle: Text(
              item.kind == VisionItemKind.goal ? 'Meta' : 'Proyecto',
              style: TextStyle(color: context.lq.muted, fontSize: 11),
            ),
            value: item.linked,
            onChanged: idle
                ? (v) => bloc.add(VisionLinkToggled(item, linked: v))
                : null,
          ),
      ],
    );
  }
}
