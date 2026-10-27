import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/settings/domain/entities/game_settings.dart';

// shortcut: valores al activar límite o silencio por primera vez; no vienen
// del diseño, ajustar con PRODUCT.md.
const _defaultDailyLimit = 10;
const _defaultSilenceStart = '22:00';
const _defaultSilenceEnd = '07:00';

/// Hoja de avisos. Devuelve las reglas nuevas, o null si se cierra sin guardar.
Future<GameSettings?> showNotificationSheet(
  BuildContext context,
  GameSettings settings,
) => showModalBottomSheet<GameSettings>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _NotificationSheet(settings),
);

/// Hoja de descansos de la Mazmorra (RF-067).
Future<GameSettings?> showBreaksSheet(
  BuildContext context,
  GameSettings settings,
) => showModalBottomSheet<GameSettings>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _BreaksSheet(settings),
);

/// Resumen de una línea para la fila de Configuración.
String notificationSummary(GameSettings s) => [
  s.notificationDailyLimit == null
      ? 'Sin límite diario'
      : '${s.notificationDailyLimit} avisos al día',
  s.silenceStart == null
      ? 'sin silencio'
      : 'silencio ${s.silenceStart}–${s.silenceEnd}',
].join(' · ');

String breaksSummary(GameSettings s) =>
    '${s.shortBreakMinutes} min, y ${s.longBreakMinutes} min cada '
    '${s.longBreakEveryNCycles} ciclos';

class _NotificationSheet extends StatefulWidget {
  const _NotificationSheet(this.settings);

  final GameSettings settings;

  @override
  State<_NotificationSheet> createState() => _NotificationSheetState();
}

class _NotificationSheetState extends State<_NotificationSheet> {
  late int? _limit = widget.settings.notificationDailyLimit;
  late String? _start = widget.settings.silenceStart;
  late String? _end = widget.settings.silenceEnd;
  late bool _bypass = widget.settings.criticalBypassSilence;

  Future<String?> _pickTime(String current) async {
    final [hour, minute] = current.split(':').map(int.parse).toList();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(picked.hour)}:${two(picked.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final silence = _start != null;
    return _SheetFrame(
      title: 'Avisos',
      onSave: () => Navigator.pop(
        context,
        widget.settings.withNotifications(
          dailyLimit: _limit,
          silenceStart: _start,
          silenceEnd: _end,
          // Sin ventana de silencio no hay nada que saltar.
          criticalBypassSilence: silence && _bypass,
        ),
      ),
      children: [
        _Switch(
          title: 'Límite diario de avisos',
          subtitle: _limit == null
              ? 'Sin límite'
              : 'Hasta $_limit avisos al día',
          value: _limit != null,
          onChanged: (on) =>
              setState(() => _limit = on ? _defaultDailyLimit : null),
        ),
        if (_limit case final limit?)
          _CountStepper(
            label: 'Avisos al día',
            value: limit,
            range: GameSettings.dailyLimitRange,
            onChanged: (v) => setState(() => _limit = v),
          ),
        _Switch(
          title: 'Ventana de silencio',
          subtitle: silence
              ? 'De $_start a $_end'
              : 'Los avisos llegan a cualquier hora',
          value: silence,
          onChanged: (on) => setState(() {
            _start = on ? _defaultSilenceStart : null;
            _end = on ? _defaultSilenceEnd : null;
          }),
        ),
        if (silence) ...[
          _TimeRow(
            label: 'Desde',
            value: _start!,
            onTap: () async {
              final time = await _pickTime(_start!);
              if (time != null) setState(() => _start = time);
            },
          ),
          _TimeRow(
            label: 'Hasta',
            value: _end!,
            onTap: () async {
              final time = await _pickTime(_end!);
              if (time != null) setState(() => _end = time);
            },
          ),
          _Switch(
            title: 'Los avisos críticos pueden sonar',
            subtitle: 'Por ejemplo, una racha a punto de romperse.',
            value: _bypass,
            onChanged: (on) => setState(() => _bypass = on),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Durante una Mazmorra, los avisos no críticos esperan solos.',
          style: TextStyle(color: lq.muted, fontSize: 12),
        ),
      ],
    );
  }
}

class _BreaksSheet extends StatefulWidget {
  const _BreaksSheet(this.settings);

  final GameSettings settings;

  @override
  State<_BreaksSheet> createState() => _BreaksSheetState();
}

class _BreaksSheetState extends State<_BreaksSheet> {
  late int _short = widget.settings.shortBreakMinutes;
  late int _long = widget.settings.longBreakMinutes;
  late int _every = widget.settings.longBreakEveryNCycles;

  @override
  Widget build(BuildContext context) => _SheetFrame(
    title: 'Descansos de la Mazmorra',
    onSave: () => Navigator.pop(
      context,
      widget.settings.withBreaks(
        shortMinutes: _short,
        longMinutes: _long,
        longEveryNCycles: _every,
      ),
    ),
    children: [
      _CountStepper(
        label: 'Descanso corto',
        unit: 'min',
        value: _short,
        range: GameSettings.shortBreakRange,
        onChanged: (v) => setState(() => _short = v),
      ),
      _CountStepper(
        label: 'Descanso largo',
        unit: 'min',
        value: _long,
        range: GameSettings.longBreakRange,
        onChanged: (v) => setState(() => _long = v),
      ),
      _CountStepper(
        label: 'Descanso largo cada',
        unit: 'ciclos',
        value: _every,
        range: GameSettings.longBreakEveryRange,
        onChanged: (v) => setState(() => _every = v),
      ),
    ],
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.onSave,
    required this.children,
  });

  final String title;
  final VoidCallback onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  color: lq.ink,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...children,
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: lq.deepGreen,
                  foregroundColor: lq.onDeepGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(
      title,
      style: TextStyle(
        color: context.lq.ink,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: context.lq.muted, fontSize: 13),
    ),
    value: value,
    activeTrackColor: context.lq.deepGreen,
    onChanged: onChanged,
  );
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.only(left: 12),
    minTileHeight: 48,
    onTap: onTap,
    title: Text(label, style: TextStyle(color: context.lq.ink, fontSize: 14)),
    trailing: Text(
      value,
      style: TextStyle(
        color: context.lq.deepGreen,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Contador con − y +, limitado a [range].
class _CountStepper extends StatelessWidget {
  const _CountStepper({
    required this.label,
    required this.value,
    required this.range,
    required this.onChanged,
    this.unit,
  });

  final String label;
  final int value;
  final ({int min, int max}) range;
  final ValueChanged<int> onChanged;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final lq = context.lq;
    final text = unit == null ? '$value' : '$value $unit';
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: lq.ink, fontSize: 14)),
          ),
          IconButton(
            tooltip: 'Menos',
            onPressed: value > range.min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: lq.deepGreen,
          ),
          SizedBox(
            width: 72,
            child: Semantics(
              label: label,
              value: text,
              child: ExcludeSemantics(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lq.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Más',
            onPressed: value < range.max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: lq.deepGreen,
          ),
        ],
      ),
    );
  }
}
