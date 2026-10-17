import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/login_brand_header.dart';
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

  void _showNotice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: context.lq.ink),
      );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Si el login funciona, el router lleva a Home por sí solo.
  @override
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    // Solo reacciona si esta pantalla es la visible (registro también escucha).
    listenWhen: (_, state) =>
        state is AuthFailure && (ModalRoute.of(context)?.isCurrent ?? true),
    listener: (context, state) => _showNotice((state as AuthFailure).message),
    child: AuthFormLayout(
      formKey: _formKey,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      children: [
        const LoginBrandHeader(),
        const Spacer(flex: 3),
        CustomTextField(
          controller: _emailController,
          label: 'Correo Electrónico',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: (value) => value == null || !value.contains('@')
              ? 'Ingresa un correo válido'
              : null,
        ),
        const SizedBox(height: 11),
        CustomTextField(
          controller: _passwordController,
          label: 'Contraseña',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => _onLoginPressed(),
          validator: (value) =>
              value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _showNotice(
              'La recuperación de contraseña estará disponible pronto.',
            ),
            style: TextButton.styleFrom(
              foregroundColor: context.lq.deepGreen,
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              '¿Olvidaste tu contraseña?',
              style: TextStyle(fontSize: 10),
            ),
          ),
        ),
        const Spacer(flex: 2),
        AuthPrimaryButton(
          label: 'Continuar',
          icon: const Icon(Icons.arrow_forward, size: 17),
          onPressed: _onLoginPressed,
          isLoading: context.watch<AuthBloc>().state is AuthLoading,
        ),
        const SizedBox(height: 13),
        SocialLoginButtons(onNotice: _showNotice),
        const SizedBox(height: 3),
        AuthFooterLink(
          question: '¿No tienes cuenta? ',
          linkLabel: 'Crea tu perfil',
          onTap: () => context.push(RoutePaths.register),
        ),
      ],
    ),
  );
}
