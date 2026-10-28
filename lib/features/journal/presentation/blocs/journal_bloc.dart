import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/features/journal/domain/entities/journal_board.dart';
import 'package:proyecto_movil/features/journal/domain/usecases/get_journal.dart';

part 'journal_event.dart';
part 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  JournalBloc({required this._getJournal, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const JournalInitial()) {
    on<JournalRequested>(_onRequested, transformer: droppable());
  }

  final GetJournal _getJournal;
  final DateTime Function() _clock;

  Future<void> _onRequested(
    JournalRequested event,
    Emitter<JournalState> emit,
  ) async {
    final current = state;
    emit(
      current is JournalSuccess
          ? JournalSuccess(current.board, refreshing: true)
          : const JournalLoading(),
    );
    final result = await _getJournal(_clock());
    emit(
      result.match(
        (failure) => current is JournalSuccess
            ? JournalSuccess(current.board, message: failure.message)
            : JournalFailure(failure.message),
        JournalSuccess.new,
      ),
    );
  }
}
