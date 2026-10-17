import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/lifequest_widgets.dart';

/// Estructura común de login y registro: pantalla completa, desplazable si el
/// teclado no deja espacio, con un formulario que ocupa todo el alto.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.formKey,
    required this.padding,
    required this.children,
  });

  final GlobalKey<FormState> formKey;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: LifeQuestColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: LifeQuestColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: LifeQuestColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: padding,
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: children,
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
