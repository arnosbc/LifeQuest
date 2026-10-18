import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// JSON tal como lo devuelve la RPC `home_dashboard`.
const dashboardJson = <String, dynamic>{
  'display_name': 'Ana',
  'character_class': 'Estratega',
  'level': 24,
  'current_xp': 7850,
  'xp_to_next_level': 12000,
  'coins': 2450,
  'hp_current': 80,
  'hp_max': 100,
  'is_weakened': false,
  'priority_mission': {
    'id': 't1',
    'title': 'Preparar presentación del proyecto',
    'due_date': '2026-10-17T23:00:00+00:00',
    'priority': 'high',
    'xp_reward': 350,
    'coin_reward': 120,
  },
  'habits': [
    {'id': 'h1', 'name': 'Leer', 'done': true},
    {'id': 'h2', 'name': 'Agua', 'done': false},
  ],
  'habits_done': 1,
  'habits_total': 2,
  'streak_days': 12,
  'missions_done': 3,
  'missions_total': 5,
  'focus_minutes': 45,
};

final dashboard = dashboardWith();

HomeDashboard dashboardWith({bool isWeakened = false}) => HomeDashboard(
  displayName: 'Ana',
  characterClass: 'Estratega',
  level: 24,
  currentXp: 7850,
  xpToNextLevel: 12000,
  coins: 2450,
  hpCurrent: 80,
  hpMax: 100,
  isWeakened: isWeakened,
  priorityMission: PriorityMission(
    id: 't1',
    title: 'Preparar presentación del proyecto',
    dueDate: DateTime.parse('2026-10-17T23:00:00+00:00').toLocal(),
    priority: UrgencyLevel.high,
    xpReward: 350,
    coinReward: 120,
  ),
  habits: const [
    TodayHabit(id: 'h1', name: 'Leer', done: true),
    TodayHabit(id: 'h2', name: 'Agua', done: false),
  ],
  habitsDone: 1,
  habitsTotal: 2,
  streakDays: 12,
  missionsDone: 3,
  missionsTotal: 5,
  focusMinutes: 45,
);

/// Usuario recién registrado: sin misiones ni hábitos.
const emptyDashboard = HomeDashboard(
  level: 1,
  currentXp: 0,
  xpToNextLevel: 100,
  coins: 0,
  hpCurrent: 100,
  hpMax: 100,
  isWeakened: false,
  habits: [],
  habitsDone: 0,
  habitsTotal: 0,
  streakDays: 0,
  missionsDone: 0,
  missionsTotal: 0,
  focusMinutes: 0,
);
