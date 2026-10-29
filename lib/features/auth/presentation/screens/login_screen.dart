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
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_tabs.dart';
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
        header: const AuthHeader(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        children: [
          const AuthTabs(register: false),
          const SizedBox(height: 14),
          const AuthTitle(
            title: 'Bienvenido de vuelta',
            lead: 'Tu racha y tus tareas te esperan.',
          ),
          const SizedBox(height: 14),
          CustomTextField(
            controller: _emailController,
            label: 'Correo electrónico',
            hint: 'tu@correo.com',
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
            hint: 'Tu contraseña',
            isPassword: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onFieldSubmitted: (_) => _onLoginPressed(),
            validator: (value) => value == null || value.length < 6
                ? 'Mínimo 6 caracteres.'
                : null,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showNotice(
                'La recuperación de contraseña estará disponible pronto.',
              ),
              style: TextButton.styleFrom(
                foregroundColor: q.ink,
                minimumSize: const Size(48, QSize.minTap),
                padding: EdgeInsets.zero,
              ),
              child: Text('¿Olvidaste tu contraseña?', style: QText.label(q.ink)),
            ),
          ),
          const SizedBox(height: QSpace.xs),
          AuthPrimaryButton(
            label: 'Iniciar sesión',
            onPressed: _onLoginPressed,
            isLoading: context.watch<AuthBloc>().state is AuthLoading,
          ),
          const Spacer(),
          const SizedBox(height: 14),
          SocialLoginButtons(onNotice: _showNotice),
          AuthFooterLink(
            question: '¿Aún no tienes cuenta?',
            linkLabel: 'Regístrate',
            onTap: () => context.push(RoutePaths.register),
          ),
        ],
      ),
    );
  }
}
