import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/lifequest_widgets.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
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
    required this.prefixIcon,
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
    final borderColor = context.lq.outline;
    final errorColor = context.lq.error;
    final iconColor = context.lq.muted;
    final isEmail = widget.keyboardType == TextInputType.emailAddress;

    // TalkBack lee la etiqueta en el campo; la visible se excluye para no
    // duplicarla, y el botón de ver contraseña queda como nodo propio.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: TextStyle(
              color: context.lq.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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
            cursorColor: context.lq.deepGreen,
            style: TextStyle(color: context.lq.ink, fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(widget.prefixIcon, size: 20, color: iconColor),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 44,
                minHeight: 48,
              ),
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
                        size: 20,
                        color: iconColor,
                      ),
                    )
                  : null,
              filled: true,
              fillColor: context.lq.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.lq.deepGreen, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: errorColor),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: errorColor, width: 1.5),
              ),
              errorStyle: TextStyle(
                color: errorColor,
                fontSize: 12,
                height: 1.3,
              ),
              errorMaxLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}
