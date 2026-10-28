import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/features/notifications/domain/entities/app_notification.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/get_notifications.dart';
import 'package:proyecto_movil/features/notifications/domain/usecases/mark_notifications_read.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required this._getNotifications,
    required this._markRead,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const NotificationsInitial()) {
    on<NotificationsRequested>(_onRequested, transformer: droppable());
    on<NotificationsRead>(_onRead, transformer: sequential());
  }

  final GetNotifications _getNotifications;
  final MarkNotificationsRead _markRead;
  final DateTime Function() _clock;

  Future<void> _onRequested(
    NotificationsRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsSuccess) emit(const NotificationsLoading());
    final result = await _getNotifications(_clock());
    emit(
      result.match(
        (failure) => current is NotificationsSuccess
            ? NotificationsSuccess(current.items, message: failure.message)
            : NotificationsFailure(failure.message),
        NotificationsSuccess.new,
      ),
    );
  }

  /// Se marca al instante en pantalla; si el servidor falla, vuelve atrás.
  Future<void> _onRead(
    NotificationsRead event,
    Emitter<NotificationsState> emit,
  ) async {
    final current = state;
    if (current is! NotificationsSuccess) return;
    final ids = event.ids?.toSet();
    emit(
      NotificationsSuccess([
        for (final n in current.items)
          ids == null || ids.contains(n.id)
              ? AppNotification(
                  id: n.id,
                  kind: n.kind,
                  title: n.title,
                  description: n.description,
                  createdAt: n.createdAt,
                  read: true,
                )
              : n,
      ]),
    );
    final result = await _markRead(event.ids);
    if (result.isLeft()) {
      emit(
        NotificationsSuccess(
          current.items,
          message: result.getLeft().toNullable()!.message,
        ),
      );
    }
  }
}
