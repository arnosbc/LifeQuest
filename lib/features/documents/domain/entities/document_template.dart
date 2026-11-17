/// Plantillas del Taller (RF-117). El cuerpo es Markdown listo para editar.
enum DocumentTemplate {
  blank('En blanco', 'Empieza desde cero'),
  essay('Ensayo', 'Introducción, desarrollo y conclusión'),
  report('Informe', 'Con portada, objetivo, resultados y tabla'),
  letter('Carta', 'Formal, con saludo y despedida'),
  code('Programación', 'Enunciado, solución con código y explicación'),
  notes('Apuntes', 'Cuadrícula de conceptos y notas');

  const DocumentTemplate(this.label, this.detail);

  final String label;
  final String detail;

  /// Contenido inicial; [title] y [date] rellenan la portada.
  String body({required String title, required DateTime date}) {
    final day =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return switch (this) {
      blank => '',
      essay =>
        '# $title\n\n**Autor:** \n**Fecha:** $day\n\n## Introducción\n\n'
            'Presenta el tema y tu idea principal.\n\n## Desarrollo\n\n'
            'Explica tus argumentos con ejemplos.\n\n## Conclusión\n\n'
            'Resume lo más importante.\n\n## Referencias\n\n- \n',
      report =>
        '# $title\n\n**Materia:** \n**Docente:** \n**Estudiante:** \n'
            '**Fecha:** $day\n\n---\n\n## Objetivo\n\n\n\n## Metodología\n\n\n\n'
            '## Resultados\n\n| Variable | Valor |\n| --- | --- |\n|  |  |\n|  |  |\n\n'
            '## Conclusiones\n\n',
      letter =>
        '$day\n\n**Para:** \n\n**Asunto:** $title\n\nEstimado/a:\n\n'
            'Escribe aquí el motivo de la carta.\n\nAtentamente,\n\n'
            '**Tu nombre**\n',
      code =>
        '# $title\n\n## Enunciado\n\nDescribe el problema.\n\n## Solución\n\n'
            '```dart\nvoid main() {\n  print(\'Hola, mundo\');\n}\n```\n\n'
            '## Explicación\n\nCuenta cómo funciona tu solución.\n',
      notes =>
        '# $title\n\n**Fecha:** $day\n\n| Concepto | Notas |\n| --- | --- |\n'
            '|  |  |\n|  |  |\n|  |  |\n\n## Resumen\n\n',
    };
  }
}
