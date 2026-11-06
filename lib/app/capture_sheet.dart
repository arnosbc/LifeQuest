import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/app/reminder_actions.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_sheet.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';
import 'package:proyecto_movil/features/assistant/presentation/widgets/capture_view.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Hoja «Anotar» (barra de Hoy y botón flotante). Devuelve true si se guardó
/// algo; en ese caso los avisos ya se reprogramaron.
/// [listen]: abre dictando. [sharedText]: lo que llegó de otra app (por
/// defecto va a la Bandeja).
Future<bool> openCaptureSheet(
  BuildContext context, {
  bool listen = false,
  String? sharedText,
}) async {
  final saved = await showQuestlySheet<bool>(
    context,
    title: sharedText == null ? 'Anotar' : 'Guardar lo compartido',
    child: BlocProvider(
      create: (_) => sl<CaptureBloc>(),
      child: CaptureView(
        startListening: listen,
        initialText: sharedText,
        preferInbox: sharedText != null,
      ),
    ),
  );
  if (saved == true) ReminderActions.sync();
  return saved == true;
}
