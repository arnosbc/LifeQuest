import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/custom_textfield.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  static const _background = Color(0xFFF4F9F6);
  static const _green = Color(0xFF29B951);
  static const _ink = Color(0xFF1D3B2B);

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
  Widget build(BuildContext context) {
    const systemUiStyle = SystemUiOverlayStyle(
      statusBarColor: _background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: _background,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiStyle,
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'LifeQuest',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'PASO 1 DE 2',
                                style: TextStyle(
                                  color: Color(0xFF168B3B),
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
                              color: _ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Comienza tu viaje completando tus datos.',
                            style: TextStyle(
                              color: Color(0xFF78887E),
                              fontSize: 11,
                            ),
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
                            validator: (value) =>
                                value == null || !value.contains('@')
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
                                value == null || value.length < 6
                                ? 'Mínimo 6 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirmar Contraseña',
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) =>
                                value != _passwordController.text
                                ? 'Las contraseñas no coinciden'
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptedTerms,
                                onChanged: (value) => setState(() {
                                  _acceptedTerms = value ?? false;
                                }),
                                activeColor: _green,
                                side: const BorderSide(
                                  color: Color(0xFF9AB5A3),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const Text(
                                'Acepto los ',
                                style: TextStyle(
                                  color: Color(0xFF78887E),
                                  fontSize: 10,
                                ),
                              ),
                              InkWell(
                                onTap: () => showDialog<void>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Términos y condiciones'),
                                    content: const Text(
                                      'Al crear tu cuenta, aceptas usar LifeQuest de forma responsable.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Cerrar'),
                                      ),
                                    ],
                                  ),
                                ),
                                child: const Text(
                                  'términos y condiciones',
                                  style: TextStyle(
                                    color: Color(0xFF168B3B),
                                    fontSize: 10,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF168B3B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 2),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _onRegisterPressed,
                              icon: const Icon(Icons.auto_awesome, size: 16),
                              label: const Text('Crear Cuenta'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                elevation: 7,
                                shadowColor: _green.withValues(alpha: 0.24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                '¿Ya tienes cuenta? ',
                                style: TextStyle(
                                  color: Color(0xFF78887E),
                                  fontSize: 10,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.maybePop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF168B3B),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Inicia sesión',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
