import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';
import '../../../home/home_page.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/login_brand_header.dart';
import '../widgets/social_login_buttons.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      final emailName = _emailController.text.split('@').first.trim();
      final userName = emailName.isEmpty
          ? 'Alex'
          : emailName[0].toUpperCase() + emailName.substring(1);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => HomePage(userName: userName),
        ),
      );
    }
  }

  void _showNotice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: LifeQuestColors.ink),
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
            foregroundColor: LifeQuestColors.deepGreen,
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
      ),
      const SizedBox(height: 13),
      SocialLoginButtons(onNotice: _showNotice),
      const SizedBox(height: 3),
      AuthFooterLink(
        question: '¿No tienes cuenta? ',
        linkLabel: 'Crea tu perfil',
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (context) => const RegisterPage()),
        ),
      ),
    ],
  );
}
