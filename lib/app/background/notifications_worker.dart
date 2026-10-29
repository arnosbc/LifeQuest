import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'package:proyecto_movil/app/config/constants.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/deliver_device_notifications.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Revisión periódica de avisos (workmanager, ~15 min). Corre en su propio
/// isolate aunque la app esté cerrada: pide al servidor lo que toca mostrar
/// ahora (036 aplica silencio, límite, digest y Mazmorra) y lo muestra.
@pragma('vm:entry-point')
void notificationsWorker() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (AppConstants.supabaseUrl.isEmpty) return true;
    if (!sl.isRegistered<DeliverDeviceNotifications>()) {
      await initBackgroundDependencies();
    }
    // Si falla (sin red), la próxima revisión lo recoge: no se reintenta.
    await sl<DeliverDeviceNotifications>()(DateTime.now());
    return true;
  });
}
