import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';

/// Estructura común de login y registro: pantalla completa, desplazable si el
/// teclado no deja espacio, con un formulario que ocupa todo el alto. Con
/// [header], la cabecera va de borde a borde, bajo la barra de estado.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    this.formKey,
    this.header,
    required this.padding,
    required this.children,
  });

  /// Opcional: las pantallas sin campos no lo necesitan.
  final GlobalKey<FormState>? formKey;
  final Widget? header;
  final EdgeInsetsGeometry padding;
  final List<Widget> children;

  static const _maxFormWidth = 480.0;
  static const _maxFormHeight = 880.0;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    // Iconos claros sobre la cabecera de color; si no hay, según el modo.
    final lightIcons = header != null || q.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: lightIcons
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: lightIcons ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness: q.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: q.bg,
        body: SafeArea(
          top: header == null,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?header,
                      Expanded(
                        child: Padding(
                          // En tablet o en horizontal el formulario no pasa de
                          // _maxFormWidth × _maxFormHeight y queda centrado.
                          padding: EdgeInsets.symmetric(
                            horizontal: max(
                              0,
                              (constraints.maxWidth - _maxFormWidth) / 2,
                            ),
                            vertical: header != null
                                ? 0
                                : max(
                                    0,
                                    (constraints.maxHeight - _maxFormHeight) /
                                        2,
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
                    ],
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
