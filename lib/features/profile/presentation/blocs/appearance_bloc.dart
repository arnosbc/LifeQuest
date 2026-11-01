import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/save_theme_preference.dart';

part 'appearance_event.dart';
part 'appearance_state.dart';

/// Modo claro/oscuro/sistema de toda la app. Es global: lo provee `App` por
/// encima del router.
class AppearanceBloc extends Bloc<AppearanceEvent, AppearanceState> {
  AppearanceBloc({
    required this._getThemePreference,
    required this._saveThemePreference,
  }) : super(const AppearanceInitial()) {
    on<AppearanceRequested>(_onRequested);
    on<AppearanceThemeChanged>(_onThemeChanged);
  }

  final GetThemePreference _getThemePreference;
  final SaveThemePreference _saveThemePreference;

  Future<void> _onRequested(
    AppearanceRequested event,
    Emitter<AppearanceState> emit,
  ) async {
    final theme = await _getThemePreference(const NoParams());
    // Si no se puede leer, sistema: el tema nunca bloquea la app.
    emit(AppearanceSuccess(theme.getOrElse((_) => ThemePreference.system)));
  }

  Future<void> _onThemeChanged(
    AppearanceThemeChanged event,
    Emitter<AppearanceState> emit,
  ) async {
    // Se aplica al instante; guardarlo no lo retrasa.
    emit(AppearanceSuccess(event.theme));
    final result = await _saveThemePreference(event.theme);
    result.match(
      (failure) =>
          emit(AppearanceSuccess(event.theme, message: failure.message)),
      (_) {},
    );
  }
}
