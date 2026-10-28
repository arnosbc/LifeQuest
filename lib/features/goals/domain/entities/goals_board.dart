import 'package:equatable/equatable.dart';

/// Objetivos: cada Meta es un jefe. "¡Sigue así!/Éxito/Fracaso" es solo
/// una piel de UI sobre [GoalStatus] (RF-084).
class GoalsBoard extends Equatable {
  const GoalsBoard({
    this.goals = const [],
    this.victoryXp = 300,
    this.victoryCoins = 90,
  });

  final List<BossGoal> goals;
  final int victoryXp;
  final int victoryCoins;

  @override
  List<Object?> get props => [goals, victoryXp, victoryCoins];
}

enum GoalStatus { notStarted, inProgress, completed, expired }

class BossGoal extends Equatable {
  const BossGoal({
    required this.id,
    required this.title,
    this.status = GoalStatus.notStarted,
    this.dueDate,
    this.skillName,
    this.maxHp = 100,
    this.currentHp = 100,
    this.smart = const SmartSheet(),
    this.attacks = const [],
    this.hits = const [],
  });

  final String id;
  final String title;
  final GoalStatus status;
  final DateTime? dueDate;
  final String? skillName;
  final int maxHp;
  final int currentHp;
  final SmartSheet smart;

  /// Tareas y proyectos abiertos vinculados: cada uno golpea al jefe.
  final List<BossAttack> attacks;

  /// Últimos golpes, del más reciente al más antiguo.
  final List<BossHit> hits;

  bool get active =>
      status == GoalStatus.notStarted || status == GoalStatus.inProgress;

  @override
  List<Object?> get props => [
    id,
    title,
    status,
    dueDate,
    skillName,
    maxHp,
    currentHp,
    smart,
    attacks,
    hits,
  ];
}

class SmartSheet extends Equatable {
  const SmartSheet({
    this.specific,
    this.measurable,
    this.achievable,
    this.relevant,
    this.timebound,
  });

  final String? specific;
  final String? measurable;
  final String? achievable;
  final String? relevant;
  final String? timebound;

  @override
  List<Object?> get props => [
    specific,
    measurable,
    achievable,
    relevant,
    timebound,
  ];
}

enum AttackKind { task, project }

class BossAttack extends Equatable {
  const BossAttack({
    required this.kind,
    required this.id,
    required this.title,
    required this.damage,
  });

  final AttackKind kind;
  final String id;
  final String title;
  final int damage;

  @override
  List<Object?> get props => [kind, id, title, damage];
}

class BossHit extends Equatable {
  const BossHit({required this.title, required this.damage, this.at});

  final String title;
  final int damage;
  final DateTime? at;

  @override
  List<Object?> get props => [title, damage, at];
}
