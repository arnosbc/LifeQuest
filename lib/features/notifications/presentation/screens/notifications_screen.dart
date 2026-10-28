import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/presentation/blocs/notifications_bloc.dart';
import 'package:proyecto_movil/features/notifications/presentation/widgets/empty_notifications.dart';
import 'package:proyecto_movil/features/notifications/presentation/widgets/notification_card.dart';
import 'package:proyecto_movil/features/notifications/presentation/widgets/notification_filter_chips.dart';
import 'package:proyecto_movil/features/notifications/presentation/widgets/notifications_header.dart';

/// Centro de avisos. Necesita un [NotificationsBloc] por encima.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationKind? _filter;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<NotificationsBloc, NotificationsState>(
        listenWhen: (_, s) => s is NotificationsSuccess && s.message != null,
        listener: (context, s) =>
            showLifeQuestMessage(context, (s as NotificationsSuccess).message!),
        builder: (context, state) {
          final bloc = context.read<NotificationsBloc>();
          return switch (state) {
            NotificationsInitial() || NotificationsLoading() => Center(
              child: CircularProgressIndicator(color: context.lq.deepGreen),
            ),
            NotificationsFailure(:final message) => LifeQuestErrorView(
              message: message,
              onRetry: () => bloc.add(const NotificationsRequested()),
            ),
            NotificationsSuccess() => RefreshIndicator(
              color: context.lq.deepGreen,
              onRefresh: () async => bloc.add(const NotificationsRequested()),
              child: _content(bloc, state),
            ),
          };
        },
      );

  Widget _content(NotificationsBloc bloc, NotificationsSuccess state) {
    // Agrupadas por categoría en el orden del enum.
    final visible = [
      for (final kind in NotificationKind.values)
        if (_filter == null || _filter == kind)
          ...state.items.where((item) => item.kind == kind),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      children: [
        NotificationsHeader(onBack: widget.onBack),
        const SizedBox(height: 11),
        NotificationFilterChips(
          selected: _filter,
          onSelected: (filter) => setState(() => _filter = filter),
        ),
        if (state.unread > 0)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => bloc.add(const NotificationsRead()),
              child: Text('Marcar ${state.unread} como leídos'),
            ),
          ),
        const SizedBox(height: 8),
        if (visible.isEmpty)
          const EmptyNotifications()
        else
          for (final item in visible)
            NotificationCard(
              item: item,
              isRead: item.read,
              onTap: item.read
                  ? () {}
                  : () => bloc.add(NotificationsRead([item.id])),
            ),
      ],
    );
  }
}
