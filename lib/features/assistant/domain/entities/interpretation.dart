import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/features/assistant/domain/entities/task_draft.dart';

/// Si la IA está activa y cuántas llamadas quedan hoy (`assistant_status`, 033).
class AiStatus extends Equatable {
  const AiStatus({required this.enabled, required this.callsLeft});

  static const off = AiStatus(enabled: false, callsLeft: 0);

  final bool enabled;
  final int callsLeft;

  bool get available => enabled && callsLeft > 0;

  @override
  List<Object?> get props => [enabled, callsLeft];
}

/// Resultado de interpretar una nota: el borrador y quién lo entendió.
class Interpretation extends Equatable {
  const Interpretation({
    required this.draft,
    required this.usedAi,
    required this.aiAvailable,
    this.notice,
  });

  final TaskDraft draft;
  final bool usedAi;

  /// Se puede pedir «Dividir en pasos».
  final bool aiAvailable;

  /// Aviso cuando la IA no respondió y se usaron las reglas.
  final String? notice;

  @override
  List<Object?> get props => [draft, usedAi, aiAvailable, notice];
}
