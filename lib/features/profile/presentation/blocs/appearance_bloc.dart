import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_realm.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/get_theme_realm.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/save_theme_preference.dart';
import 'package:proyecto_movil/features/profile/domain/usecases/save_theme_realm.dart';

part 'appearance_event.dart';
part 'appearance_state.dart';

/// Modo (claro/oscuro/sistema) y tema del reino de toda la app. Es global: lo
/// provee `App` por encima del router.
class AppearanceBloc extends Bloc<AppearanceEvent, AppearanceState> {
  AppearanceBloc({
    required this._getThemePreference,
    required this._saveThemePreference,
    required this._getThemeRealm,
    required this._saveThemeRealm,
  }) : super(const AppearanceInitial()) {
    on<AppearanceRequested>(_onRequested);
    on<AppearanceThemeChanged>(_onThemeChanged);
    on<AppearanceRealmChanged>(_onRealmChanged);
  }

  final GetThemePreference _getThemePreference;
  final SaveThemePreference _saveThemePreference;
  final GetThemeRealm _getThemeRealm;
  final SaveThemeRealm _saveThemeRealm;

  Future<void> _onRequested(
    AppearanceRequested event,
    Emitter<AppearanceState> emit,
  ) async {
    final (theme, realm) = await (
      _getThemePreference(const NoParams()),
      _getThemeRealm(const NoParams()),
    ).wait;
    // Si no se pueden leer, sistema y Bosque: el tema nunca bloquea la app.
    emit(
      AppearanceSuccess(
        theme.getOrElse((_) => ThemePreference.system),
        realm: realm.getOrElse((_) => ThemeRealm.bosque),
      ),
    );
  }

  Future<void> _onThemeChanged(
    AppearanceThemeChanged event,
    Emitter<AppearanceState> emit,
  ) async {
    final realm = state.realm;
    // Se aplica al instante; guardarlo no lo retrasa.
    emit(AppearanceSuccess(event.theme, realm: realm));
    final result = await _saveThemePreference(event.theme);
    result.match(
      (failure) => emit(
        AppearanceSuccess(event.theme, realm: realm, message: failure.message),
      ),
      (_) {},
    );
  }

  Future<void> _onRealmChanged(
    AppearanceRealmChanged event,
    Emitter<AppearanceState> emit,
  ) async {
    final theme = state.theme;
    emit(AppearanceSuccess(theme, realm: event.realm));
    final result = await _saveThemeRealm(event.realm);
    result.match(
      (failure) => emit(
        AppearanceSuccess(theme, realm: event.realm, message: failure.message),
      ),
      (_) {},
    );
  }
}
