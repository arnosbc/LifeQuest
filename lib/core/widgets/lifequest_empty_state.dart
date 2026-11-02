import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:proyecto_movil/core/theme/questly_palette.dart';
import 'package:proyecto_movil/core/theme/questly_theme.dart';
import 'package:proyecto_movil/core/widgets/sheet_row.dart';

/// Ilustraciones de trazo para estados vacíos, en una cuadrícula de 160 × 120.
/// `{i}` tinta, `{p}` hoja, `{t}` tinte, `{a}` acento cálido.
enum LifeQuestIllustration {
  /// Hoja en blanco con lápiz: aún no hay nada.
  blank(
    '<ellipse cx="80" cy="108" rx="50" ry="5" fill="{t}"/>'
    '<rect x="42" y="28" width="64" height="76" rx="6" fill="{t}" stroke="{i}" '
    'transform="rotate(-7 74 66)"/>'
    '<rect x="48" y="24" width="64" height="80" rx="6" fill="{p}" stroke="{i}"/>'
    '<path d="M48 36V30a6 6 0 0 1 6-6h52a6 6 0 0 1 6 6v6z" fill="{i}"/>'
    '<path d="M60 52h40M60 64h40M60 76h24" stroke="{t}" stroke-width="4"/>'
    '<g transform="rotate(32 118 66)"><rect x="112" y="36" width="12" '
    'height="44" rx="2" fill="{a}" stroke="{i}"/><path d="M112 80l6 12 6-12z" '
    'fill="{p}" stroke="{i}"/><path d="M112 44h12" stroke="{i}"/></g>'
    '<path d="M28 44v10M23 49h10M134 20v8M130 24h8" stroke="{i}"/>',
  ),

  /// Hoja con un visto grande y un sol: todo hecho.
  done(
    '<ellipse cx="80" cy="108" rx="50" ry="5" fill="{t}"/>'
    '<circle cx="124" cy="30" r="12" fill="{a}"/>'
    '<path d="M124 10v-4M144 30h4M138 16l3-3M110 16l-3-3" stroke="{a}"/>'
    '<rect x="42" y="28" width="64" height="76" rx="6" fill="{t}" stroke="{i}" '
    'transform="rotate(-7 74 66)"/>'
    '<rect x="48" y="24" width="64" height="80" rx="6" fill="{p}" stroke="{i}"/>'
    '<path d="M48 36V30a6 6 0 0 1 6-6h52a6 6 0 0 1 6 6v6z" fill="{i}"/>'
    '<path d="M64 70l10 10 22-24" stroke="{i}" stroke-width="5"/>'
    '<path d="M28 44v10M23 49h10" stroke="{i}"/>',
  ),

  /// Brote en maceta: hábitos por sembrar.
  sprout(
    '<ellipse cx="80" cy="108" rx="44" ry="5" fill="{t}"/>'
    '<path d="M62 82h36l-5 22H67z" fill="{t}" stroke="{i}"/>'
    '<rect x="56" y="74" width="48" height="10" rx="3" fill="{p}" stroke="{i}"/>'
    '<path d="M80 74V44" stroke="{i}"/>'
    '<path d="M80 58c-14 0-22-8-22-20 12 0 22 7 22 20z" fill="{p}" stroke="{i}"/>'
    '<path d="M80 50c0-13 8-22 24-22 0 13-9 22-24 22z" fill="{a}" stroke="{i}"/>'
    '<path d="M34 40v10M29 45h10M126 66v8M122 70h8" stroke="{i}"/>',
  );

  const LifeQuestIllustration(this.svg);

  final String svg;
}

/// Estado vacío con ilustración, título, texto y una acción que invita.
class LifeQuestEmptyState extends StatelessWidget {
  const LifeQuestEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final LifeQuestIllustration illustration;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Ilustración más pequeña para estados dentro de una sección.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final art = illustration.svg
        .replaceAll('{i}', hex(q.text))
        .replaceAll('{p}', hex(q.card))
        .replaceAll('{t}', hex(q.track))
        .replaceAll('{a}', hex(q.mustard));
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 12 : 24),
      child: Column(
        children: [
          ExcludeSemantics(
            child: SvgPicture.string(
              '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 120" '
              'fill="none" stroke-width="2.5" stroke-linecap="round" '
              'stroke-linejoin="round">$art</svg>',
              height: compact ? 84 : 120,
            ),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: QText.title3(q.text)),
          if (message case final message?) ...[
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: QText.body(q.text2),
            ),
          ],
          if (actionLabel case final label?) ...[
            const SizedBox(height: 14),
            SheetPill(label: label, onTap: onAction),
          ],
        ],
      ),
    );
  }
}
