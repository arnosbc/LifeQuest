import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/app/config/constants.dart';
import 'package:proyecto_movil/injection_container.dart';

bool _booted = false;

/// Arranque mínimo para callbacks con la app cerrada (botones del aviso y del
/// widget): corren en otro isolate, sin main(). Devuelve false si no hay
/// sesión guardada. Se puede llamar varias veces en el mismo isolate.
Future<bool> bootInBackground() async {
  if (!_booted) {
    WidgetsFlutterBinding.ensureInitialized();
    // La sesión guardada se restaura al inicializar Supabase.
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      publishableKey: AppConstants.supabaseKey,
    );
    await initDependencies();
    _booted = true;
  }
  final auth = Supabase.instance.client.auth;
  final session = auth.currentSession;
  if (session == null) return false;
  if (session.isExpired) await auth.refreshSession();
  return true;
}
