import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/core/widgets/questly/questly.dart';
import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/presentation/blocs/notifications_bloc.dart';

/// Centro de avisos. Necesita un [NotificationsBloc] por encima.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.onOpen});

  /// Abre dónde se resuelve el aviso; null deja solo «Leído».
  final ValueChanged<NotificationTopic>? onOpen;

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
              child: CircularProgressIndicator(color: context.lq.green),
            ),
            NotificationsFailure(:final message) => LifeQuestErrorView(
              message: message,
              onRetry: () => bloc.add(const NotificationsRequested()),
            ),
            NotificationsSuccess() => RefreshIndicator(
              color: context.lq.green,
              onRefresh: () async => bloc.add(const NotificationsRequested()),
              child: _content(bloc, state),
            ),
          };
        },
      );

  Widget _content(NotificationsBloc bloc, NotificationsSuccess state) {
    // Agrupadas por nivel en el orden del enum.
    final visible = [
      for (final kind in NotificationKind.values)
        if (_filter == null || _filter == kind)
          ...state.items.where((item) => item.kind == kind),
    ];
    return LifeQuestPage(
      title: 'Avisos',
      subtitle: 'Lo importante de hoy, sin ruido.',
      numeral: state.unread > 0 ? '${state.unread}' : null,
      numeralLabel: 'sin leer',
      children: [
        QuestlySegmented<NotificationKind?>(
          segments: const [
            (null, 'Todos'),
            (NotificationKind.critical, 'Críticos'),
            (NotificationKind.motivational, 'Importantes'),
            (NotificationKind.informative, 'Info'),
          ],
          selected: _filter,
          onChanged: (filter) => setState(() => _filter = filter),
        ),
        if (state.unread > 0)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => bloc.add(const NotificationsRead()),
              child: Text('Marcar ${state.unread} como leídos'),
            ),
          )
        else
          const SizedBox(height: 12),
        if (visible.isEmpty)
          const LifeQuestEmptyState(
            compact: true,
            illustration: LifeQuestIllustration.done,
            title: 'Todo en calma',
            message: 'No hay avisos aquí. Te diremos cuando algo importe.',
          )
        else
          for (final item in visible)
            SheetRow(
              leading: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Text(
                    _symbol(item.kind),
                    semanticsLabel: item.kind.label,
                    style: TextStyle(
                      fontSize: 16,
                      color: item.read ? context.lq.muted : context.lq.ink,
                    ),
                  ),
                ),
              ),
              title: item.title,
              subtitle:
                  '${LifeQuestDates.dayTime(item.createdAt)} · '
                  '${item.description}',
              subtitleLines: 3,
              muted: item.read,
              action: switch (widget.onOpen) {
                final open? when item.topic != NotificationTopic.other =>
                  SheetPill(
                    label: 'Abrir',
                    onTap: () {
                      if (!item.read) bloc.add(NotificationsRead([item.id]));
                      open(item.topic);
                    },
                  ),
                _ when !item.read => SheetPill(
                  label: 'Leído',
                  onTap: () => bloc.add(NotificationsRead([item.id])),
                ),
                _ => null,
              },
            ),
      ],
    );
  }

  /// Símbolo + texto: el color nunca va solo (CLAUDE.md §13).
  static String _symbol(NotificationKind kind) => switch (kind) {
    NotificationKind.critical => '▲',
    NotificationKind.motivational => '●',
    NotificationKind.informative => '○',
  };
}
