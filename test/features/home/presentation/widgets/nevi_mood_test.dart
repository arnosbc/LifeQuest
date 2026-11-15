import 'package:flutter_test/flutter_test.dart';

import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/home/presentation/widgets/nevi_mood.dart';

import '../../home_fixtures.dart';

void main() {
  final morning = DateTime(2026, 11, 15, 9);
  final night = DateTime(2026, 11, 15, 20);

  // Sin nada hecho hoy, con hábitos pendientes y racha de [streak] días.
  HomeDashboard idle({int streak = 4}) => HomeDashboard(
    level: 1,
    currentXp: 0,
    xpToNextLevel: 100,
    coins: 0,
    hpCurrent: 100,
    hpMax: 100,
    isWeakened: false,
    habits: const [TodayHabit(id: 'h1', name: 'Leer', done: false)],
    habitsDone: 0,
    habitsTotal: 1,
    streakDays: streak,
    missionsDone: 0,
    missionsTotal: 0,
    focusMinutes: 0,
  );

  test('con algo hecho y pendientes, Nevi corre', () {
    expect(neviMood(dashboard, morning).$1, 'corriendo');
  });

  test('de noche sin actividad, la racha espera (sin culpa)', () {
    final (pose, message) = neviMood(idle(), night);
    expect(pose, 'pensando');
    expect(message, 'Tu racha de 4 días te espera 🔥. Algo pequeño basta.');
  });

  test('de noche sin racha, solo invita', () {
    expect(neviMood(idle(streak: 0), night).$1, 'saludando');
  });

  test('en la mañana saluda', () {
    expect(neviMood(idle(), morning).$2, startsWith('¡Buenos días!'));
  });

  test('sin pendientes ni actividad, medita', () {
    expect(neviMood(emptyDashboard, morning).$1, 'meditando');
  });

  test('todo hecho: celebra; cofre listo: lo muestra', () {
    const done = HomeDashboard(
      level: 1,
      currentXp: 0,
      xpToNextLevel: 100,
      coins: 0,
      hpCurrent: 100,
      hpMax: 100,
      isWeakened: false,
      habits: [TodayHabit(id: 'h1', name: 'Leer', done: true)],
      habitsDone: 1,
      habitsTotal: 1,
      streakDays: 2,
      missionsDone: 3,
      missionsTotal: 3,
      focusMinutes: 50,
    );
    expect(neviMood(done, night).$1, 'celebrando');
    final chest = HomeDashboard(
      level: 1,
      currentXp: 0,
      xpToNextLevel: 100,
      coins: 0,
      hpCurrent: 100,
      hpMax: 100,
      isWeakened: false,
      habits: const [],
      habitsDone: 0,
      habitsTotal: 0,
      streakDays: 2,
      missionsDone: 3,
      missionsTotal: 3,
      focusMinutes: 50,
      chest: const DailyChest(progress: 3),
    );
    expect(neviMood(chest, night).$1, 'cofre');
  });

  test('día completo: hubo actividad y no queda nada', () {
    expect(dayComplete(dashboard), isFalse); // aún hay pendientes
    expect(dayComplete(emptyDashboard), isFalse); // nada hecho
    expect(dayComplete(idle()), isFalse);
  });

  test('meta diaria: celebra solo al cruzarla, una vez', () {
    HomeDashboard withXp(int xp, {int? goal = 50}) => HomeDashboard(
      level: 1,
      currentXp: 0,
      xpToNextLevel: 100,
      coins: 0,
      hpCurrent: 100,
      hpMax: 100,
      isWeakened: false,
      habits: const [],
      habitsDone: 0,
      habitsTotal: 0,
      streakDays: 0,
      missionsDone: 0,
      missionsTotal: 0,
      focusMinutes: 0,
      dailyXp: xp,
      dailyXpGoal: goal,
    );
    expect(goalJustMet(withXp(40), withXp(55)), isTrue);
    expect(goalJustMet(withXp(55), withXp(70)), isFalse); // ya estaba cumplida
    expect(goalJustMet(withXp(10), withXp(40)), isFalse); // aún no
    expect(goalJustMet(withXp(40), withXp(55, goal: null)), isFalse); // sin 063
  });
}
