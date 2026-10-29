import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/app/app.dart';
import 'package:proyecto_movil/app/config/constants.dart';
import 'package:proyecto_movil/app/observers/app_bloc_observer.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';
import 'package:proyecto_movil/injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Las fuentes van en assets/google_fonts: nunca se descargan.
  GoogleFonts.config.allowRuntimeFetching = false;
  AppConstants.ensureSupabaseConfigured();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseKey,
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
  ).wait;

  runApp(
    App(
      authBloc: authBloc,
      appearanceBloc: appearanceBloc,
      onboardingBloc: sl<OnboardingBloc>(),
    ),
  );
}
