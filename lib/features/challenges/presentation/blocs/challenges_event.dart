part of 'challenges_bloc.dart';

sealed class ChallengesEvent extends Equatable {
  const ChallengesEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar Desafíos y Liga.
class ChallengesRequested extends ChallengesEvent {
  const ChallengesRequested();
}

/// Abrir el cofre del desafío [key] (`xp`, `tasks`, `focus` o `month`).
class ChallengeClaimed extends ChallengesEvent {
  const ChallengeClaimed(this.key);

  final String key;

  @override
  List<Object?> get props => [key];
}
