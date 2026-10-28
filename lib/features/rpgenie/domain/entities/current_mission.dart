import 'package:equatable/equatable.dart';

/// Lo que RPGenie v1 (solo reglas, RF-097) recomienda hacer ahora.
class RpgenieBoard extends Equatable {
  const RpgenieBoard({this.mission, this.openCount = 0, this.skippedCount = 0});

  /// Null si no quedan misiones abiertas (o todas se apartaron).
  final CurrentMission? mission;
  final int openCount;

  /// Cuántas se apartaron con "Ahora no".
  final int skippedCount;

  @override
  List<Object?> get props => [mission, openCount, skippedCount];
}

/// Por qué RPGenie la eligió.
enum MissionReason { critical, high, due, next }

class CurrentMission extends Equatable {
  const CurrentMission({
    required this.id,
    required this.title,
    this.reason = MissionReason.next,
    this.dueDate,
    this.xpReward = 0,
    this.coinReward = 0,
    this.skillName,
    this.goalTitle,
    this.projectTitle,
  });

  final String id;
  final String title;
  final MissionReason reason;
  final DateTime? dueDate;
  final int xpReward;
  final int coinReward;
  final String? skillName;
  final String? goalTitle;
  final String? projectTitle;

  @override
  List<Object?> get props => [
    id,
    title,
    reason,
    dueDate,
    xpReward,
    coinReward,
    skillName,
    goalTitle,
    projectTitle,
  ];
}
