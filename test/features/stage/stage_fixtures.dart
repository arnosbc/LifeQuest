import 'package:proyecto_movil/features/stage/domain/entities/new_goal.dart';
import 'package:proyecto_movil/features/stage/domain/entities/new_project.dart';
import 'package:proyecto_movil/features/stage/domain/entities/stage_board.dart';

const stageBoard = StageBoard(
  highlight: [
    HighlightItem(
      id: 't1',
      title: 'Enviar informe',
      bucket: StageBucket.urgent,
    ),
  ],
  highlightTotal: 1,
  projects: [
    StageProject(
      id: 'p1',
      title: 'Lanzamiento de la app',
      urgency: StageUrgency.high,
      skillName: 'Trabajo',
      tasksTotal: 4,
      tasksDone: 1,
    ),
  ],
  areas: [StageArea(id: 's1', name: 'Trabajo', level: 3, projects: 1)],
  resources: [
    StageResource(id: 'r1', title: 'Guía', url: 'https://example.com'),
  ],
  archive: StageArchive(projects: 2),
);

const emptyStageBoard = StageBoard();
const newProject = NewProject(title: 'Curso de inglés');

final newGoal = NewGoal(
  title: 'Correr 10 km',
  specific: 'Correr 10 km sin parar',
  measurable: 'Menos de 60 minutos',
  achievable: '3 entrenos por semana',
  relevant: 'Más energía',
  dueDate: DateTime(2026, 12, 31),
);
