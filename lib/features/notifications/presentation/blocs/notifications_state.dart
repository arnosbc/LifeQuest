part of 'notifications_bloc.dart';

sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

class NotificationsSuccess extends NotificationsState {
  const NotificationsSuccess(this.items, {this.message});

  final List<AppNotification> items;

  /// Aviso puntual (un error al refrescar o al marcar).
  final String? message;

  int get unread => items.where((n) => !n.read).length;

  @override
  List<Object?> get props => [items, message];
}

class NotificationsFailure extends NotificationsState {
  const NotificationsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
