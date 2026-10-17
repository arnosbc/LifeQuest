import 'package:flutter/material.dart';

import '../../../../shared/lifequest_widgets.dart';

/// Casilla de términos que forma parte del Form: `validate()` muestra su error
/// junto a la casilla. Empieza desmarcada; el consentimiento debe ser explícito.
class TermsCheckbox extends FormField<bool> {
  TermsCheckbox({super.key})
    : super(
        initialValue: false,
        validator: (value) =>
            value == true ? null : 'Acepta los términos para continuar.',
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // TalkBack lee la frase completa en la casilla; el enlace
                // sigue siendo un botón aparte para abrir los términos.
                MergeSemantics(
                  child: InkWell(
                    onTap: () => field.didChange(!(field.value ?? false)),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Semantics(
                          label: 'Acepto los términos y condiciones',
                          child: Checkbox(
                            value: field.value,
                            onChanged: field.didChange,
                            activeColor: field.context.lq.deepGreen,
                            isError: field.hasError,
                            side: BorderSide(
                              color: field.context.lq.outline,
                              width: 1.5,
                            ),
                          ),
                        ),
                        ExcludeSemantics(
                          child: Text(
                            'Acepto los',
                            style: TextStyle(
                              color: field.context.lq.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () => showDialog<void>(
                      context: field.context,
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
                    style: TextButton.styleFrom(
                      foregroundColor: field.context.lq.deepGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(48, 48),
                    ),
                    child: Text(
                      'términos y condiciones',
                      style: TextStyle(
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: field.context.lq.deepGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  field.errorText!,
                  style: TextStyle(color: field.context.lq.error, fontSize: 12),
                ),
              ),
          ],
        ),
      );
}
