import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/lifequest_widgets.dart';
import '../../../home/home_page.dart';
import '../../services/auth_service.dart';
import '../../stores/auth_store.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_form_layout.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/terms_checkbox.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Future<void> _onRegisterPressed() async {
    if (ref.read(authStoreProvider).isLoading) return;

    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      _revealFirstError(invalid);
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    try {
      final outcome = await ref
          .read(authStoreProvider.notifier)
          .signUp(
            username: name,
            email: email,
            password: _passwordController.text,
          );
      if (!mounted) return;

      if (outcome == SignUpOutcome.signedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => LifeQuestTheme.lightOnly(
              HomePage(userName: ref.read(authStoreProvider).user!.displayName),
            ),
          ),
          (route) => false,
        );
        return;
      }

      // El proyecto pide confirmar el correo antes de entrar.
      _showMessage(
        '¡Héroe "$name" creado! Te enviamos un enlace a $email. '
        'Confírmalo y luego inicia sesión.',
      );
      Navigator.pop(context);
    } on AuthFailure catch (failure) {
      if (mounted) _showMessage(failure.message);
    }
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), backgroundColor: context.lq.ink),
    );

  /// Lleva a la vista el primer campo con error y lo anuncia en TalkBack.
  void _revealFirstError(Set<FormFieldState<Object?>> invalid) {
    double top(FormFieldState<Object?> f) =>
        (f.context.findRenderObject()! as RenderBox)
            .localToGlobal(Offset.zero)
            .dy;
    final first = invalid.reduce((a, b) => top(a) <= top(b) ? a : b);
    Scrollable.ensureVisible(
      first.context,
      alignment: 0.2,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
    );
    _focusTextIn(first.context);
    final count = invalid.length;
    SemanticsService.sendAnnouncement(
      View.of(context),
      count == 1
          ? 'Revisa 1 campo: ${first.errorText}'
          : 'Revisa $count campos. Primero: ${first.errorText}',
      TextDirection.ltr,
    );
  }

  /// Pone el cursor en el campo de texto del FormField (la casilla no tiene).
  void _focusTextIn(BuildContext fieldContext) {
    void visit(Element element) {
      if (element.widget is EditableText) {
        (element.widget as EditableText).focusNode.requestFocus();
        return;
      }
      element.visitChildElements(visit);
    }

    (fieldContext as Element).visitChildElements(visit);
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
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
    children: [
      Text(
        'LifeQuest',
        style: TextStyle(
          color: context.lq.deepGreen,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 40),
      Semantics(
        header: true,
        child: Text(
          'Crea tu Héroe',
          style: TextStyle(
            color: context.lq.ink,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Comienza tu viaje completando tus datos.',
        style: TextStyle(color: context.lq.muted, fontSize: 15),
      ),
      const SizedBox(height: 32),
      CustomTextField(
        controller: _nameController,
        label: 'Nombre de usuario',
        prefixIcon: Icons.person_outline,
        maxLength: 30,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newUsername],
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Ingresa un nombre de usuario.'
            : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _emailController,
        label: 'Correo electrónico',
        prefixIcon: Icons.mail_outline,
        maxLength: 254,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        validator: (value) =>
            value == null || !_emailPattern.hasMatch(value.trim())
            ? 'Ingresa un correo válido, como nombre@correo.com.'
            : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _passwordController,
        label: 'Contraseña',
        prefixIcon: Icons.lock_outline,
        isPassword: true,
        maxLength: 128,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        validator: (value) => value == null || value.length < 6
            ? 'Usa al menos 6 caracteres.'
            : null,
      ),
      const SizedBox(height: 16),
      CustomTextField(
        controller: _confirmPasswordController,
        label: 'Confirmar contraseña',
        prefixIcon: Icons.lock_outline,
        isPassword: true,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.newPassword],
        onFieldSubmitted: (_) => _onRegisterPressed(),
        validator: (value) => value != _passwordController.text
            ? 'Las contraseñas no coinciden.'
            : null,
      ),
      const SizedBox(height: 8),
      TermsCheckbox(),
      const Spacer(),
      const SizedBox(height: 24),
      AuthPrimaryButton(
        label: 'Crear cuenta',
        icon: const Icon(Icons.auto_awesome, size: 18),
        onPressed: _onRegisterPressed,
        isLoading: ref.watch(authStoreProvider).isLoading,
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
