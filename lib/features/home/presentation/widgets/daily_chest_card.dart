import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';
import 'package:proyecto_movil/features/home/domain/entities/home_dashboard.dart';

/// Cofre del día: progreso hacia las misiones que lo abren y botón para
/// cobrarlo. Solo cuentan las misiones que dieron Monedas.
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
      title: chest.claimed ? 'Cofre del día abierto' : 'Cofre del día',
      subtitle: chest.claimed
          ? 'Mañana te espera otro.'
          : chest.ready
          ? '¡Listo! +${chest.coins} Monedas te esperan.'
          : 'Misiones de hoy: $progress/${chest.required} · +${chest.coins} Monedas',
      actionLabel: chest.claimed ? 'Abierto' : 'Abrir',
      busy: busy,
      onAction: chest.ready ? onClaim : null,
    );
  }
}
