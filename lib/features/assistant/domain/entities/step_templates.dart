/// Pasos por reglas cuando la IA está apagada o falla: plantilla por palabra
/// clave del título y, si ninguna encaja, una genérica. Siempre hay
/// propuesta; el usuario la edita.
// shortcut: 9 plantillas por palabra suelta, ampliar con títulos reales.
abstract final class StepTemplates {
  static const _templates = <(List<String>, List<String>)>[
    (
      ['estudiar', 'repasar', 'examen', 'parcial', 'quiz'],
      [
        'Reunir apuntes y temas',
        'Resumir cada tema en una hoja',
        'Practicar con ejercicios',
        'Repasar lo que fallaste',
      ],
    ),
    (
      ['escribir', 'redactar', 'informe', 'ensayo', 'tesis', 'artículo'],
      [
        'Definir la idea principal',
        'Hacer el esquema',
        'Escribir el borrador',
        'Revisar y corregir',
      ],
    ),
    (
      ['presentación', 'exponer', 'exposición', 'diapositivas'],
      [
        'Definir el mensaje principal',
        'Ordenar las ideas en diapositivas',
        'Hacer las diapositivas',
        'Ensayar en voz alta',
      ],
    ),
    (
      [
        'programar',
        'código',
        'implementar',
        'desplegar',
        'aplicación',
        'pruebas',
      ],
      [
        'Definir qué debe funcionar',
        'Hacer la parte principal',
        'Probar los casos importantes',
        'Corregir y entregar',
      ],
    ),
    (
      ['limpiar', 'ordenar', 'organizar el', 'organizar la'],
      [
        'Sacar lo que no sirve',
        'Ordenar por zonas',
        'Limpiar',
        'Guardar cada cosa en su sitio',
      ],
    ),
    (
      ['comprar', 'compras', 'mercado', 'supermercado'],
      ['Revisar qué falta', 'Hacer la lista', 'Comprar', 'Guardar lo comprado'],
    ),
    (
      ['viaje', 'viajar', 'maleta', 'vacaciones'],
      [
        'Confirmar fechas y reservas',
        'Hacer la lista de equipaje',
        'Preparar documentos y dinero',
        'Hacer la maleta',
      ],
    ),
    (
      ['reunión', 'fiesta', 'evento', 'cumpleaños'],
      [
        'Definir fecha, lugar y objetivo',
        'Listar lo necesario',
        'Invitar o confirmar a las personas',
        'Preparar lo del día',
      ],
    ),
    (
      ['trámite', 'pagar', 'factura', 'impuestos', 'documentos'],
      [
        'Reunir los documentos',
        'Revisar requisitos y fecha límite',
        'Hacer el trámite o el pago',
        'Guardar el comprobante',
      ],
    ),
  ];

  static const _generic = [
    'Definir cómo se ve terminado',
    'Reunir lo que necesitas',
    'Hacer la primera parte',
    'Terminar y revisar',
  ];

  static List<String> forTitle(String title) {
    // Inicio de palabra: «apagar» no es «pagar».
    final t = ' ${title.toLowerCase()}';
    for (final (keys, steps) in _templates) {
      if (keys.any((k) => t.contains(' $k'))) return steps;
    }
    return _generic;
  }
}
