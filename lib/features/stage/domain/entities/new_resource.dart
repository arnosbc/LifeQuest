import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

/// Recurso nuevo desde Quick Add: un enlace, una nota o un documento, con
/// vínculos opcionales a un Proyecto, una Meta o una Skill (035).
class NewResource extends Equatable {
  const NewResource({
    required this.title,
    required this.kind,
    this.url,
    this.content,
    this.fileName,
    this.bytes,
    this.projectId,
    this.goalId,
    this.skillId,
  });

  /// Formatos de documento que acepta el bucket `resources`.
  static const extensions = [
    'pdf',
    'docx',
    'xlsx',
    'pptx',
    'md',
    'txt',
    'png',
    'jpg',
    'jpeg',
  ];

  /// Igual que el bucket `resources` (035).
  static const maxBytes = 10 * 1024 * 1024;

  /// Igual que create_resource (035).
  static const maxNoteLength = 10000;

  final String title;
  final ResourceKind kind;
  final String? url;
  final String? content;

  /// Documento elegido (solo [ResourceKind.document]).
  final String? fileName;
  final Uint8List? bytes;

  final String? projectId;
  final String? goalId;
  final String? skillId;

  /// Extensión del documento en minúsculas, sin punto; vacía si no tiene.
  String get extension {
    final name = fileName ?? '';
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  @override
  List<Object?> get props => [
    title,
    kind,
    url,
    content,
    fileName,
    bytes?.length,
    projectId,
    goalId,
    skillId,
  ];
}
