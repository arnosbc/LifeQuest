import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/get_settings.dart';
import 'package:proyecto_movil/features/settings/domain/usecases/save_game_settings.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this._getSettings, required this._saveGameSettings})
    : super(const SettingsInitial()) {
    on<SettingsRequested>(_onRequested, transformer: droppable());
    // sequential: dos cambios seguidos se guardan en orden, sin perder ninguno.
    on<GameSettingsChanged>(_onChanged, transformer: sequential());
  }

  final GetSettings _getSettings;
  final SaveGameSettings _saveGameSettings;

  Future<void> _onRequested(
    SettingsRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(const SettingsLoading());
    final result = await _getSettings(const NoParams());
    emit(
      result.match(
        (failure) => SettingsFailure(failure.message),
        SettingsSuccess.new,
      ),
    );
  }

  Future<void> _onChanged(
    GameSettingsChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final current = state;
    if (current is! SettingsSuccess) return;
    if (event.settings == current.overview.settings) return;
    // Se muestra el cambio al instante; si falla, vuelve lo anterior.
    emit(
      SettingsSuccess(
        current.overview.withSettings(event.settings),
        saving: true,
      ),
    );
    final result = await _saveGameSettings(event.settings);
    emit(
      result.match(
        (failure) =>
            SettingsSuccess(current.overview, message: failure.message),
        (_) => SettingsSuccess(
          current.overview.withSettings(event.settings),
          message: 'Cambios guardados.',
        ),
      ),
    );
  }
}
