import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.userName = 'Alex'});

  final String userName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _green = Color(0xFF29B951);
  static const _deepGreen = Color(0xFF168B3B);
  static const _ink = Color(0xFF1D3B2B);
  static const _muted = Color(0xFF78887E);
  static const _background = Color(0xFFF4F9F6);
  static const _line = Color(0xFFD5EBDD);

  int _selectedIndex = 0;
  final Set<int> _completedHabits = {0, 1};

  static const _titles = ['Inicio', 'Misiones', 'Dungeon', 'Hábitos', 'Perfil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.edit_note,
    Icons.shield_outlined,
    Icons.monitor_heart_outlined,
    Icons.person_outline,
  ];

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _ink,
        ),
      );
  }

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildHome(),
            _buildMissions(),
            _buildDungeon(),
            _buildHabits(),
            _buildProfile(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 66,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8F7EC),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(
          _titles.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            selectedIcon: Icon(_selectedIcon(index)),
            label: _titles[index],
          ),
        ),
      ),
    );
  }

  IconData _selectedIcon(int index) => switch (index) {
    0 => Icons.home_rounded,
    1 => Icons.edit_note_rounded,
    2 => Icons.shield_rounded,
    3 => Icons.monitor_heart_rounded,
    _ => Icons.person_rounded,
  };

  Widget _buildHome() {
    return _page(
      ListView(
        padding: const EdgeInsets.fromLTRB(19, 12, 19, 18),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lunes, 28 de septiembre',
                      style: TextStyle(
                        color: _deepGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Buenos días, ${widget.userName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 19,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Tu siguiente avance está listo.',
                      style: TextStyle(color: _muted, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _roundAction(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notificaciones',
                onPressed: () =>
                    _showMessage('No tienes notificaciones nuevas.'),
              ),
              const SizedBox(width: 7),
              InkWell(
                onTap: () => _selectTab(4),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    widget.userName.isEmpty
                        ? 'A'
                        : widget.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _progressCard(),
          const SizedBox(height: 13),
          _sectionHeading(
            'MISIÓN PRIORITARIA',
            action: 'Ver todas',
            onTap: () => _selectTab(1),
          ),
          const SizedBox(height: 6),
          _priorityMission(),
          const SizedBox(height: 12),
          _sectionHeading(
            'HÁBITOS DE HOY',
            action: '🔥 12 días',
            onTap: () => _selectTab(3),
            actionIsLabel: true,
          ),
          const SizedBox(height: 6),
          _habitStrip(),
          const SizedBox(height: 12),
          _sectionHeading('ACCESOS RÁPIDOS'),
          const SizedBox(height: 6),
          _quickActions(),
        ],
      ),
    );
  }

  Widget _progressCard() {
    return _surface(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Nivel 24 · Estratega',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _coinBadge(),
            ],
          ),
          const SizedBox(height: 1),
          const Text(
            '4,150 XP para subir de nivel',
            style: TextStyle(color: _muted, fontSize: 8),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Progreso de XP',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '7,850 / 12,000',
                style: TextStyle(
                  color: _ink,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: const LinearProgressIndicator(
              value: 7850 / 12000,
              minHeight: 5,
              backgroundColor: Color(0xFFE5EEE8),
              color: _green,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(
                child: _MiniStat(value: '3 / 5', label: 'Misiones'),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _MiniStat(value: '2 / 3', label: 'Hábitos'),
              ),
              SizedBox(width: 6),
              Expanded(
                child: _MiniStat(value: '45 min', label: 'En foco'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priorityMission() {
    return _surface(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconTile(Icons.verified_user_outlined),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preparar presentación del proyecto',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Hoy · 18:00 · Alta prioridad',
                      style: TextStyle(
                        color: Color(0xFFBA6C18),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 12,
                color: Color(0xFFE5A521),
              ),
              const SizedBox(width: 3),
              const Text(
                '350 XP',
                style: TextStyle(
                  color: _ink,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 9),
              const Icon(Icons.toll, size: 12, color: _green),
              const SizedBox(width: 3),
              const Text(
                '120',
                style: TextStyle(
                  color: _deepGreen,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 25,
                child: FilledButton.icon(
                  onPressed: () => _selectTab(1),
                  icon: const Icon(Icons.play_arrow_rounded, size: 15),
                  label: const Text('Continuar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _habitStrip() {
    const habits = ['Leer', 'Ejercicio', 'Agua'];
    const icons = [
      Icons.menu_book_rounded,
      Icons.fitness_center,
      Icons.water_drop,
    ];

    return _surface(
      padding: const EdgeInsets.all(7),
      child: Row(
        children: List.generate(habits.length, (index) {
          final completed = _completedHabits.contains(index);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == habits.length - 1 ? 0 : 5,
              ),
              child: InkWell(
                onTap: () => setState(() {
                  if (completed) {
                    _completedHabits.remove(index);
                  } else {
                    _completedHabits.add(index);
                  }
                }),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  height: 47,
                  decoration: BoxDecoration(
                    color: completed ? const Color(0xFFEAF8EE) : Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        completed ? Icons.check_circle : icons[index],
                        size: 19,
                        color: completed ? _green : const Color(0xFF8FA095),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        habits[index],
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _quickActions() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 7,
      mainAxisSpacing: 7,
      childAspectRatio: 3.45,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _quickAction(
          Icons.add_box_outlined,
          'Nueva tarea',
          () => _selectTab(1),
        ),
        _quickAction(
          Icons.timer_outlined,
          'Modo focus',
          () => _showMessage('Sesión de enfoque iniciada.'),
        ),
        _quickAction(
          Icons.monitor_heart_outlined,
          'Registrar hábito',
          () => _selectTab(3),
        ),
        _quickAction(Icons.auto_awesome, 'Game Master', () => _selectTab(2)),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              _iconTile(icon, size: 22, iconSize: 13),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissions() {
    return _sectionPage(
      title: 'Misiones',
      subtitle: 'Cada paso cuenta para tu siguiente nivel.',
      children: [
        _progressCard(),
        const SizedBox(height: 15),
        _sectionHeading('EN CURSO', action: '3 activas', actionIsLabel: true),
        const SizedBox(height: 7),
        _missionTile(
          Icons.work_outline,
          'Preparar presentación del proyecto',
          'Hoy · 18:00',
          '350 XP',
          priority: true,
        ),
        const SizedBox(height: 8),
        _missionTile(
          Icons.menu_book_outlined,
          'Leer 20 páginas',
          'Hoy · Sin límite',
          '120 XP',
        ),
        const SizedBox(height: 8),
        _missionTile(
          Icons.directions_walk,
          'Salir a caminar',
          'Hoy · 30 min',
          '180 XP',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 44,
          child: FilledButton.icon(
            onPressed: () => _showMessage('Nueva misión creada.'),
            icon: const Icon(Icons.add),
            label: const Text('Crear misión'),
            style: FilledButton.styleFrom(backgroundColor: _green),
          ),
        ),
      ],
    );
  }

  Widget _buildDungeon() {
    return _sectionPage(
      title: 'Dungeon',
      subtitle: 'Enfrenta retos y gana recompensas.',
      children: [
        _surface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8EE),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.shield_moon_outlined, color: _green),
              ),
              const SizedBox(height: 13),
              const Text(
                'El desafío de hoy',
                style: TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Completa tres misiones antes de que termine el día para reclamar tu recompensa.',
                style: TextStyle(color: _muted, fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(
                    child: _MiniStat(value: '2 / 3', label: 'Retos'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(value: '500 XP', label: 'Recompensa'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: FilledButton.icon(
                  onPressed: () => _selectTab(1),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continuar desafío'),
                  style: FilledButton.styleFrom(backgroundColor: _green),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 17),
        _sectionHeading('RACHA DE AVENTURAS'),
        const SizedBox(height: 7),
        _surface(
          padding: const EdgeInsets.all(14),
          child: const Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFE5A521),
                size: 27,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '12 días seguidos',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('Mejor: 18', style: TextStyle(color: _muted, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHabits() {
    const habits = [
      ('Leer', '20 minutos de lectura', Icons.menu_book_rounded),
      ('Ejercicio', 'Muévete un poco hoy', Icons.fitness_center),
      ('Agua', 'Toma 8 vasos de agua', Icons.water_drop_outlined),
    ];

    return _sectionPage(
      title: 'Hábitos',
      subtitle: 'La constancia también es una aventura.',
      children: [
        _surface(
          padding: const EdgeInsets.all(13),
          child: const Row(
            children: [
              Expanded(
                child: _MiniStat(value: '2 / 3', label: 'Completados'),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MiniStat(value: '12 días', label: 'Racha actual'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeading('HOY · LUNES 28'),
        const SizedBox(height: 7),
        ...List.generate(habits.length, (index) {
          final done = _completedHabits.contains(index);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _surface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  _iconTile(habits[index].$3),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habits[index].$1,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          habits[index].$2,
                          style: const TextStyle(color: _muted, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      if (done) {
                        _completedHabits.remove(index);
                      } else {
                        _completedHabits.add(index);
                      }
                    }),
                    tooltip: done ? 'Marcar pendiente' : 'Completar hábito',
                    icon: Icon(
                      done ? Icons.check_circle : Icons.circle_outlined,
                      color: done ? _green : const Color(0xFF9EADA3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () => _showMessage('Hábito añadido a tu rutina.'),
            icon: const Icon(Icons.add),
            label: const Text('Añadir hábito'),
            style: OutlinedButton.styleFrom(foregroundColor: _deepGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return _sectionPage(
      title: 'Perfil',
      subtitle: 'Tu progreso, a tu manera.',
      children: [
        _surface(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              CircleAvatar(
                radius: 31,
                backgroundColor: const Color(0xFFE7F7EC),
                child: Text(
                  widget.userName.isEmpty
                      ? 'A'
                      : widget.userName[0].toUpperCase(),
                  style: const TextStyle(
                    color: _green,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                widget.userName,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Nivel 24 · Estratega',
                style: TextStyle(color: _muted, fontSize: 10),
              ),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: _MiniStat(value: '7,850', label: 'XP total'),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _MiniStat(value: '12 días', label: 'Mejor racha'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionHeading('CUENTA'),
        const SizedBox(height: 7),
        _profileAction(
          Icons.notifications_outlined,
          'Notificaciones',
          () => _showMessage('Preferencias de notificaciones.'),
        ),
        _profileAction(
          Icons.palette_outlined,
          'Apariencia',
          () => _showMessage('Tu tema actual es claro.'),
        ),
        _profileAction(
          Icons.help_outline,
          'Ayuda',
          () => _showMessage('Centro de ayuda próximamente.'),
        ),
      ],
    );
  }

  Widget _sectionPage({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return _page(
      ListView(
        padding: const EdgeInsets.fromLTRB(19, 17, 19, 20),
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 17),
          ...children,
        ],
      ),
    );
  }

  Widget _page(Widget child) =>
      Padding(padding: const EdgeInsets.only(bottom: 6), child: child);

  Widget _sectionHeading(
    String title, {
    String? action,
    VoidCallback? onTap,
    bool actionIsLabel = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64786B),
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (action != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
              child: Text(
                action,
                style: TextStyle(
                  color: actionIsLabel ? _deepGreen : _green,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _surface({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(10),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B164D28),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _roundAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(side: BorderSide(color: _line)),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 32, height: 32),
        icon: Icon(icon, size: 17, color: _ink),
      ),
    );
  }

  Widget _coinBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.toll, color: _green, size: 11),
          SizedBox(width: 4),
          Text(
            '2,450',
            style: TextStyle(
              color: _deepGreen,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconTile(IconData icon, {double size = 30, double iconSize = 16}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8EE),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(icon, color: _deepGreen, size: iconSize),
    );
  }

  Widget _missionTile(
    IconData icon,
    String title,
    String detail,
    String reward, {
    bool priority = false,
  }) {
    return _surface(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      child: Row(
        children: [
          _iconTile(icon),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(color: _muted, fontSize: 9),
                ),
              ],
            ),
          ),
          Text(
            reward,
            style: TextStyle(
              color: priority ? _deepGreen : _muted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileAction(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: _surface(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                children: [
                  Icon(icon, color: _deepGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _muted, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF3),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _HomePageState._ink,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(color: _HomePageState._muted, fontSize: 7),
          ),
        ],
      ),
    );
  }
}
