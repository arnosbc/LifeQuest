import 'package:equatable/equatable.dart';

/// Escala única de urgencia de la app (`urgency_level`).
enum StageUrgency { low, medium, high }

/// Grupo del Daily Highlight (RF-089).
enum StageBucket { urgent, high, medium, low, pending }

/// Lo que se puede mandar al Archivo desde Stage.
enum StageItemKind { project, resource, goal }

/// Misión (sin subtareas) dentro de un proyecto.
class StageTask extends Equatable {
  const StageTask({required this.id, required this.title, this.done = false});

  final String id;
  final String title;
  final bool done;

  @override
  List<Object?> get props => [id, title, done];
}

/// Meta = Boss: cada misión o proyecto vinculado le resta vida.
class StageGoal extends Equatable {
  const StageGoal({
    required this.id,
    required this.title,
    this.skillName,
    this.dueDate,
    this.bossHp = 100,
    this.bossMaxHp = 100,
    this.projects = 0,
    this.openTasks = 0,
  });

  final String id;
  final String title;
  final String? skillName;
  final DateTime? dueDate;
  final int bossHp;
  final int bossMaxHp;
  final int projects;
  final int openTasks;

  @override
  List<Object?> get props => [
    id,
    title,
    skillName,
    dueDate,
    bossHp,
    bossMaxHp,
    projects,
    openTasks,
  ];
}

class HighlightItem extends Equatable {
  const HighlightItem({
    required this.id,
    required this.title,
    required this.bucket,
    this.dueDate,
  });

  final String id;
  final String title;
  final StageBucket bucket;
  final DateTime? dueDate;

  @override
  List<Object?> get props => [id, title, bucket, dueDate];
}

class StageProject extends Equatable {
  const StageProject({
    required this.id,
    required this.title,
    required this.urgency,
    this.skillName,
    this.goalTitle,
    this.endDate,
    this.tasksTotal = 0,
    this.tasksDone = 0,
    this.tasks = const [],
  });

  final String id;
  final String title;

  /// Misiones del proyecto, abiertas primero.
  final List<StageTask> tasks;

  /// Calculada por el servidor según el ritmo (RF-019); no se guarda.
  final StageUrgency urgency;
  final String? skillName;
  final String? goalTitle;
  final DateTime? endDate;
  final int tasksTotal;
  final int tasksDone;

  /// `complete_project` exige al menos una tarea hecha y ninguna abierta.
  bool get canComplete => tasksTotal > 0 && tasksDone == tasksTotal;

  @override
  List<Object?> get props => [
    id,
    title,
    urgency,
    skillName,
    goalTitle,
    endDate,
    tasksTotal,
    tasksDone,
    tasks,
  ];
}

/// Área de P.A.R.A. = skill del usuario.
class StageArea extends Equatable {
  const StageArea({
    required this.id,
    required this.name,
    this.level = 1,
    this.openTasks = 0,
    this.projects = 0,
    this.habits = 0,
  });

  final String id;
  final String name;
  final int level;
  final int openTasks;
  final int projects;
  final int habits;

  @override
  List<Object?> get props => [id, name, level, openTasks, projects, habits];
}

class StageResource extends Equatable {
  const StageResource({
    required this.id,
    required this.title,
    required this.url,
  });

  final String id;
  final String title;
  final String url;

  @override
  List<Object?> get props => [id, title, url];
}

/// Cuántas cosas hay en el Archivo (terminadas, vencidas o archivadas).
class StageArchive extends Equatable {
  const StageArchive({this.projects = 0, this.goals = 0, this.resources = 0});

  final int projects;
  final int goals;
  final int resources;

  int get total => projects + goals + resources;

  @override
  List<Object?> get props => [projects, goals, resources];
}

/// Skill o Meta a la que se puede vincular un proyecto nuevo.
class StageLink extends Equatable {
  const StageLink({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// Todo lo que muestra Stage · P.A.R.A., en una sola carga.
class StageBoard extends Equatable {
  const StageBoard({
    this.highlight = const [],
    this.highlightTotal = 0,
    this.projects = const [],
    this.areas = const [],
    this.resources = const [],
    this.archive = const StageArchive(),
    this.skills = const [],
    this.goals = const [],
  });

  /// Las primeras 5 misiones del Daily Highlight.
  final List<HighlightItem> highlight;
  final int highlightTotal;
  final List<StageProject> projects;
  final List<StageArea> areas;
  final List<StageResource> resources;
  final StageArchive archive;
  final List<StageLink> skills;

  /// Metas activas (Bosses).
  final List<StageGoal> goals;

  /// Las metas como opciones para vincular un proyecto.
  List<StageLink> get goalLinks => [
    for (final goal in goals) StageLink(id: goal.id, name: goal.title),
  ];

  @override
  List<Object?> get props => [
    highlight,
    highlightTotal,
    projects,
    areas,
    resources,
    archive,
    skills,
    goals,
  ];
}
