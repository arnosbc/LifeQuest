import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Estructura común de login y registro: pantalla completa, desplazable si el
/// teclado no deja espacio, con un formulario que ocupa todo el alto.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    this.formKey,
    required this.padding,
    required this.children,
  });

  /// Opcional: las pantallas sin campos no lo necesitan.
  final GlobalKey<FormState>? formKey;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  static const _maxFormWidth = 480.0;
  static const _maxFormHeight = 880.0;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
    child: Scaffold(
      backgroundColor: context.lq.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  // En tablet o en horizontal el formulario no pasa de
                  // _maxFormWidth × _maxFormHeight y queda centrado.
                  padding: EdgeInsets.symmetric(
                    horizontal: max(
                      0,
                      (constraints.maxWidth - _maxFormWidth) / 2,
                    ),
                    vertical: max(
                      0,
                      (constraints.maxHeight - _maxFormHeight) / 2,
                    ),
                  ).add(padding),
                  child: Form(
                    key: formKey,
                    child: AutofillGroup(
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
    ),
  );
}
