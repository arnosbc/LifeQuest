part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar o refrescar los avisos.
class NotificationsRequested extends NotificationsEvent {
  const NotificationsRequested();
}

/// Marcar leídos [ids]; null marca todos.
class NotificationsRead extends NotificationsEvent {
  const NotificationsRead([this.ids]);

  final List<String>? ids;

  @override
  List<Object?> get props => [ids];
}
