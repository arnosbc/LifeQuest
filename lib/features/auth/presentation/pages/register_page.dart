import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/terms_checkbox.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedTerms = true;

  void _onRegisterPressed() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Acepta los términos para continuar.')),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Héroe "${_nameController.text}" creado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormLayout(
    formKey: _formKey,
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
    children: [
      const Row(
        children: [
          Text(
            'LifeQuest',
            style: TextStyle(
              color: LifeQuestColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          Text(
            'PASO 1 DE 2',
            style: TextStyle(
              color: LifeQuestColors.deepGreen,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const Spacer(flex: 3),
      const Text(
        'Crea tu Héroe',
        style: TextStyle(
          color: LifeQuestColors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 3),
      const Text(
        'Comienza tu viaje completando tus datos.',
        style: TextStyle(color: LifeQuestColors.muted, fontSize: 11),
      ),
      const Spacer(flex: 4),
      CustomTextField(
        controller: _nameController,
        label: 'Nombre de Usuario',
        prefixIcon: Icons.person_outline,
        validator: (value) => value == null || value.isEmpty
            ? 'Ingresa un nombre de usuario'
            : null,
      ),
      const SizedBox(height: 10),
      CustomTextField(
        controller: _emailController,
        label: 'Correo Electrónico',
        prefixIcon: Icons.mail_outline,
        keyboardType: TextInputType.emailAddress,
        validator: (value) => value == null || !value.contains('@')
            ? 'Ingresa un correo válido'
            : null,
      ),
      const SizedBox(height: 10),
      CustomTextField(
        controller: _passwordController,
        label: 'Contraseña',
        prefixIcon: Icons.lock_outline,
        isPassword: true,
        validator: (value) =>
            value == null || value.length < 6 ? 'Mínimo 6 caracteres' : null,
      ),
      const SizedBox(height: 10),
      CustomTextField(
        controller: _confirmPasswordController,
        label: 'Confirmar Contraseña',
        prefixIcon: Icons.lock_outline,
        isPassword: true,
        validator: (value) => value != _passwordController.text
            ? 'Las contraseñas no coinciden'
            : null,
      ),
      const SizedBox(height: 4),
      TermsCheckbox(
        value: _acceptedTerms,
        onChanged: (value) => setState(() => _acceptedTerms = value),
      ),
      const Spacer(flex: 2),
      AuthPrimaryButton(
        label: 'Crear Cuenta',
        icon: const Icon(Icons.auto_awesome, size: 16),
        onPressed: _onRegisterPressed,
      ),
      const SizedBox(height: 4),
      AuthFooterLink(
        question: '¿Ya tienes cuenta? ',
        linkLabel: 'Inicia sesión',
        onTap: () => Navigator.maybePop(context),
      ),
    ],
  );
}
