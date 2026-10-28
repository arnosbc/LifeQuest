import 'package:proyecto_movil/features/vision/domain/entities/vision_board.dart';

/// Respuesta JSON de la RPC `vision_overview`
/// (supabase/migrations/024_vision_board.sql).
class VisionBoardModel {
  const VisionBoardModel(this.json);

  factory VisionBoardModel.fromJson(Map<String, dynamic> json) =>
      VisionBoardModel(json);

  final Map<String, dynamic> json;

  VisionBoard toEntity() => VisionBoard(
    content: json['content'] as String?,
    identity: json['identity'] as String?,
    items: [
      for (final i
          in (json['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        VisionItem(
          kind: i['kind'] == 'project'
              ? VisionItemKind.project
              : VisionItemKind.goal,
          id: i['id'] as String,
          title: i['title'] as String,
          linked: i['linked'] as bool? ?? false,
        ),
    ],
  );
}
