import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/app/config/app_shell.dart';
import 'package:proyecto_movil/features/auth/services/auth_service.dart';
import 'package:proyecto_movil/features/auth/stores/auth_store.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/login_brand_header.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/social_login_buttons.dart';
import 'package:proyecto_movil/features/auth/presentation/screens/register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _onLoginPressed() async {
    if (ref.read(authStoreProvider).isLoading ||
        !_formKey.currentState!.validate()) {
      return;
    }

    try {
      final user = await ref
          .read(authStoreProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) =>
              LifeQuestTheme.lightOnly(AppShell(userName: user.displayName)),
        ),
      );
    } on AuthFailure catch (failure) {
      if (mounted) _showNotice(failure.message);
    }
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

  @override
  Widget build(BuildContext context) => AuthFormLayout(
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
        isLoading: ref.watch(authStoreProvider).isLoading,
      ),
      const SizedBox(height: 13),
      SocialLoginButtons(onNotice: _showNotice),
      const SizedBox(height: 3),
      AuthFooterLink(
        question: '¿No tienes cuenta? ',
        linkLabel: 'Crea tu perfil',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (context) => const RegisterScreen()),
        ),
      ),
    ],
  );
}
