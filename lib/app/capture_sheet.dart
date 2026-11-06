import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:proyecto_movil/app/reminder_actions.dart';
import 'package:proyecto_movil/core/widgets/questly/questly_sheet.dart';
import 'package:proyecto_movil/features/assistant/presentation/blocs/capture_bloc.dart';
import 'package:proyecto_movil/features/assistant/presentation/widgets/capture_view.dart';
import 'package:proyecto_movil/injection_container.dart';

/// Hoja «Anotar» (barra de Hoy y botón flotante). Devuelve true si se guardó
/// algo; en ese caso los avisos ya se reprogramaron.
Future<bool> openCaptureSheet(BuildContext context) async {
  final saved = await showQuestlySheet<bool>(
    context,
    title: 'Anotar',
    child: BlocProvider(
      create: (_) => sl<CaptureBloc>(),
      child: const CaptureView(),
    ),
  );
  if (saved == true) ReminderActions.sync();
  return saved == true;
}
