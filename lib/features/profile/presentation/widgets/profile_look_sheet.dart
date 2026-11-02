import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/show_lifequest_message.dart';
import 'package:proyecto_movil/features/profile/domain/entities/profile_look.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/profile_look_cubit.dart';
import 'package:proyecto_movil/features/profile/presentation/widgets/profile_look_widgets.dart';

const _emojis = [
  '😎', '🤩', '😄', '🥳', '😇', '🤓', '😺', '🔥', //
  '💪', '🌟', '🎯', '📚', '🎮', '🎵', '🌱', '⚡',
];

const _characters = [
  ('🧙', 'Mago'),
  ('🦸', 'Héroe'),
  ('🥷', 'Ninja'),
  ('🧝', 'Elfo'),
  ('🧑‍🚀', 'Astronauta'),
  ('🤖', 'Robot'),
  ('🐉', 'Dragón'),
  ('🦊', 'Zorro'),
  ('🦄', 'Unicornio'),
  ('🐼', 'Panda'),
];

const _glows = [
  (ProfileGlow.none, 'Sin luz'),
  (ProfileGlow.lavender, 'Lavanda'),
  (ProfileGlow.gold, 'Dorada'),
  (ProfileGlow.pink, 'Rosa'),
  (ProfileGlow.cyan, 'Cian'),
  (ProfileGlow.green, 'Verde'),
];

const _backdrops = [
  (ProfileBackdrop.lavender, 'Lavanda'),
  (ProfileBackdrop.aurora, 'Aurora animada'),
  (ProfileBackdrop.stars, 'Cielo estrellado'),
  (ProfileBackdrop.mountains, 'Montañas'),
];

/// Hoja para personalizar el Perfil: foto, emoji, personaje, luz y fondo. Los
/// cambios se ven y se guardan al momento.
Future<void> showProfileLookSheet(
  BuildContext context, {
  required VoidCallback onEditIdentity,
}) => showQuestlySheet<void>(
  context,
  title: 'Personalizar perfil',
  // La hoja vive en otra ruta: se le pasa el cubit de la pantalla.
  child: BlocProvider.value(
    value: context.read<ProfileLookCubit>(),
    child: _LookEditor(onEditIdentity: onEditIdentity),
  ),
);

class _LookEditor extends StatelessWidget {
  const _LookEditor({required this.onEditIdentity});

  final VoidCallback onEditIdentity;

