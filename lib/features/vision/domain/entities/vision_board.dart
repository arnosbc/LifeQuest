import 'package:equatable/equatable.dart';

/// Vision Board: el propósito de largo plazo (1 por usuario) y las Metas y
/// Proyectos que lo sirven (`linked_to_vision`).
class VisionBoard extends Equatable {
  const VisionBoard({this.content, this.identity, this.items = const []});

  final String? content;

  /// «¿Quién eres en este reino?» del perfil.
  final String? identity;
  final List<VisionItem> items;

  @override
  List<Object?> get props => [content, identity, items];
}

enum VisionItemKind { goal, project }

class VisionItem extends Equatable {
  const VisionItem({
    required this.kind,
    required this.id,
    required this.title,
    this.linked = false,
  });

  final VisionItemKind kind;
  final String id;
  final String title;
  final bool linked;

  @override
  List<Object?> get props => [kind, id, title, linked];
}
