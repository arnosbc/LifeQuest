import 'package:flutter/material.dart';

import '../../shared/lifequest_widgets.dart';
import '../dungeon/dungeon_page.dart';
import '../habits/habits_page.dart';
import '../missions/missions_page.dart';
import '../profile/appearance_page.dart';
import '../profile/help_page.dart';
import '../profile/notifications_page.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import 'home_dashboard_page.dart';

enum _ProfileSubpage { none, notifications, help, appearance }

/// Main application shell. It owns navigation; each destination owns its UI
/// and local state in its own feature.
class HomePage extends StatefulWidget {
  const HomePage({super.key, this.userName = 'Alex'});

  final String userName;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  _ProfileSubpage _profileSubpage = _ProfileSubpage.none;

  static const _labels = ['Inicio', 'Misiones', 'Dungeon', 'Hábitos', 'Perfil'];
  static const _icons = [
    Icons.home_outlined,
    Icons.edit_note_outlined,
    Icons.shield_outlined,
    Icons.monitor_heart_outlined,
    Icons.person_outline,
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeDashboardPage(userName: widget.userName, onNavigate: _selectTab),
      const MissionsPage(),
      const DungeonPage(),
      const HabitsPage(),
      ProfilePage(
        userName: widget.userName,
        onOpenNotifications: () =>
            _openProfileSubpage(_ProfileSubpage.notifications),
        onOpenHelp: () => _openProfileSubpage(_ProfileSubpage.help),
        onOpenAppearance: () => _openProfileSubpage(_ProfileSubpage.appearance),
        onOpenSettings: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (settingsContext) => SettingsPage(
              userName: widget.userName,
              onBack: () => Navigator.of(settingsContext).pop(),
            ),
          ),
        ),
      ),
      NotificationsPage(
        onBack: () => _openProfileSubpage(_ProfileSubpage.none),
      ),
      HelpPage(onBack: () => _openProfileSubpage(_ProfileSubpage.none)),
      AppearancePage(onBack: () => _openProfileSubpage(_ProfileSubpage.none)),
    ];

    return Scaffold(
      backgroundColor: LifeQuestColors.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: switch (_profileSubpage) {
            _ProfileSubpage.none => _selectedIndex,
            _ProfileSubpage.notifications => 5,
            _ProfileSubpage.help => 6,
            _ProfileSubpage.appearance => 7,
          },
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 66,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        backgroundColor: Colors.white,
        indicatorColor: LifeQuestColors.softGreen,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: List.generate(
          _labels.length,
          (index) => NavigationDestination(
            icon: Icon(_icons[index]),
            selectedIcon: Icon(_selectedIcon(index)),
            label: _labels[index],
          ),
        ),
      ),
    );
  }

  void _selectTab(int index) => setState(() {
    _selectedIndex = index;
    _profileSubpage = _ProfileSubpage.none;
  });

  void _openProfileSubpage(_ProfileSubpage page) =>
      setState(() => _profileSubpage = page);

  IconData _selectedIcon(int index) => switch (index) {
    0 => Icons.home_rounded,
    1 => Icons.edit_note_rounded,
    2 => Icons.shield_rounded,
    3 => Icons.monitor_heart_rounded,
    _ => Icons.person_rounded,
  };
}
