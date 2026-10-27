part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

/// Aún no se consultó (sin sesión o recién iniciada).
class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

class OnboardingLoading extends OnboardingState {
  const OnboardingLoading();
}

/// Le toca el Onboarding.
class OnboardingPending extends OnboardingState {
  const OnboardingPending(this.status, {this.saving = false, this.error});

  final OnboardingStatus status;

  /// Guardando al terminar o saltar.
  final bool saving;

  /// Aviso del último intento de guardar, para mostrar con «Reintentar».
  final String? error;

  @override
  List<Object?> get props => [status, saving, error];
}

/// Ya lo hizo, lo acaba de terminar o no se pudo consultar: va a Inicio.
class OnboardingNotNeeded extends OnboardingState {
  const OnboardingNotNeeded();
}
