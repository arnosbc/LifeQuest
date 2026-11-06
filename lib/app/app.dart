import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/app_router.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/app/capture_sheet.dart';
import 'package:proyecto_movil/app/home_widget_sync.dart';
import 'package:proyecto_movil/app/reminder_actions.dart';
import 'package:proyecto_movil/app/share_intake.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/onboarding/presentation/blocs/onboarding_bloc.dart';
import 'package:proyecto_movil/features/profile/domain/entities/theme_preference.dart';
import 'package:proyecto_movil/features/profile/presentation/blocs/appearance_bloc.dart';

/// Raíz de la app: provee la sesión (AuthBloc), el tema (AppearanceBloc) y el
/// Onboarding (OnboardingBloc) por encima del router.
class App extends StatefulWidget {
  const App({
    super.key,
    required this.authBloc,
    required this.appearanceBloc,
    required this.onboardingBloc,
  });

  final AuthBloc authBloc;
  final AppearanceBloc appearanceBloc;
  final OnboardingBloc onboardingBloc;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createAppRouter(
    widget.authBloc,
    widget.onboardingBloc,
  );
  late final StreamSubscription<AuthState> _auth;
  late final AppLifecycleListener _lifecycle;
  late final ShareIntake _share = ShareIntake(_onShared);
  bool _signedIn = false;

  /// Lo compartido antes de iniciar sesión espera a que la haya.
  String? _pendingShare;

  @override
  void initState() {
    super.initState();
    _onAuth(widget.authBloc.state);
    _auth = widget.authBloc.stream.listen(_onAuth);
    _share.start();
    // Al volver a la app: la hora o las tareas pudieron cambiar en otro lado.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        if (_signedIn) ReminderActions.sync();
      },
    );
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
      ReminderActions.sync();
      if (_pendingShare case final text?) _onShared(text);
    } else {
      ReminderActions.clear();
      HomeWidgetSync.clear();
    }
  }

  /// «Compartir → Questly» desde otra app: abre «Anotar» con el texto, que
  /// por defecto va a la Bandeja.
  void _onShared(String text) {
    _pendingShare = text;
    if (!_signedIn) return;
    // Tras el primer frame el navegador del router ya existe.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _router.routerDelegate.navigatorKey.currentContext;
      if (context == null || _pendingShare == null) return;
      _pendingShare = null;
      openCaptureSheet(context, sharedText: text);
    });
  }

  @override
  void dispose() {
    _auth.cancel();
    _lifecycle.dispose();
    _share.dispose();
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
      buildWhen: (a, b) => a.theme != b.theme,
      builder: (context, state) => MaterialApp.router(
        title: 'LifeQuest',
        debugShowCheckedModeBanner: false,
        theme: LifeQuestTheme.light,
        darkTheme: LifeQuestTheme.dark,
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
