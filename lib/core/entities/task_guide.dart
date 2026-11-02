import 'package:equatable/equatable.dart';

/// Guía de una tarea guiada (plan B1): objetivo, pasos marcables, pistas que
/// se muestran a pedido y búsquedas para aprender más. La escribe la IA (o
/// una ruta lista) y el servidor la guarda con `attach_task_guide` (039).
class TaskGuide extends Equatable {
  const TaskGuide({
    required this.steps,
    this.objective,
    this.hints = const [],
    this.search = const [],
  });

  final String? objective;
  final List<String> steps;
  final List<String> hints;
  final List<String> search;

  Map<String, Object?> toJson() => {
    'objective': objective,
    'steps': steps,
    'hints': hints,
    'search': search,
  };

  @override
  List<Object?> get props => [objective, steps, hints, search];
}
