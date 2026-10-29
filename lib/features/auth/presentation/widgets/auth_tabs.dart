import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Pestañas «Iniciar sesión · Registrarse» (Auth.dc.html). El registro va
/// apilado sobre el login: elegir la otra pestaña empuja o vuelve.
class AuthTabs extends StatelessWidget {
  const AuthTabs({super.key, required this.register});

  /// True en la pantalla de registro.
  final bool register;

  /// Del registro al login: vuelve si hay a dónde, si no, va directo.
  static void backToLogin(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(RoutePaths.login);

  @override
  Widget build(BuildContext context) => QuestlySegmented<bool>(
    segments: const [(false, 'Iniciar sesión'), (true, 'Registrarse')],
    selected: register,
    onChanged: (toRegister) {
      if (toRegister == register) return;
      toRegister
          ? context.push(RoutePaths.register)
          : backToLogin(context);
    },
  );
}

/// Título y bajada de cada vista de Acceso.
class AuthTitle extends StatelessWidget {
  const AuthTitle({super.key, required this.title, required this.lead});

  final String title;
  final String lead;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: QText.title2(q.text).copyWith(fontSize: 24),
          ),
        ),
        const SizedBox(height: QSpace.xs),
        Text(lead, style: QText.body(q.text2).copyWith(fontSize: 14)),
      ],
    );
  }
}
