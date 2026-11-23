import 'package:home_widget/home_widget.dart';

import 'package:proyecto_movil/app/background_boot.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/tasks/domain/usecases/complete_task.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Datos del widget de inicio (android/…/QuestlyWidgetProvider.kt): las
/// próximas 3 tareas de hoy. Une Hoy y Tareas, por eso vive en app/.
abstract final class HomeWidgetSync {
  static const _provider = 'com.example.proyecto_movil.QuestlyWidgetProvider';

  /// Bloques de hoy que aún no terminan y, después, lo que no tiene hora.
  /// Arriba, la mascota con la racha y el progreso de tareas del día.
  static Future<void> update(HomeDashboard d, DateTime now) => _save(
    [
      for (final b in d.agenda)
        if (!b.done && b.end.isAfter(now)) (b.id, b.title, _hhmm(b.start)),
      for (final t in d.unscheduled) (t.id, t.title, ''),
    ].take(3).toList(),
    progress: (
      d.streakDays,
      d.tasksDone + d.habitsDone,
      d.tasksTotal + d.habitsTotal,
    ),
    day: (dayKey(now), dayDone(d)),
  );

  /// Fecha local `yyyy-MM-dd` (la lee `LocalDate.parse` en Kotlin).
  static String dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// Día cumplido: hay algo para hoy y todas las tareas y hábitos están hechos.
  static bool dayDone(HomeDashboard d) =>
      d.tasksTotal + d.habitsTotal > 0 &&
      d.tasksDone >= d.tasksTotal &&
      d.habitsDone >= d.habitsTotal;

  /// Botón de Ajustes: el teléfono muestra su diálogo para poner el widget.
  /// False si el launcher no permite fijarlo desde la app.
  static Future<bool> pin() async {
    try {
      if (await HomeWidget.isRequestPinWidgetSupported() != true) return false;
      await HomeWidget.requestPinWidget(qualifiedAndroidName: _provider);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Al cerrar sesión: que el widget no muestre tareas de otra cuenta.
  static Future<void> clear() =>
      _save(const [], count: -1, progress: (0, 0, 0), day: (null, false));

  static Future<void> _save(
    List<(String, String, String)> items, {
    int? count,
    (int streak, int done, int total)? progress,
    // Sin fecha = sesión cerrada: la mascota pide entrar.
    (String? savedDay, bool dayDone)? day,
  }) async {
    try {
      if (day != null) {
        await HomeWidget.saveWidgetData<bool>('signed_in', day.$1 != null);
        await HomeWidget.saveWidgetData<String>('saved_day', day.$1);
        await HomeWidget.saveWidgetData<bool>('day_done', day.$2);
      }
      if (progress != null) {
        await HomeWidget.saveWidgetData<int>('streak', progress.$1);
        await HomeWidget.saveWidgetData<int>('done', progress.$2);
        await HomeWidget.saveWidgetData<int>('total', progress.$3);
      }
      await HomeWidget.saveWidgetData<int>('count', count ?? items.length);
      for (var i = 0; i < 3; i++) {
        final item = i < items.length ? items[i] : null;
        await HomeWidget.saveWidgetData<String>('task_${i}_id', item?.$1);
        await HomeWidget.saveWidgetData<String>('task_${i}_title', item?.$2);
        await HomeWidget.saveWidgetData<String>('task_${i}_time', item?.$3);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    } catch (_) {
      // Sin widget (o en tests): nada que actualizar.
    }
  }

  static Future<List<(String, String, String)>> _read() async => [
    for (var i = 0; i < 3; i++)
      if (await HomeWidget.getWidgetData<String>('task_${i}_id') case final id?)
        (
          id,
          await HomeWidget.getWidgetData<String>('task_${i}_title') ?? '',
          await HomeWidget.getWidgetData<String>('task_${i}_time') ?? '',
        ),
  ];

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

/// Id de tarea con forma de UUID (lo que genera la BD).
bool isTaskId(String? id) => id != null && _uuid.hasMatch(id);

/// «✓» del widget (`questly://done?id=…`), con la app abierta o cerrada.
@pragma('vm:entry-point')
Future<void> onWidgetAction(Uri? uri) async {
  final id = uri?.queryParameters['id'];
  // H-04: validar lo que llega por el intent antes de usarlo.
  if (uri?.host != 'done' || !isTaskId(id) || !await bootInBackground()) {
    return;
  }
  final done = await sl<CompleteTask>()(id!);
  // Se quita la fila sin esperar a abrir la app; si falló, se queda.
  if (done.isRight()) {
    final rest = (await HomeWidgetSync._read()).where((t) => t.$1 != id);
    // La barra avanza al instante; la racha la recalcula la app al abrirse.
    final streak = await HomeWidget.getWidgetData<int>('streak') ?? 0;
    final doneCount = await HomeWidget.getWidgetData<int>('done') ?? 0;
    final total = await HomeWidget.getWidgetData<int>('total') ?? 0;
    await HomeWidgetSync._save(
      rest.toList(),
      progress: (streak, doneCount + 1 > total ? total : doneCount + 1, total),
    );
  }
}
