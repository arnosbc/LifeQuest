import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Registra en consola (solo en debug) los cambios de estado y errores de
/// todos los blocs.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      debugPrint(
        '${bloc.runtimeType}: ${change.currentState} → ${change.nextState}',
      );
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) debugPrint('${bloc.runtimeType} error: $error');
    super.onError(bloc, error, stackTrace);
  }
}
