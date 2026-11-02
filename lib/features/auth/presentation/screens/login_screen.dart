import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/show_lifequest_message.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_header.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _onLoginPressed() {
    if (context.read<AuthBloc>().state is AuthLoading ||
        !_formKey.currentState!.validate()) {
      return;
    }
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _showNotice(String message) => showLifeQuestMessage(context, message);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Si el login funciona, el router lleva a Home por sí solo.
  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return BlocListener<AuthBloc, AuthState>(
      // Solo reacciona si esta pantalla es la visible (registro también escucha).
      listenWhen: (_, state) =>
          state is AuthFailure && (ModalRoute.of(context)?.isCurrent ?? true),
      listener: (context, state) => _showNotice((state as AuthFailure).message),
      child: AuthFormLayout(
        formKey: _formKey,
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
        children: [
          const AuthHeader(subtitle: 'Inicia sesión en tu cuenta'),
          const SizedBox(height: 28),
          CustomTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (value) => value == null || !value.contains('@')
                ? 'Revisa el correo: parece que falta algo (ej.: tu@correo.com).'
                : null,
          ),
          const SizedBox(height: QSpace.m),
          CustomTextField(
            controller: _passwordController,
            label: 'Contraseña',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _onLoginPressed(),
            validator: (value) => value == null || value.length < 6
                ? 'Mínimo 6 caracteres.'
                : null,
          ),
          const SizedBox(height: QSpace.xl),
          AuthPrimaryButton(
            label: 'Iniciar sesión',
            onPressed: _onLoginPressed,
            isLoading: context.watch<AuthBloc>().state is AuthLoading,
          ),
          const SizedBox(height: QSpace.s),
          Center(
            child: TextButton(
              onPressed: () => _showNotice(
                'La recuperación de contraseña estará disponible pronto.',
              ),
              style: TextButton.styleFrom(
                foregroundColor: q.text,
                minimumSize: const Size(48, QSize.minTap),
              ),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: QText.body(q.text).copyWith(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: QSpace.m),
          SocialLoginButtons(
            onGoogle: context.watch<AuthBloc>().state is AuthLoading
                ? null
                : () => context.read<AuthBloc>().add(
                    const GoogleLoginRequested(),
                  ),
          ),
          const SizedBox(height: QSpace.s),
          AuthFooterLink(
            question: '¿No tienes una cuenta?',
            linkLabel: 'Regístrate',
            onTap: () => context.push(RoutePaths.register),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
