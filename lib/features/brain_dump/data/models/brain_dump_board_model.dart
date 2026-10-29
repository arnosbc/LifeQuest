import 'package:proyecto_movil/core/entities/smart_goal.dart';
import 'package:proyecto_movil/features/brain_dump/domain/entities/brain_dump_board.dart';

/// Respuesta JSON de la RPC `brain_dump_overview`
/// (supabase/migrations/023_brain_dump.sql).
class BrainDumpBoardModel {
  const BrainDumpBoardModel(this.json);

  factory BrainDumpBoardModel.fromJson(Map<String, dynamic> json) =>
      BrainDumpBoardModel(json);

  final Map<String, dynamic> json;

  BrainDumpBoard toEntity() => BrainDumpBoard(
    inbox: _thoughts('inbox'),
    someday: _thoughts('someday'),
    reference: _thoughts('reference'),
    convertedToday: (json['converted_today'] as num?)?.toInt() ?? 0,
    skills: [
      for (final s
          in (json['skills'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        SkillChoice(id: s['id'] as String, name: s['name'] as String),
    ],
  );

  List<Thought> _thoughts(String key) => [
    for (final t
        in (json[key] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>())
      Thought(
        id: t['id'] as String,
        content: t['content'] as String,
        createdAt: DateTime.parse(t['created_at'] as String).toLocal(),
      ),
  ];
}
