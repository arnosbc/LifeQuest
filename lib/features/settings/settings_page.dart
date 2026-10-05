import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.userName, required this.onBack});

  final String userName;
  final VoidCallback onBack;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _difficulty = 'Normal';
  bool _habitReminders = true;
  bool _missionAlerts = true;
  bool _motivationalMessages = false;

  @override
  Widget build(BuildContext context) => LifeQuestPage(
    title: 'Configuración',
    subtitle: '',
    trailing: IconButton(
      onPressed: widget.onBack,
      tooltip: 'Volver al perfil',
      visualDensity: VisualDensity.compact,
      icon: const Icon(Icons.settings_outlined, size: 17),
    ),
    children: [
      _accountCard(),
      const SizedBox(height: 11),
      _preferencesCard(context),
      const SizedBox(height: 11),
      _signOutCard(),
      const SizedBox(height: 8),
      SizedBox(
        width: double.infinity,
        height: 40,
        child: FilledButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.sports_esports_outlined, size: 15),
          label: const Text('Cancelar y Seguir Jugando'),
          style: FilledButton.styleFrom(
            backgroundColor: LifeQuestColors.green,
            textStyle: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        width: double.infinity,
        height: 36,
        child: OutlinedButton.icon(
          onPressed: _confirmSignOut,
          icon: const Icon(Icons.logout, size: 14),
          label: const Text('Cerrar Sesión'),
          style: OutlinedButton.styleFrom(
            foregroundColor: LifeQuestColors.ink,
            backgroundColor: Colors.white,
            side: const BorderSide(color: LifeQuestColors.line),
            textStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _accountCard() => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFDFF8E8),
              child: Text(
                widget.userName.isEmpty
                    ? 'A'
                    : widget.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: LifeQuestColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: LifeQuestColors.softGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'NIVEL 24',
                      style: TextStyle(
                        color: LifeQuestColors.deepGreen,
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.more_horiz,
              color: LifeQuestColors.muted,
              size: 17,
            ),
            const SizedBox(width: 5),
          ],
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PROGRESO XP',
              style: TextStyle(color: LifeQuestColors.muted, fontSize: 7),
            ),
            Text(
              '1,450 / 2,000 XP',
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 7,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const LinearProgressIndicator(
          value: .72,
          minHeight: 4,
          color: LifeQuestColors.green,
          backgroundColor: Color(0xFFE3EEE7),
        ),
      ],
    ),
  );

  Widget _preferencesCard(BuildContext context) => LifeQuestSurface(
    padding: const EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Perfil / Game Master',
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Dificultad',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _difficultyOption('Fácil'),
            const SizedBox(width: 5),
            _difficultyOption('Normal'),
            const SizedBox(width: 5),
            _difficultyOption('Difícil'),
          ],
        ),
        const SizedBox(height: 9),
        const Text(
          'Tienda',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 4),
        _settingLink(
          Icons.shopping_bag_outlined,
          'Contenido de la Tienda',
          'Accede a paquetes, recompensas y personalizaciones.',
          () => showLifeQuestMessage(
            context,
            'La tienda estará disponible próximamente.',
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Notificaciones',
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
        const SizedBox(height: 4),
        _settingLink(
          Icons.notifications_active_outlined,
          'Preferencias de notificaciones',
          'Ajusta recordatorios, logros y alertas del juego.',
          _showNotificationPreferences,
        ),
      ],
    ),
  );

  Widget _difficultyOption(String label) {
    final selected = _difficulty == label;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _difficulty = label),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? LifeQuestColors.softGreen : Colors.white,
              border: Border.all(
                color: selected ? LifeQuestColors.green : LifeQuestColors.line,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 8,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _settingLink(
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F9F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: LifeQuestColors.deepGreen, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: LifeQuestColors.ink,
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      color: LifeQuestColors.muted,
                      fontSize: 7,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: LifeQuestColors.muted,
              size: 15,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _signOutCard() => const LifeQuestSurface(
    padding: EdgeInsets.all(11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cerrar Sesión',
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Tu progreso está guardado de forma segura en la nube. Puedes volver a entrar cuando quieras.',
          style: TextStyle(
            color: LifeQuestColors.muted,
            fontSize: 8,
            height: 1.35,
          ),
        ),
      ],
    ),
  );

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tu progreso está guardado. Puedes volver cuando quieras.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (shouldSignOut == true && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _showNotificationPreferences() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => SafeArea(
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
              _preferenceSwitch('Recordatorios de hábitos', _habitReminders, (
                value,
              ) {
                setState(() => _habitReminders = value);
                setSheetState(() {});
              }),
              _preferenceSwitch('Alertas de misiones', _missionAlerts, (value) {
                setState(() => _missionAlerts = value);
                setSheetState(() {});
              }),
              _preferenceSwitch(
                'Mensajes motivacionales',
                _motivationalMessages,
                (value) {
                  setState(() => _motivationalMessages = value);
                  setSheetState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
