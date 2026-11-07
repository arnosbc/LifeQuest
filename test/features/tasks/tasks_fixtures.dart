import 'package:proyecto_movil/features/tasks/domain/entities/task.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/tasks_board.dart';
import 'package:proyecto_movil/features/tasks/domain/entities/new_task.dart';

const task = Task(
  id: 't1',
  title: 'Preparar la exposición',
  priority: TaskPriority.high,
  bucket: TaskBucket.high,
  xpReward: 30,
  coinReward: 9,
);

const board = TasksBoard(tasks: [task]);
const emptyBoard = TasksBoard(tasks: []);
const newTask = NewTask(title: 'Leer');
