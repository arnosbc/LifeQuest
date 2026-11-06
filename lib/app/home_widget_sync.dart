import 'package:home_widget/home_widget.dart';

import 'package:proyecto_movil/app/background_boot.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';
import 'package:proyecto_movil/features/missions/domain/usecases/complete_mission.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Datos del widget de inicio (android/…/QuestlyWidgetProvider.kt): las
/// próximas 3 tareas de hoy. Une Hoy y Tareas, por eso vive en app/.
abstract final class HomeWidgetSync {
  static const _provider = 'com.example.proyecto_movil.QuestlyWidgetProvider';

  /// Bloques de hoy que aún no terminan y, después, lo que no tiene hora.
  static Future<void> update(HomeDashboard d, DateTime now) => _save(
    [
      for (final b in d.agenda)
        if (!b.done && b.end.isAfter(now)) (b.id, b.title, _hhmm(b.start)),
      for (final t in d.unscheduled) (t.id, t.title, ''),
    ].take(3).toList(),
  );

  /// Al cerrar sesión: que el widget no muestre tareas de otra cuenta.
  static Future<void> clear() => _save(const [], count: -1);

  static Future<void> _save(
    List<(String, String, String)> items, {
    int? count,
  }) async {
    try {
      await HomeWidget.saveWidgetData<int>('count', count ?? items.length);
      for (var i = 0; i < 3; i++) {
        final item = i < items.length ? items[i] : null;
        await HomeWidget.saveWidgetData<String>('task_${i}_id', item?.$1);
        await HomeWidget.saveWidgetData<String>('task_${i}_title', item?.$2);
        await HomeWidget.saveWidgetData<String>('task_${i}_time', item?.$3);
      }
      await HomeWidget.updateWidget(qualifiedAndroidName: _provider);
    } on Exception {
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

/// «✓» del widget (`questly://done?id=…`), con la app abierta o cerrada.
@pragma('vm:entry-point')
Future<void> onWidgetAction(Uri? uri) async {
  final id = uri?.queryParameters['id'];
  if (uri?.host != 'done' || id == null || !await bootInBackground()) return;
  final done = await sl<CompleteMission>()(id);
  // Se quita la fila sin esperar a abrir la app; si falló, se queda.
  if (done.isRight()) {
    final rest = (await HomeWidgetSync._read()).where((t) => t.$1 != id);
    await HomeWidgetSync._save(rest.toList());
  }
}
