import 'package:equatable/equatable.dart';

import 'package:proyecto_movil/core/entities/task_guide.dart';

/// Un paso marcable de la tarea guiada (039, `task_steps`).
class GuidedStep extends Equatable {
  const GuidedStep({
    required this.id,
    required this.position,
    required this.title,
    this.doneAt,
    this.paidXp = 0,
  });

  final String id;
  final int position;
  final String title;
  final DateTime? doneAt;

  /// XP que ya pagó este paso (0 si aún no, o si lo pagará la tarea al final).
  final int paidXp;

  bool get done => doneAt != null;

  @override
  List<Object?> get props => [id, position, title, doneAt, paidXp];
}

/// Tarea con su guía y sus pasos (`task_detail`, 039; plan B1–B2 y B6).
class GuidedTask extends Equatable {
  const GuidedTask({
    required this.id,
    required this.title,
    required this.xpReward,
    required this.coinReward,
    required this.createdAt,
    this.description,
    this.completedAt,
    this.guide,
    this.steps = const [],
    this.paidXp = 0,
    this.inFocus = false,
  });

  final String id;
  final String title;
  final String? description;

  /// Está en una sesión de Modo Foco abierta: solo así se marcan sus pasos y
  /// se completa (040).
  final bool inFocus;
  final int xpReward;
  final int coinReward;
  final DateTime createdAt;
  final DateTime? completedAt;

  /// Objetivo, pistas y búsquedas; los pasos van en [steps].
  final TaskGuide? guide;
  final List<GuidedStep> steps;

  /// XP ya cobrada por los pasos.
  final int paidXp;

  bool get completed => completedAt != null;
  int get doneCount => steps.where((s) => s.done).length;

  /// El primer paso sin hacer: el que toca ahora.
  GuidedStep? get current {
    for (final s in steps) {
      if (!s.done) return s;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    xpReward,
    coinReward,
    createdAt,
    completedAt,
    guide,
    steps,
    paidXp,
    inFocus,
  ];
}
