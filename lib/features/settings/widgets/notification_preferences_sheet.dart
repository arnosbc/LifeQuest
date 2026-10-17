import 'package:flutter/material.dart';

import '../../../shared/lifequest_widgets.dart';

/// Preferencias que sobreviven entre aperturas del sheet (las guarda la página).
class NotificationPreferences {
  bool habitReminders = true;
  bool missionAlerts = true;
  bool motivationalMessages = false;
}

class NotificationPreferencesSheet extends StatefulWidget {
  const NotificationPreferencesSheet({super.key, required this.preferences});

  final NotificationPreferences preferences;

  @override
  State<NotificationPreferencesSheet> createState() =>
      _NotificationPreferencesSheetState();
}

class _NotificationPreferencesSheetState
    extends State<NotificationPreferencesSheet> {
  @override
  Widget build(BuildContext context) {
    final prefs = widget.preferences;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Preferencias de notificaciones',
                style: TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _preferenceSwitch(
              'Recordatorios de hábitos',
              prefs.habitReminders,
              (value) => setState(() => prefs.habitReminders = value),
            ),
            _preferenceSwitch(
              'Alertas de misiones',
              prefs.missionAlerts,
              (value) => setState(() => prefs.missionAlerts = value),
            ),
            _preferenceSwitch(
              'Mensajes motivacionales',
              prefs.motivationalMessages,
              (value) => setState(() => prefs.motivationalMessages = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preferenceSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    dense: true,
    title: Text(
      title,
      style: const TextStyle(color: LifeQuestColors.ink, fontSize: 11),
    ),
    value: value,
    activeTrackColor: LifeQuestColors.green,
    onChanged: onChanged,
  );
}
