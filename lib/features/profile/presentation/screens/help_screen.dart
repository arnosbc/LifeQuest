import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Ayuda: cómo contactarnos, preguntas frecuentes, privacidad y quién hace
/// Questly. La acción principal es escribirnos por WhatsApp.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  static const _phone = '573001376592';
  static const _phoneLabel = '+57 300 137 6592';
  // shortcut: versión escrita a mano, sincronizar con pubspec.yaml al publicar.
  static const _version = '2.10.2';

  static const _faqs = [
    (
      '¿Cómo anoto algo rápido?',
      'Toca el botón + que está abajo a la derecha y escríbelo como lo dirías: '
          '«mañana a las 3 llamar al banco». Questly le pone fecha, hora y '
          'aviso. Revisa lo que entendió y toca «Crear».',
    ),
    (
      '¿Cómo marco una tarea como hecha?',
      'En Hoy toca «Ya la hice» en la tarea actual, o en Tareas desliza la '
          'tarea hacia la derecha. Si fue sin querer, toca «Deshacer» en el '
          'mensaje que aparece abajo.',
    ),
    (
      '¿Qué es «Dividir en pasos»?',
      'Al crear una tarea grande, toca «Dividir en pasos» y Questly te propone '
          'pasos pequeños con fecha. Puedes editarlos o quitarlos antes de '
          'guardar.',
    ),
    (
      '¿Cómo funciona Foco?',
      'En la pestaña Foco eliges las tareas, el ciclo (25, 30 o 45 minutos) y '
          'la duración. Los ciclos y descansos se encadenan solos. Cambia los '
          'descansos en Tú → Ajustes → Descansos del foco.',
    ),
    (
      '¿Cómo funciona la racha?',
      'La racha cuenta los días seguidos en que cumples un hábito bueno. En '
          'Hábitos toca el círculo del hábito cuando lo hagas; la llama se '
          'enciende y sube un día.',
    ),
    (
      '¿Cómo gano XP y subo de nivel?',
      'Ganas XP al completar tareas, cumplir hábitos y terminar ciclos de Foco. '
          'Con suficiente XP subes de nivel. Cambia cuánta ganas en Tú → '
          'Ajustes → Dificultad.',
    ),
    (
      'No me llegan los avisos',
      'Revisa que Questly tenga permiso de notificaciones en los ajustes del '
          'teléfono y que el ahorro de batería no la esté cerrando. En Tú → '
          'Ajustes → Avisos puedes ver el límite diario y las horas de '
          'silencio.',
    ),
    (
      '¿Cómo activo la IA?',
      'En Tú → Ajustes → Asistente con IA. Con ella Questly entiende mejor lo '
          'que escribes y divide tareas en pasos. Puedes usarla hasta 40 veces '
          'al día y apagarla cuando quieras.',
    ),
    (
      '¿Cómo pongo el widget en mi inicio?',
      'En Tú → Ajustes → Widget de inicio. Si tu teléfono no lo permite desde '
          'ahí, mantén presionado el inicio, toca Widgets y elige Questly.',
    ),
    (
      '¿Puedo volver a ver la guía?',
      'Sí, en Tú → Ajustes → Guía de uso. Ahí también cambias a modo claro u '
          'oscuro en Apariencia.',
    ),
    (
      '¿Pierdo mis datos si cambio de teléfono?',
      'No. Tu progreso se guarda en la nube. Instala Questly y entra con la '
          'misma cuenta de Google o el mismo correo.',
    ),
  ];

  static const _legal = [
    (
      'Privacidad',
      'Guardamos tus tareas, hábitos, proyectos y progreso en la nube '
          '(Supabase) para que no los pierdas; solo tu cuenta puede verlos. '
          'Para entrar usamos tu cuenta de Google o tu correo. Los avisos se '
          'programan en tu teléfono. Si activas la IA, el texto que escribes, '
          'los títulos que divides en pasos y sus recursos se envían a Gemini '
          '(Google) para procesarlos. No vendemos ni compartimos tus datos con '
          'nadie más. Para borrar tu cuenta y todos tus datos, escríbenos por '
          'WhatsApp.',
    ),
    (
      'Condiciones de uso',
      'Questly es un proyecto académico, gratuito y en desarrollo. Úsalo para '
          'organizar tu día; las sugerencias de la app y de la IA son una '
          'ayuda y pueden equivocarse, así que revisa fechas y pasos antes de '
          'guardarlos. No guardes en Questly contraseñas ni datos sensibles. '
          'Podemos cambiar funciones mientras la mejoramos.',
    ),
  ];

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showLifeQuestMessage(
        context,
        'No se pudo abrir. Escríbenos al $_phoneLabel.',
      );
    }
  }

  Uri _whatsApp(String text) => Uri.https('wa.me', '/$_phone', {'text': text});

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Ayuda',
    subtitle: '¿Una duda o algo no funciona? Te ayudamos.',
    trailing: IconButton(
      onPressed: onBack,
      tooltip: 'Volver al perfil',
      icon: Icon(Icons.close_rounded, color: context.lq.ink),
    ),
    children: [
      const LifeQuestSectionHeading('HABLA CON NOSOTROS'),
      const SizedBox(height: 8),
      LifeQuestActionRow(
        icon: Icons.chat_bubble_outline,
        title: 'WhatsApp',
        subtitle: '$_phoneLabel · te respondemos lo antes posible',
        actionLabel: 'Escribir',
        onAction: () =>
            _open(context, _whatsApp('Hola, necesito ayuda con Questly: ')),
      ),
      LifeQuestActionRow(
        icon: Icons.call_outlined,
        title: 'Llamar',
        subtitle: _phoneLabel,
        actionLabel: 'Llamar',
        onAction: () => _open(context, Uri(scheme: 'tel', path: '+$_phone')),
      ),
      LifeQuestActionRow(
        icon: Icons.bug_report_outlined,
        title: 'Reportar un problema',
        subtitle: 'Cuéntanos qué pasó; si puedes, adjunta una captura.',
        actionLabel: 'Reportar',
        onAction: () => _open(
          context,
          _whatsApp(
            'Reporte de Questly $_version\n'
            '¿Qué pasó?: \n'
            '¿Qué estabas haciendo?: \n'
            'Teléfono: ',
          ),
        ),
      ),
      const SizedBox(height: 16),
      const LifeQuestSectionHeading('PREGUNTAS FRECUENTES'),
      for (final (question, answer) in _faqs)
        _Answer(question: question, answer: answer),
      const SizedBox(height: 16),
      const LifeQuestSectionHeading('PRIVACIDAD Y CONDICIONES'),
      for (final (title, text) in _legal)
        _Answer(question: title, answer: text),
      const SizedBox(height: 16),
      const LifeQuestSectionHeading('EL EQUIPO'),
      const SizedBox(height: 8),
      Text(
        'Estevan Yesid Sánchez Velásquez y Jhon Alexander Bermúdez Crawford.\n'
        'Proyecto de Programación Móvil · Docente: Alexander Vaca.',
        style: TextStyle(color: context.lq.ink, fontSize: 14, height: 1.45),
      ),
      const SizedBox(height: 20),
      Center(
        child: Text(
          'Questly · versión $_version',
          style: TextStyle(color: context.lq.muted, fontSize: 12),
        ),
      ),
    ],
  );
}

/// Pregunta que se despliega para mostrar su respuesta.
class _Answer extends StatelessWidget {
  const _Answer({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      expandedAlignment: Alignment.centerLeft,
      iconColor: context.lq.ink,
      collapsedIconColor: context.lq.muted,
      title: Text(
        question,
        style: TextStyle(
          color: context.lq.ink,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Text(
          answer,
          style: TextStyle(color: context.lq.muted, fontSize: 14, height: 1.45),
        ),
      ],
    ),
  );
}
