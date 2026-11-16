import 'package:home_widget/home_widget.dart';

import 'package:proyecto_movil/app/config/route_paths.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Widget «Mi día» de la pantalla de inicio (Android: LifeQuestWidgetProvider).
/// La app le pasa los datos del Inicio; el widget los dibuja y, al tocarlo,
/// abre la app con un enlace lifequest://… que [routeFor] traduce a una ruta.
abstract final class HomeScreenWidget {
  static const _provider = 'LifeQuestWidgetProvider';

  /// Datos del Inicio para el widget.
  static Future<void> show(HomeDashboard d) => _safely(() async {
    final next = d.priorityMission;
    await Future.wait([
      HomeWidget.saveWidgetData<bool>('signed_in', true),
      HomeWidget.saveWidgetData<int>('streak', d.streakDays),
      HomeWidget.saveWidgetData<int>('hp', d.hpCurrent),
      HomeWidget.saveWidgetData<int>('level', d.level),
      // Misiones de hoy = las que abren el cofre del día.
      HomeWidget.saveWidgetData<int>('missions_done', d.chest.progress),
      HomeWidget.saveWidgetData<int>('missions_goal', d.chest.required),
      // Meta diaria de XP (063); 0 = el servidor aún no la tiene.
      HomeWidget.saveWidgetData<int>('xp_done', d.dailyXp),
      HomeWidget.saveWidgetData<int>('xp_goal', d.dailyXpGoal ?? 0),
      HomeWidget.saveWidgetData<String>('next_task_id', next?.id),
      HomeWidget.saveWidgetData<String>('next_task_title', next?.title),
      // El widget decide el ánimo de la mascota con esto y la hora actual.
      HomeWidget.saveWidgetData<String>('saved_day', dayKey(DateTime.now())),
      HomeWidget.saveWidgetData<bool>('day_done', dayDone(d)),
      HomeWidget.saveWidgetData<int>('pending', pending(d)),
    ]);
    await HomeWidget.updateWidget(androidName: _provider);
  });

  /// Fecha local `yyyy-MM-dd` (la lee `LocalDate.parse` en Kotlin).
  static String dayKey(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-'
      '${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// Día cumplido: todos los hábitos de hoy (los que llevan racha) o, sin
  /// hábitos, el cofre del día.
  static bool dayDone(HomeDashboard d) => d.habitsTotal > 0
      ? d.habitsDone >= d.habitsTotal
      : d.chest.progress >= d.chest.required;

  /// Lo que falta hoy: hábitos sin hacer + tareas de la lista «Hoy».
  static int pending(HomeDashboard d) =>
      (d.habitsTotal - d.habitsDone).clamp(0, d.habitsTotal) +
      d.todayTasks.length;

  /// Al cerrar sesión el widget deja de mostrar datos de la cuenta.
  static Future<void> clear() => _safely(() async {
    await Future.wait([
      HomeWidget.saveWidgetData<bool>('signed_in', false),
      HomeWidget.saveWidgetData<int>('streak', 0),
      HomeWidget.saveWidgetData<int>('hp', 0),
      HomeWidget.saveWidgetData<int>('level', 1),
      HomeWidget.saveWidgetData<int>('missions_done', 0),
      HomeWidget.saveWidgetData<int>('xp_done', 0),
      HomeWidget.saveWidgetData<int>('xp_goal', 0),
      HomeWidget.saveWidgetData<String>('next_task_id', null),
      HomeWidget.saveWidgetData<String>('next_task_title', null),
      HomeWidget.saveWidgetData<String>('saved_day', null),
      HomeWidget.saveWidgetData<bool>('day_done', false),
      HomeWidget.saveWidgetData<int>('pending', 0),
    ]);
    await HomeWidget.updateWidget(androidName: _provider);
  });

  /// Pide al launcher colocar el widget (diálogo de Android 8+). False si el
  /// launcher no lo permite: entonces se agrega a mano desde la pantalla de inicio.
  static Future<bool> pin() async {
    final supported = await _safely(HomeWidget.isRequestPinWidgetSupported);
    if (supported != true) return false;
    await _safely(() => HomeWidget.requestPinWidget(androidName: _provider));
    return true;
  }

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Enlace del widget → ruta de la app; null si no es del widget.
  static String? routeFor(Uri? uri) {
    if (uri == null || uri.scheme != 'lifequest') return null;
    return switch (uri.host) {
      // H-05 (M4): cualquier app puede abrir este enlace; solo un UUID pasa.
      'focus' => switch (uri.queryParameters['task']) {
        final String id when _uuid.hasMatch(id) => RoutePaths.focusOn(id),
        _ => RoutePaths.dungeon,
      },
      _ => RoutePaths.home,
    };
  }

  /// Último toque del widget que la app no atendió (lo guarda MainActivity);
  /// se consume al leerlo. Null si no hay.
  static Future<Uri?> takePendingLink() async {
    final link = await _safely(
      () => HomeWidget.getWidgetData<String>('pending_link'),
    );
    if (link == null) return null;
    await _safely(
      () => HomeWidget.saveWidgetData<String>('pending_link', null),
    );
    return Uri.tryParse(link);
  }

  // Sin el plugin (tests, web, escritorio) el widget simplemente no existe.
  static Future<T?> _safely<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }
}
