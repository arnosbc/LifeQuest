import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/app_router.dart';
import 'package:proyecto_movil/app/config/theme.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';

/// Raíz de la app: provee la sesión (AuthBloc) por encima del router.
class App extends StatefulWidget {
  const App({super.key, required this.authBloc});

  final AuthBloc authBloc;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = createAppRouter(widget.authBloc);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: widget.authBloc,
    child: MaterialApp.router(
      title: 'LifeQuest',
      debugShowCheckedModeBanner: false,
      theme: LifeQuestTheme.light,
      darkTheme: LifeQuestTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    ),
  );
}
