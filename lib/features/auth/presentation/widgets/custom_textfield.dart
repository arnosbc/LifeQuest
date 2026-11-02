import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Campo de Acceso: icono a la izquierda y el texto de ayuda dentro del
/// campo; la etiqueta solo la lee TalkBack. Radio 16 y borde lavanda suave.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool isPassword;
  final String? semanticLabel;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLength;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.isPassword = false,
    this.semanticLabel,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.maxLength,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final isEmail = widget.keyboardType == TextInputType.emailAddress;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(QRadius.block),
          borderSide: BorderSide(color: color, width: width),
        );

    // TalkBack lee la etiqueta en el campo; el botón de ver contraseña queda
    // como nodo propio.
    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onFieldSubmitted,
        autocorrect: !widget.isPassword && !isEmail,
        enableSuggestions: !widget.isPassword && !isEmail,
        validator: widget.validator,
        inputFormatters: widget.maxLength == null
            ? null
            : [LengthLimitingTextInputFormatter(widget.maxLength)],
        cursorColor: q.ink,
        style: QText.body(q.text).copyWith(fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint ?? widget.label,
          prefixIcon: widget.icon == null
              ? null
              : Icon(widget.icon, size: 20, color: q.text2),
          hintStyle: QText.body(q.text2).copyWith(fontSize: 15),
          suffixIcon: widget.isPassword
              ? IconButton(
                  tooltip: _obscureText
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: () => setState(() {
                    _obscureText = !_obscureText;
                  }),
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 22,
                    color: q.text2,
                  ),
                )
              : null,
          filled: true,
          fillColor: q.card,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          enabledBorder: border(q.inputBorder, 1),
          focusedBorder: border(q.accent, 1.5),
          errorBorder: border(q.coralInk),
          focusedErrorBorder: border(q.coralInk, 2),
          errorStyle: QText.body(
            q.coralInk,
          ).copyWith(fontSize: 13, height: 1.3),
          errorMaxLines: 2,
        ),
      ),
    );
  }
}
