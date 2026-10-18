import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/auth/presentation/blocs/auth_bloc.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_footer_link.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_form_layout.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/auth_primary_button.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/custom_textfield.dart';
import 'package:proyecto_movil/features/auth/presentation/widgets/terms_checkbox.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  void _onRegisterPressed() {
    if (context.read<AuthBloc>().state is AuthLoading) return;

    final invalid = _formKey.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      _revealFirstError(invalid);
      return;
    }

    context.read<AuthBloc>().add(
      RegisterRequested(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  /// Si el registro entra directo, el router lleva a Home por sí solo.
  void _onAuthStateChanged(BuildContext context, AuthState state) {
    switch (state) {
      case AuthFailure(:final message):
        _showMessage(message);
      case AuthEmailConfirmationRequired():
        // Reemplaza el registro: al volver se llega al login.
        context.pushReplacement(RoutePaths.checkEmail, extra: state);
      default:
        break;
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
  Widget build(BuildContext context) => BlocListener<AuthBloc, AuthState>(
    // Solo reacciona si esta pantalla es la visible (login también escucha).
    listenWhen: (_, _) => ModalRoute.of(context)?.isCurrent ?? true,
    listener: _onAuthStateChanged,
    child: AuthFormLayout(
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
          isLoading: context.watch<AuthBloc>().state is AuthLoading,
        ),
        const SizedBox(height: 4),
        AuthFooterLink(
          question: '¿Ya tienes cuenta? ',
          linkLabel: 'Inicia sesión',
          onTap: () => context.pop(),
        ),
      ],
    ),
  );
}
