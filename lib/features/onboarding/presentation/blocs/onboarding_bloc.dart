import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_choices.dart';
import 'package:proyecto_movil/features/onboarding/domain/entities/onboarding_status.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:proyecto_movil/features/onboarding/domain/usecases/get_onboarding_status.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// Global (vive en `App`): el router lo consulta para decidir si muestra el
/// Onboarding antes de Inicio.
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required this._getOnboardingStatus,
    required this._completeOnboarding,
  }) : super(const OnboardingInitial()) {
    on<OnboardingRequested>(_onRequested, transformer: restartable());
    on<OnboardingSubmitted>(_onSubmitted, transformer: droppable());
    on<OnboardingReset>((_, emit) => emit(const OnboardingInitial()));
  }

  final GetOnboardingStatus _getOnboardingStatus;
  final CompleteOnboarding _completeOnboarding;

  Future<void> _onRequested(
    OnboardingRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingLoading());
    final result = await _getOnboardingStatus(const NoParams());
    emit(
      result.match(
        // Si no se pudo consultar, el jugador entra a Inicio: nunca queda
        // atrapado (puede poner identidad y skills desde Perfil).
        (_) => const OnboardingNotNeeded(),
        (status) => status.pending
            ? OnboardingPending(status)
            : const OnboardingNotNeeded(),
      ),
    );
  }

  Future<void> _onSubmitted(
    OnboardingSubmitted event,
    Emitter<OnboardingState> emit,
  ) async {
    final current = state;
    if (current is! OnboardingPending) return;
    emit(OnboardingPending(current.status, saving: true));
    final result = await _completeOnboarding(event.choices);
    emit(
      result.match(
        (failure) => OnboardingPending(current.status, error: failure.message),
        (_) => const OnboardingNotNeeded(),
      ),
    );
  }
}
