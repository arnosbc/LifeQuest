import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/app_router.dart';
import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/core/usecases/usecase.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/disable_device_notifications.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/enable_device_notifications.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';

/// Raíz de la app: provee la sesión (AuthBloc), el tema (AppearanceBloc) y el
/// Onboarding (OnboardingBloc) por encima del router. Con la sesión enciende o
/// apaga los avisos en el dispositivo.
class App extends StatefulWidget {
  const App({
    super.key,
    required this.authBloc,
    required this.appearanceBloc,
    required this.onboardingBloc,
    this.enableDeviceNotifications,
    this.disableDeviceNotifications,
  });

  final AuthBloc authBloc;
  final AppearanceBloc appearanceBloc;
  final OnboardingBloc onboardingBloc;
  final EnableDeviceNotifications? enableDeviceNotifications;
  final DisableDeviceNotifications? disableDeviceNotifications;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createAppRouter(
    widget.authBloc,
    widget.onboardingBloc,
  );
  late final StreamSubscription<AuthState> _auth;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _onAuth(widget.authBloc.state);
    // Si la sesión caducó con la app cerrada, el dispositivo deja de recibir.
    if (!_signedIn) widget.disableDeviceNotifications?.call(const NoParams());
    _auth = widget.authBloc.stream.listen(_onAuth);
  }

  /// Al iniciar sesión se consulta si toca el Onboarding; al cerrarla se
  /// olvida, para que la próxima cuenta se consulte de nuevo.
  void _onAuth(AuthState state) {
    final signedIn = state is AuthSuccess;
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    widget.onboardingBloc.add(
      signedIn ? const OnboardingRequested() : const OnboardingReset(),
    );
    if (signedIn) {
      widget.enableDeviceNotifications?.call(
        () => _router.go(RoutePaths.notifications),
      );
    } else {
      widget.disableDeviceNotifications?.call(const NoParams());
    }
  }

  @override
  void dispose() {
    _auth.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider.value(value: widget.authBloc),
      BlocProvider.value(value: widget.appearanceBloc),
      BlocProvider.value(value: widget.onboardingBloc),
    ],
    child: BlocBuilder<AppearanceBloc, AppearanceState>(
      buildWhen: (a, b) => a.theme != b.theme || a.realm != b.realm,
      builder: (context, state) => MaterialApp.router(
        title: 'LifeQuest',
        debugShowCheckedModeBanner: false,
        theme: LifeQuestTheme.build(questlyRealmOf(state.realm), dark: false),
        darkTheme: LifeQuestTheme.build(
          questlyRealmOf(state.realm),
          dark: true,
        ),
        themeMode: switch (state.theme) {
          ThemePreference.light => ThemeMode.light,
          ThemePreference.dark => ThemeMode.dark,
          ThemePreference.system => ThemeMode.system,
        },
        routerConfig: _router,
      ),
    ),
  );
}
