import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  void _showMessage(String message) => showLifeQuestMessage(context, message);

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
      header: const AuthHeader(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      children: [
        const AuthTabs(register: true),
        const SizedBox(height: 14),
        const AuthTitle(
          title: 'Crea tu cuenta',
          lead: 'Guarda tu progreso y úsalo desde cualquier dispositivo.',
        ),
        const SizedBox(height: 14),
        CustomTextField(
          controller: _nameController,
          label: 'Tu nombre',
          hint: 'Ej.: Jose',
          maxLength: 30,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newUsername],
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Dinos cómo te llamas.'
              : null,
        ),
        const SizedBox(height: QSpace.m),
        CustomTextField(
          controller: _emailController,
          label: 'Correo electrónico',
          hint: 'tu@correo.com',
          maxLength: 254,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          validator: (value) =>
              value == null || !_emailPattern.hasMatch(value.trim())
              ? 'Revisa el correo: parece que falta algo (ej.: tu@correo.com).'
              : null,
        ),
        const SizedBox(height: QSpace.m),
        CustomTextField(
          controller: _passwordController,
          label: 'Crea una contraseña',
          hint: 'Mínimo 6 caracteres',
          isPassword: true,
          maxLength: 128,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          validator: (value) => value == null || value.length < 6
              ? 'Usa al menos 6 caracteres.'
              : null,
        ),
        const SizedBox(height: QSpace.m),
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirma la contraseña',
          isPassword: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) => _onRegisterPressed(),
          validator: (value) => value != _passwordController.text
              ? 'Las contraseñas no coinciden.'
              : null,
        ),
        const SizedBox(height: QSpace.s),
        TermsCheckbox(),
        const SizedBox(height: QSpace.s),
        AuthPrimaryButton(
          label: 'Crear cuenta',
          onPressed: _onRegisterPressed,
          isLoading: context.watch<AuthBloc>().state is AuthLoading,
        ),
        const Spacer(),
        const SizedBox(height: 14),
        AuthFooterLink(
          question: '¿Ya tienes cuenta?',
          linkLabel: 'Inicia sesión',
          onTap: () => AuthTabs.backToLogin(context),
        ),
      ],
    ),
  );
}
