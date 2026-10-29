import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';

/// Campo de Acceso (Auth.dc.html): etiqueta encima, 52 px de alto, radio 14
/// y borde de 1,5 px.
class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool isPassword;
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
    this.isPassword = false,
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
          borderRadius: BorderRadius.circular(QRadius.button),
          borderSide: BorderSide(color: color, width: width),
        );

    // TalkBack lee la etiqueta en el campo; la visible se excluye para no
    // duplicarla, y el botón de ver contraseña queda como nodo propio.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(widget.label, style: QText.label(q.text))),
        const SizedBox(height: 6),
        Semantics(
          label: widget.label,
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
            style: QText.body(q.text).copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: QText.body(q.text2).copyWith(fontSize: 16),
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
              enabledBorder: border(q.inputBorder),
              focusedBorder: border(q.ink, 2),
              errorBorder: border(q.coralInk),
              focusedErrorBorder: border(q.coralInk, 2),
              errorStyle: QText.body(
                q.coralInk,
              ).copyWith(fontSize: 13, height: 1.3),
              errorMaxLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}
