import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:proyecto_movil/core/resources/resource.dart';
import 'package:proyecto_movil/core/resources/resources_bloc.dart';
import 'package:proyecto_movil/core/theme/questly_icons.dart';
import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/confirm_dialog.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_sheet.dart';

enum ResourcePick { link, camera, gallery, pdf }

extension on ResourcePick {
  String get label => switch (this) {
    ResourcePick.link => 'Enlace',
    ResourcePick.camera => 'Cámara',
    ResourcePick.gallery => 'Foto',
    ResourcePick.pdf => 'PDF',
  };

  QIcons get icon => switch (this) {
    ResourcePick.link => QIcons.link,
    ResourcePick.camera || ResourcePick.gallery => QIcons.image,
    ResourcePick.pdf => QIcons.file,
  };
}

QIcons resourceIcon(ResourceKind kind) => switch (kind) {
  ResourceKind.link => QIcons.link,
  ResourceKind.image => QIcons.image,
  ResourceKind.pdf => QIcons.file,
  ResourceKind.note => QIcons.note,
};

/// Pide al usuario el recurso. Null si cancela.
Future<ResourceDraft?> pickResourceDraft(
  BuildContext context,
  ResourcePick pick,
) async {
  switch (pick) {
    case ResourcePick.link:
      final url = await askLifeQuestText(
        context,
        title: 'Añadir enlace',
        label: 'https://…',
        confirmLabel: 'Añadir',
        maxLength: 2000,
      );
      return url == null || url.trim().isEmpty ? null : ResourceDraft.link(url);
    case ResourcePick.camera || ResourcePick.gallery:
      // Comprimida: el plan gratis de Storage tiene 1 GB.
      final photo = await ImagePicker().pickImage(
        source: pick == ResourcePick.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (photo == null) return null;
      return ResourceDraft.file(
        localPath: photo.path,
        name: photo.name,
        size: await photo.length(),
      );
    case ResourcePick.pdf:
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      final file = files.firstOrNull;
      if (file?.path == null) return null;
      return ResourceDraft.file(
        localPath: file!.path!,
        name: file.name,
        size: await File(file.path!).length(),
      );
  }
}

/// Fila de botones «Enlace · Cámara · Foto · PDF».
class ResourcePickButtons extends StatelessWidget {
  const ResourcePickButtons({
    super.key,
    required this.onPicked,
    this.enabled = true,
    this.picks = ResourcePick.values,
  });

  final ValueChanged<ResourceDraft> onPicked;
  final bool enabled;
  final List<ResourcePick> picks;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final pick in picks)
          OutlinedButton.icon(
            onPressed: !enabled
                ? null
                : () async {
                    final draft = await pickResourceDraft(context, pick);
                    if (draft != null) onPicked(draft);
                  },
            icon: QIcon(pick.icon, color: q.text, size: 18),
            label: Text(pick.label),
            style: OutlinedButton.styleFrom(
              foregroundColor: q.text,
              minimumSize: const Size(QSize.minTap, QSize.minTap),
              side: BorderSide(color: q.inputBorder),
            ),
          ),
      ],
    );
  }
}

/// Hoja «Recursos» de una tarea, proyecto o meta: añadir, abrir y quitar
/// (con deshacer de 5 s, sin confirmar).
Future<void> showResourcesSheet(
  BuildContext context, {
  required ResourceTarget target,
  required String title,
  ResourceRepository? repository,
}) => showQuestlySheet<void>(
  context,
  title: 'Recursos de «$title»',
  child: BlocProvider(
    // El repositorio es único en la app (injection_container).
    create: (_) => ResourcesBloc(
      repository ?? GetIt.instance<ResourceRepository>(),
      target,
    )..add(const ResourcesRequested()),
    child: const _ResourcesView(),
  ),
);

class _ResourcesView extends StatelessWidget {
  const _ResourcesView();

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return BlocConsumer<ResourcesBloc, ResourcesState>(
      listenWhen: (a, b) => b.toOpen != null && a.toOpen != b.toOpen,
      listener: (_, s) =>
          launchUrl(Uri.parse(s.toOpen!), mode: LaunchMode.externalApplication),
      builder: (context, s) {
        final bloc = context.read<ResourcesBloc>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Lo que necesitas a mano para esta tarea. Con la IA encendida, '
              '«Dividir en pasos» también lo lee.',
              style: QText.meta(q.text2),
            ),
            const SizedBox(height: 12),
            ResourcePickButtons(
              enabled: !s.busy,
              onPicked: (d) => bloc.add(ResourceAdded(d)),
            ),
            if (s.busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (s.error case final e?) ...[
              const SizedBox(height: 10),
              Text(e, style: QText.meta(q.destructive)),
            ],
            const SizedBox(height: 12),
            if (s.loading)
              const Center(child: CircularProgressIndicator())
            else if (s.visible.isEmpty)
              Text('Aún no hay recursos.', style: QText.body(q.text2))
            else
              for (final r in s.visible)
                _ResourceRow(
                  resource: r,
                  onOpen: r.kind == ResourceKind.note
                      ? null
                      : () => bloc.add(ResourceOpened(r)),
                  onRemove: () => bloc.add(ResourceRemoved(r)),
                ),
            if (s.removing case final r?)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '«${r.title}» quitado',
                        style: QText.meta(q.text2),
                      ),
                    ),
                    TextButton(
                      onPressed: () => bloc.add(const ResourceRemoveUndone()),
                      child: const Text('Deshacer'),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ResourceRow extends StatelessWidget {
  const _ResourceRow({
    required this.resource,
    required this.onOpen,
    required this.onRemove,
  });

  final Resource resource;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final r = resource;
    final subtitle = switch (r.kind) {
      ResourceKind.link => r.url ?? '',
      ResourceKind.image => 'Foto · tocar para abrir',
      ResourceKind.pdf => 'PDF · tocar para abrir',
      ResourceKind.note => r.note ?? '',
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minTileHeight: QSize.minTap,
      leading: QIcon(resourceIcon(r.kind), color: q.text2),
      title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        subtitle,
        maxLines: r.kind == ResourceKind.note ? 4 : 1,
        overflow: TextOverflow.ellipsis,
        style: QText.meta(q.text2),
      ),
      onTap: onOpen,
      trailing: IconButton(
        tooltip: 'Quitar «${r.title}»',
        onPressed: onRemove,
        icon: QIcon(QIcons.close, color: q.text3, size: 18),
      ),
    );
  }
}
