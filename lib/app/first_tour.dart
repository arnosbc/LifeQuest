import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';

/// Pasos de la guía: imagen de la mascota, título y texto. Describen lo que
/// la app ya hace; no cambian ningún flujo.
const firstTourSteps = [
  (
    'assets/images/guia/guia_hola.png',
    'Hola, así funciona LifeQuest',
    'Anotas lo que tienes que hacer, lo ves en tu día y lo cumples. '
        'Te muestro lo básico en 6 pasos.',
  ),
  (
    'assets/images/guia/guia_anotar.png',
    'Anota con el botón +',
    'Escribe como hablas: «llamar a mamá mañana 7pm». LifeQuest entiende '
        'la fecha y la hora, y te avisa a tiempo.',
  ),
  (
    'assets/images/guia/guia_hoy.png',
    'Hoy es tu agenda',
    'Ahí ves lo que toca hoy, por horas. Marca el círculo cuando termines '
        'una tarea y ganas XP.',
  ),
  (
    'assets/images/guia/guia_habitos.png',
    'Hábitos y racha',
    'En Hábitos creas lo que quieres hacer cada día. Cumplirlos mantiene '
        'viva tu racha.',
  ),
  (
    'assets/images/guia/guia_foco.png',
    'Foco para concentrarte',
    'Elige una tarea y empieza el temporizador. Trabajas sin distracciones '
        'y los descansos llegan solos.',
  ),
  (
    'assets/images/guia/guia_listo.png',
    'Tu progreso está en Tú',
    'Ahí ves tu nivel y tu historial, y en Ajustes puedes poner el widget '
        'en tu pantalla de inicio. ¡A empezar!',
  ),
];

String? _checkedFor;

/// La guía sale sola al abrir la app en Hoy por primera vez con cada cuenta
/// (después del registro y el Onboarding: antes el router no muestra el shell).
Future<void> maybeShowFirstTour(BuildContext context) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  // Se llama en cada build del shell: solo se mira una vez por cuenta.
  if (userId == null || userId == _checkedFor) return;
  _checkedFor = userId;
  final key = 'first_tour_seen_$userId';
  final prefs = SharedPreferencesAsync();
  try {
    if (await prefs.getBool(key) ?? false) return;
    await prefs.setBool(key, true);
  } catch (_) {
    return; // Sin almacenamiento (tests): no se muestra sola.
  }
  if (context.mounted) await showFirstTour(context);
}

/// Guía de uso paso a paso. Tocar fuera la cierra.
Future<void> showFirstTour(BuildContext context) async {
  for (final (i, (image, title, message)) in firstTourSteps.indexed) {
    final last = i == firstTourSteps.length - 1;
    if (!context.mounted) return;
    final next = await showQuestlyDialog<bool>(
      context,
      title: title,
      message: message,
      content: Padding(
        padding: const EdgeInsets.only(bottom: QSpace.s),
        child: Column(
          children: [
            // Las ilustraciones traen su fondo grafito: van en su propio marco.
            ClipRRect(
              borderRadius: BorderRadius.circular(QRadius.card),
              child: ColoredBox(
                color: const Color(0xFF1C1C1C),
                child: Image.asset(image, height: 150, excludeFromSemantics: true),
              ),
            ),
            const SizedBox(height: QSpace.xs),
            Text(
              '${i + 1} de ${firstTourSteps.length}',
              style: QText.label(context.q.text3),
            ),
          ],
        ),
      ),
      actions: [
        Builder(
          builder: (context) => QuestlyButton(
            label: last ? '¡Vamos!' : 'Siguiente',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ),
      ],
    );
    if (next != true) return;
  }
}
