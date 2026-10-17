import 'package:flutter/material.dart';

import 'package:proyecto_movil/core/widgets/widgets.dart';

/// Precios sin definir a propósito: la economía sigue abierta (CLAUDE.md §11).
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) => const LifeQuestPage(
    title: 'Marketplace',
    subtitle: 'Disfruta lo que has ganado. Tu avance no se toca.',
    children: [
      LifeQuestSurface(
        color: LifeQuestColors.softGreen,
        child: Row(
          children: [
            LifeQuestIconTile(Icons.monetization_on_outlined),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Tus Monedas',
                style: TextStyle(
                  color: LifeQuestColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '320',
              style: TextStyle(
                color: LifeQuestColors.deepGreen,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 14),
      LifeQuestSectionHeading('TIENDA'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.self_improvement,
        title: 'Descanso',
        subtitle: 'Una tarde libre sin culpa · precio provisional',
        trailing: '— 🪙',
      ),
      LifeQuestListRow(
        icon: Icons.icecream_outlined,
        title: 'Indulgencia',
        subtitle: 'Tu postre favorito · precio provisional',
        trailing: '— 🪙',
      ),
      LifeQuestListRow(
        icon: Icons.local_activity_outlined,
        title: 'Experiencia',
        subtitle: 'Una salida al cine · precio provisional',
        trailing: '— 🪙',
      ),
      SizedBox(height: 14),
      LifeQuestSectionHeading('HOTEL'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.hotel_outlined,
        title: 'Recuperar HP',
        subtitle: 'Un buen descanso para tu personaje',
        trailing: '— 🪙',
      ),
      SizedBox(height: 14),
      LifeQuestSectionHeading('MERCADO NEGRO'),
      SizedBox(height: 7),
      LifeQuestListRow(
        icon: Icons.local_fire_department_outlined,
        title: 'Recuperar racha',
        subtitle: 'Ítem raro · con tiempo de espera entre usos',
        trailing: '— 🪙',
      ),
    ],
  );
}
