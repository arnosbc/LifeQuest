import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';

enum _NotificationFilter { all, critical, motivational, informative }

enum _NotificationKind { critical, motivational, informative }

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  _NotificationFilter _filter = _NotificationFilter.all;
  final Set<int> _readNotifications = {};

  static const _notifications = [
    _Notification(
      id: 0,
      kind: _NotificationKind.critical,
      icon: Icons.water_drop_outlined,
      title: 'Recordatorio importante',
      description: 'No olvides Beber agua · llevas 3/4 esta semana.',
      time: 'hace 2h',
    ),
    _Notification(
      id: 1,
      kind: _NotificationKind.motivational,
      icon: Icons.local_fire_department_outlined,
      title: 'Tu racha te está esperando',
      description: 'Vuelve a Leer y mantén tu progreso de hoy.',
      time: 'hace 2h',
    ),
    _Notification(
      id: 2,
      kind: _NotificationKind.informative,
      icon: Icons.dashboard_customize_outlined,
      title: 'Digest informativo',
      description:
          '• 2 hábitos completados hoy\n• 1 recordatorio importante\n• 1 invitación para retomar tu racha',
      time: 'hoy',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _notifications
        .where((item) => _matchesFilter(item.kind))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        _header(),
        const SizedBox(height: 11),
        _filters(),
        const SizedBox(height: 13),
        if (visible.isEmpty)
          const _EmptyNotifications()
        else if (_filter == _NotificationFilter.all)
          ..._allSections(visible)
        else
          ...visible.map((item) => _notificationSection(item)),
      ],
    );
  }

  Widget _header() => Row(
    children: [
      InkWell(
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 29,
          height: 29,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: LifeQuestColors.line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.notifications_none,
            color: LifeQuestColors.green,
            size: 17,
          ),
        ),
      ),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'Notificaciones anti-estrés',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      IconButton(
        onPressed: widget.onBack,
        tooltip: 'Volver al perfil',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.close, size: 18, color: LifeQuestColors.muted),
      ),
    ],
  );

  Widget _filters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        _filterChip('Todas', _NotificationFilter.all),
        _filterChip('Crítica', _NotificationFilter.critical),
        _filterChip('Motivacional', _NotificationFilter.motivational),
        _filterChip('Informativa', _NotificationFilter.informative),
      ],
    ),
  );

  Widget _filterChip(String label, _NotificationFilter filter) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: ChoiceChip(
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
      showCheckmark: false,
      labelStyle: TextStyle(
        color: _filter == filter ? Colors.white : LifeQuestColors.muted,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
      backgroundColor: Colors.white,
      selectedColor: LifeQuestColors.green,
      side: BorderSide(
        color: _filter == filter ? LifeQuestColors.green : LifeQuestColors.line,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
  );

  List<Widget> _allSections(List<_Notification> items) => [
    for (final kind in _NotificationKind.values)
      for (final item in items.where(
        (notification) => notification.kind == kind,
      ))
        _notificationSection(item),
  ];

  Widget _notificationSection(_Notification item) => Padding(
    padding: const EdgeInsets.only(bottom: 11),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: Text(
            _kindLabel(item.kind),
            style: const TextStyle(
              color: LifeQuestColors.muted,
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _notificationCard(item),
      ],
    ),
  );

  Widget _notificationCard(_Notification item) {
    final isRead = _readNotifications.contains(item.id);
    final isDigest = item.kind == _NotificationKind.informative;
    final accent = item.kind == _NotificationKind.critical
        ? const Color(0xFF44C982)
        : LifeQuestColors.line;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _readNotifications.add(item.id)),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isDigest ? LifeQuestColors.green : LifeQuestColors.line,
            ),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LifeQuestIconTile(item.icon, size: 27),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: LifeQuestColors.ink,
                        fontSize: 9,
                        fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: LifeQuestColors.muted,
                        fontSize: 8,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.time,
                    style: const TextStyle(
                      color: LifeQuestColors.muted,
                      fontSize: 7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!isRead && !isDigest)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _matchesFilter(_NotificationKind kind) => switch (_filter) {
    _NotificationFilter.all => true,
    _NotificationFilter.critical => kind == _NotificationKind.critical,
    _NotificationFilter.motivational => kind == _NotificationKind.motivational,
    _NotificationFilter.informative => kind == _NotificationKind.informative,
  };

  String _kindLabel(_NotificationKind kind) => switch (kind) {
    _NotificationKind.critical => 'CRÍTICA',
    _NotificationKind.motivational => 'MOTIVACIONAL',
    _NotificationKind.informative => 'INFORMATIVA',
  };
}

class _Notification {
  const _Notification({
    required this.id,
    required this.kind,
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
  });

  final int id;
  final _NotificationKind kind;
  final IconData icon;
  final String title;
  final String description;
  final String time;
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 42),
    child: Column(
      children: [
        Icon(
          Icons.notifications_off_outlined,
          color: LifeQuestColors.green,
          size: 32,
        ),
        SizedBox(height: 9),
        Text(
          'No hay notificaciones en esta categoría.',
          textAlign: TextAlign.center,
          style: TextStyle(color: LifeQuestColors.muted, fontSize: 11),
        ),
      ],
    ),
  );
}
