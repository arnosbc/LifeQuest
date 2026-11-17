part of 'challenges_bloc.dart';

sealed class ChallengesState extends Equatable {
  const ChallengesState();

  @override
  List<Object?> get props => [];
}

class ChallengesInitial extends ChallengesState {
  const ChallengesInitial();
}

class ChallengesLoading extends ChallengesState {
  const ChallengesLoading();
}

class ChallengesSuccess extends ChallengesState {
  const ChallengesSuccess(
    this.board, {
    this.refreshing = false,
    this.claimingKey,
    this.message,
  });

  final ChallengesBoard board;
  final bool refreshing;

  /// Cofre que se está abriendo.
  final String? claimingKey;

  /// Aviso puntual (un cobro o un refresco que falló).
  final String? message;

  @override
  List<Object?> get props => [board, refreshing, claimingKey, message];
}

class ChallengesFailure extends ChallengesState {
  const ChallengesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