  Future<void> _pickPhoto(BuildContext context) async {
    final cubit = context.read<ProfileLookCubit>();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      imageQuality: 85,
    );
    if (file == null) return;
    final error = await cubit.usePhoto(file.path);
    if (error != null && context.mounted) showLifeQuestMessage(context, error);
  }

  /// Imagen, GIF o video. Sin redimensionar: así el GIF sigue animado.
  Future<void> _pickBackdrop(BuildContext context) async {
    final cubit = context.read<ProfileLookCubit>();
    final file = await ImagePicker().pickMedia();
    if (file == null) return;
    final error = await cubit.useBackdrop(file.path);
    if (error != null && context.mounted) showLifeQuestMessage(context, error);
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final cubit = context.watch<ProfileLookCubit>();
    final look = cubit.state;
    void set(ProfileLook l) => cubit.change(l);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Semantics(
        header: true,
        child: Text(text, style: QText.title3(q.text)),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Vista previa con el fondo y el avatar elegidos.
        ClipRRect(
          borderRadius: BorderRadius.circular(QRadius.card),
          child: SizedBox(
            height: 150,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ProfileBackdropView(look: look),
                Center(child: ProfileAvatar(look: look)),
              ],
            ),
          ),
        ),
        const SizedBox(height: QSpace.m),
        QuestlyButton(
          label: 'Editar nombre e identidad',
          icon: QIcons.edit,
          variant: QuestlyButtonVariant.secondary,
          onPressed: () {
            Navigator.of(context).pop();
            onEditIdentity();
          },
        ),
        heading('Avatar'),
        Wrap(
          spacing: QSpace.s,
          runSpacing: QSpace.s,
          children: [
            QuestlyFilterChip(
              label: 'Paisaje',
              selected: look.avatar == AvatarStyle.landscape,
              onTap: () => set(look.copyWith(avatar: AvatarStyle.landscape)),
            ),
            QuestlyFilterChip(
              label: look.photoPath == null ? 'Subir foto' : 'Mi foto',
              selected: look.avatar == AvatarStyle.photo,
              onTap: () => look.photoPath == null
                  ? _pickPhoto(context)
                  : set(look.copyWith(avatar: AvatarStyle.photo)),
            ),
            QuestlyFilterChip(
              label: 'Emoji',
              selected: look.avatar == AvatarStyle.emoji,
              onTap: () => set(look.copyWith(avatar: AvatarStyle.emoji)),
            ),
            QuestlyFilterChip(
              label: 'Personaje',
              selected: look.avatar == AvatarStyle.character,
              onTap: () => set(look.copyWith(avatar: AvatarStyle.character)),
            ),
          ],
        ),
        if (look.avatar == AvatarStyle.photo) ...[
          const SizedBox(height: QSpace.m),
          QuestlyButton(
            label: 'Cambiar foto',
            icon: QIcons.edit,
            variant: QuestlyButtonVariant.tonal,
            onPressed: () => _pickPhoto(context),
          ),
        ],
        if (look.avatar == AvatarStyle.emoji) ...[
          heading('Elige tu emoji'),
          _Grid(
            items: [for (final e in _emojis) (e, 'Emoji $e')],
            selected: look.emoji,
            onTap: (e) => set(look.copyWith(emoji: e)),
          ),
        ],
        if (look.avatar == AvatarStyle.character) ...[
          heading('Elige tu personaje'),
          _Grid(
            items: _characters,
            selected: look.character,
            onTap: (c) => set(look.copyWith(character: c)),
          ),
        ],
        heading('Iluminación'),
        Wrap(
          spacing: QSpace.s,
          runSpacing: QSpace.s,
          children: [
            for (final (glow, label) in _glows)
              QuestlyFilterChip(
                label: label,
                selected: look.glow == glow,
                onTap: () => set(look.copyWith(glow: glow)),
              ),
          ],
        ),
        heading('Fondo'),
        Wrap(
          spacing: QSpace.s,
          runSpacing: QSpace.s,
          children: [
            for (final (backdrop, label) in _backdrops)
              QuestlyFilterChip(
                label: label,
                selected: look.backdrop == backdrop,
                onTap: () => set(look.copyWith(backdrop: backdrop)),
              ),
            QuestlyFilterChip(
              label: look.backdropPath == null ? 'Subir fondo' : 'Mi fondo',
              selected: look.backdrop == ProfileBackdrop.custom,
              onTap: () => look.backdropPath == null
                  ? _pickBackdrop(context)
                  : set(look.copyWith(backdrop: ProfileBackdrop.custom)),
            ),
          ],
        ),
        if (look.backdrop == ProfileBackdrop.custom) ...[
          const SizedBox(height: QSpace.m),
          QuestlyButton(
            label: 'Cambiar fondo (imagen, GIF o video)',
            icon: QIcons.edit,
            variant: QuestlyButtonVariant.tonal,
            onPressed: () => _pickBackdrop(context),
          ),
        ],
      ],
    );
  }
}

/// Cuadrícula de emojis grandes; el elegido lleva borde de acento.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.items,
    required this.selected,
    required this.onTap,
  });

  final List<(String, String)> items;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Wrap(
      spacing: QSpace.s,
      runSpacing: QSpace.s,
      children: [
        for (final (emoji, label) in items)
          Semantics(
            button: true,
            selected: emoji == selected,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onTap(emoji),
              borderRadius: BorderRadius.circular(QRadius.control),
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: q.tint,
                  borderRadius: BorderRadius.circular(QRadius.control),
                  border: Border.all(
                    color: emoji == selected ? q.accent : Colors.transparent,
                    width: 2.5,
                  ),
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 28)),
              ),
            ),
          ),
      ],
    );
  }
}
