import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proyecto_movil/features/auth/stores/auth_store.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/account_card.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/game_master_card.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/notification_preferences_sheet.dart';
import 'package:proyecto_movil/features/settings/presentation/widgets/sign_out_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, required this.userName, required this.onBack});

  final String userName;
  final VoidCallback onBack;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _notificationPreferences = NotificationPreferences();

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
      AccountCard(userName: widget.userName),
      const SizedBox(height: 11),
      GameMasterCard(
        onOpenNotificationPreferences: _showNotificationPreferences,
      ),
      const SizedBox(height: 11),
      const SignOutCard(),
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
    if (shouldSignOut != true || !mounted) return;
    await ref.read(authStoreProvider.notifier).signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _showNotificationPreferences() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) =>
        NotificationPreferencesSheet(preferences: _notificationPreferences),
  );
}
