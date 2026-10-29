import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_header.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_primary_button.dart';

/// Tras crear la cuenta, cuando Supabase pide confirmar el correo antes de
/// iniciar sesión.
class CheckEmailScreen extends StatelessWidget {
  const CheckEmailScreen({
    super.key,
    required this.username,
    required this.email,
  });

  final String username;
  final String email;

  @override
  Widget build(BuildContext context) => AuthFormLayout(
    header: const AuthHeader(height: 170),
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
    children: [
      const Spacer(),
      const SizedBox(height: 32),
      const Center(child: _MailSeal()),
      const SizedBox(height: 32),
      Semantics(
        header: true,
        child: Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.lq.ink,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tu cuenta «$username» ya está creada. Solo falta activarla con el '
        'enlace que enviamos a:',
        textAlign: TextAlign.center,
        style: TextStyle(color: context.lq.muted, fontSize: 15, height: 1.4),
      ),
      const SizedBox(height: 16),
      _EmailChip(email),
      const SizedBox(height: 24),
      _Hint(
        icon: Icons.touch_app_outlined,
        text:
            'Toca «Confirmar» en el correo y vuelve aquí para iniciar sesión.',
      ),
      const SizedBox(height: 12),
      _Hint(
        icon: Icons.schedule_outlined,
        text:
            '¿No lo ves? Puede tardar unos minutos; revisa también spam o '
            'promociones.',
      ),
      const Spacer(),
      const SizedBox(height: 32),
      AuthPrimaryButton(
        label: 'Ir a iniciar sesión',
        onPressed: () => context.go(RoutePaths.login),
      ),
      const SizedBox(height: 4),
      AuthFooterLink(
        question: '¿Correo equivocado? ',
        linkLabel: 'Regístrate de nuevo',
        onTap: () => context.pushReplacement(RoutePaths.register),
      ),
    ],
  );
}

/// Sobre dentro de dos anillos de semillero; entra una sola vez al abrir.
class _MailSeal extends StatelessWidget {
  const _MailSeal();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 700),
      curve: Curves.easeOutExpo,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: .85 + .15 * t, child: child),
      ),
      child: Container(
        width: 128,
        height: 128,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.lq.line),
        ),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: context.lq.softGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mark_email_unread_outlined,
            size: 44,
            color: context.lq.deepGreen,
          ),
        ),
      ),
    ),
  );
}

/// El correo destacado para que el usuario detecte si lo escribió mal.
class _EmailChip extends StatelessWidget {
  const _EmailChip(this.email);

  final String email;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.lq.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.lq.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mail_outline, size: 18, color: context.lq.deepGreen),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              email,
              style: TextStyle(
                color: context.lq.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.lq.softGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 19, color: context.lq.deepGreen),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Text(
            text,
            style: TextStyle(
              color: context.lq.muted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ),
    ],
  );
}
