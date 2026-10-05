import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../home/home_page.dart';
import '../widgets/custom_textfield.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _background = Color(0xFFF4F9F6);
  static const _green = Color(0xFF29B951);
  static const _ink = Color(0xFF1D3B2B);

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: _ink));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEDF8F0),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFD5EBDD),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  size: 22,
                                  color: _green,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'LifeQuest',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'AVANZA CON RITMO Y PROGRESO REAL',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF63796B),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(flex: 3),
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
                          const SizedBox(height: 11),
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
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _showNotice(
                                'La recuperación de contraseña estará disponible pronto.',
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF168B3B),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
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
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: _onLoginPressed,
                              icon: const Icon(Icons.arrow_forward, size: 17),
                              label: const Text('Continuar'),
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
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              const Expanded(child: Divider(height: 1)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'O ingresa con',
                                  style: TextStyle(
                                    color: Color(0xFF78887E),
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider(height: 1)),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showNotice(
                                    'El inicio con Google estará disponible pronto.',
                                  ),
                                  icon: const Icon(
                                    Icons.g_mobiledata,
                                    size: 18,
                                  ),
                                  label: const Text('Google'),
                                  style: _socialButtonStyle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _showNotice(
                                    'El inicio con Apple estará disponible pronto.',
                                  ),
                                  icon: const Icon(
                                    Icons.phone_iphone,
                                    size: 15,
                                  ),
                                  label: const Text('Apple'),
                                  style: _socialButtonStyle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                '¿No tienes cuenta? ',
                                style: TextStyle(
                                  color: Color(0xFF78887E),
                                  fontSize: 10,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF168B3B),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Crea tu perfil',
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

const _socialButtonStyle = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size.fromHeight(40)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 6)),
  foregroundColor: WidgetStatePropertyAll(Color(0xFF293D31)),
  textStyle: WidgetStatePropertyAll(
    TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
  ),
  side: WidgetStatePropertyAll(BorderSide(color: Color(0xFFD7E7DC))),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(9))),
  ),
);
