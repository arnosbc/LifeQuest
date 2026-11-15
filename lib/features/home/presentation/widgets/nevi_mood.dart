import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Cómo se ve Nevi en el Inicio según el día: (pose, mensaje). Tono de
/// invitación (§7): de noche la racha «te espera», nunca «la vas a perder».
(String, String) neviMood(HomeDashboard d, DateTime now) {
  final active = _active(d);
  final pending = _pending(d);

  if (active && d.chest.ready) {
    return ('cofre', '¡Tu cofre del día está listo! Ábrelo en el camino.');
  }
  if (active && !pending) {
    return ('celebrando', '¡Camino de hoy completo! Descansa, te lo ganaste.');
  }
  if (active) {
    return ('corriendo', '¡Vas muy bien! Sigamos con la siguiente.');
  }
  if (now.hour >= 19 && d.streakDays > 0) {
    final days = d.streakDays == 1 ? '1 día' : '${d.streakDays} días';
    return ('pensando', 'Tu racha de $days te espera 🔥. Algo pequeño basta.');
  }
  if (!pending) {
    return ('meditando', 'Hoy no hay pendientes. ¿Anotamos una tarea pequeña?');
  }
  if (now.hour < 12) {
    return ('saludando', '¡Buenos días! ¿Empezamos con algo pequeño?');
  }
  return ('saludando', 'Cada pequeño paso también es progreso.');
}

/// La XP de hoy acaba de alcanzar la meta diaria (063) entre dos cargas.
bool goalJustMet(HomeDashboard before, HomeDashboard now) {
  final goal = now.dailyXpGoal;
  return goal != null && before.dailyXp < goal && now.dailyXp >= goal;
}

/// Ya hubo actividad hoy y no queda nada pendiente: el día está completo.
bool dayComplete(HomeDashboard d) => _active(d) && !_pending(d);

// Algo hecho hoy: tarea, hábito o minutos de Foco (contadores de hoy de 038).
bool _active(HomeDashboard d) =>
    d.missionsDone > 0 || d.habitsDone > 0 || d.focusMinutes > 0;

bool _pending(HomeDashboard d) =>
    d.priorityMission != null ||
    d.todayTasks.isNotEmpty ||
    d.habitsDone < d.habitsTotal;
