import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/app/app.dart';
import 'package:proyecto_movil/app/config/constants.dart';
import 'package:proyecto_movil/core/storage/secure_session_storage.dart';
import 'package:proyecto_movil/app/observers/app_bloc_observer.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/disable_device_notifications.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/enable_device_notifications.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _start();
  } on Object catch (error) {
    // Nunca una pantalla en negro: si algo falla al arrancar, se dice qué.
    runApp(_StartupError(error));
  }
}

Future<void> _start() async {
  // Las fuentes van en assets/google_fonts: nunca se descargan.
  GoogleFonts.config.allowRuntimeFetching = false;
  AppConstants.ensureSupabaseConfigured();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseKey,
    // H-01 (M9): sesión y PKCE cifrados con el Keystore, no en texto plano.
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(
        persistSessionKey:
            'sb-${Uri.parse(AppConstants.supabaseUrl).host.split('.').first}'
            '-auth-token',
      ),
      pkceAsyncStorage: const SecurePkceStorage(),
    ),
  );
  await initDependencies();
  Bloc.observer = const AppBlocObserver();

  // Se resuelve la sesión guardada antes de pintar, para que el router no
  // muestre el login un instante a quien ya tiene sesión.
  final authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
  // Igual con el tema: sin esperar, quien eligió oscuro vería un destello claro.
  final appearanceBloc = sl<AppearanceBloc>()..add(const AppearanceRequested());
  await (
    authBloc.stream.firstWhere((state) => state is! AuthInitial),
    appearanceBloc.stream.firstWhere((state) => state is AppearanceSuccess),
  ).wait.timeout(const Duration(seconds: 15));

  runApp(
    App(
      authBloc: authBloc,
      appearanceBloc: appearanceBloc,
      onboardingBloc: sl<OnboardingBloc>(),
      enableDeviceNotifications: sl<EnableDeviceNotifications>(),
      disableDeviceNotifications: sl<DisableDeviceNotifications>(),
    ),
  );
}

/// Pantalla mínima si el arranque falla (sin red, configuración, plugin).
class _StartupError extends StatelessWidget {
  const _StartupError(this.error);

  final Object error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No pudimos iniciar LifeQuest.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text('Revisa tu conexión y vuelve a abrir la app.'),
              const SizedBox(height: 16),
              SelectableText('$error', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    ),
  );
}
