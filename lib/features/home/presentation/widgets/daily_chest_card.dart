import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Recompensa diaria (antes Cofre del día): progreso hacia las tareas que la
/// desbloquean y botón para cobrarla. Solo cuentan las que dieron Monedas.
class DailyChestCard extends StatelessWidget {
  const DailyChestCard({
    super.key,
    required this.chest,
    required this.busy,
    required this.onClaim,
  });

  final DailyChest chest;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final progress = chest.progress.clamp(0, chest.required);
    return LifeQuestActionRow(
      icon: chest.claimed ? Icons.inventory_2_outlined : Icons.redeem_outlined,
      title: chest.claimed ? 'Recompensa diaria cobrada' : 'Recompensa diaria',
      subtitle: chest.claimed
          ? 'Mañana tendrás otra.'
          : chest.ready
          ? '¡Lista! +${chest.coins} Monedas te esperan.'
          : 'Tareas de hoy: $progress/${chest.required} · +${chest.coins} Monedas',
      actionLabel: chest.claimed ? 'Cobrada' : 'Cobrar',
      busy: busy,
      onAction: chest.ready ? onClaim : null,
    );
  }
}
