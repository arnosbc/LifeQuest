import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:proyecto_movil/core/errors/exceptions.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';

/// Lo que vive en el propio dispositivo: las notificaciones del sistema, el
/// código del dispositivo (036) y la revisión periódica en segundo plano.
/// Lanza [CacheException].
abstract class NotificationsLocalDataSource {
  /// Prepara el plugin. [onOpened] se llama al tocar una notificación, también
  /// si fue ella la que abrió la app.
  Future<void> initialize({void Function()? onOpened});

  /// Pide permiso para mostrar notificaciones (Android 13+, iOS).
  Future<bool> requestPermission();

  Future<String?> readDeviceToken();

  /// null borra el código guardado.
  Future<void> saveDeviceToken(String? token);

  Future<void> show(List<AppNotification> items);

  /// Revisa cada ~15 min aunque la app esté cerrada (mínimo de Android).
  Future<void> startPeriodicCheck();

  Future<void> stopPeriodicCheck();
}

class NotificationsLocalDataSourceImpl implements NotificationsLocalDataSource {
  NotificationsLocalDataSourceImpl({
    required this.backgroundDispatcher,
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferencesAsync? prefs,
    Workmanager? workmanager,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _prefs = prefs ?? SharedPreferencesAsync(),
       _workmanager = workmanager ?? Workmanager();

  /// Función de nivel superior que atiende la revisión en segundo plano.
  final void Function() backgroundDispatcher;
  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferencesAsync _prefs;
  final Workmanager _workmanager;

  static const _tokenKey = 'device_notifications_token';
  static const periodicTask = 'lifequest.device_notifications';

  // Un canal por nivel: el usuario puede silenciar cada uno en Ajustes.
  static const _channels = {
    NotificationKind.critical: AndroidNotificationDetails(
      'critical',
      'Avisos críticos',
      channelDescription: 'Rachas y proyectos que necesitan tu atención hoy.',
      importance: Importance.high,
      priority: Priority.high,
    ),
    NotificationKind.motivational: AndroidNotificationDetails(
      'motivational',
      'Avisos importantes',
      channelDescription: 'Logros, niveles y cofres listos.',
    ),
    NotificationKind.informative: AndroidNotificationDetails(
      'informational',
      'Resumen del día',
      channelDescription: 'El resumen con lo que vence y lo pendiente.',
      importance: Importance.low,
      priority: Priority.low,
    ),
  };

  bool _ready = false;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error) {
      throw CacheException('$error');
    }
  }

  @override
  Future<void> initialize({void Function()? onOpened}) => _guard(() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: onOpened == null
          ? null
          : (_) => onOpened(),
    );
    _ready = true;
    if (onOpened == null) return;
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) onOpened();
  });

  @override
  Future<bool> requestPermission() => _guard(() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  });

  @override
  Future<String?> readDeviceToken() =>
      _guard(() => _prefs.getString(_tokenKey));

  @override
  Future<void> saveDeviceToken(String? token) => _guard(
    () => token == null
        ? _prefs.remove(_tokenKey)
        : _prefs.setString(_tokenKey, token),
  );

  @override
  Future<void> show(List<AppNotification> items) => _guard(() async {
    if (!_ready) await initialize();
    for (final n in items) {
      await _plugin.show(
        // Mismo id → misma notificación: nunca se duplica en la bandeja.
        id: n.id.hashCode & 0x7fffffff,
        title: n.title,
        body: n.description,
        notificationDetails: NotificationDetails(
          android: _channels[n.kind],
          iOS: const DarwinNotificationDetails(),
        ),
      );
    }
  });

  @override
  Future<void> startPeriodicCheck() => _guard(() async {
    await _workmanager.initialize(backgroundDispatcher);
    await _workmanager.registerPeriodicTask(
      periodicTask,
      periodicTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  });

  @override
  Future<void> stopPeriodicCheck() =>
      _guard(() => _workmanager.cancelByUniqueName(periodicTask));
}
