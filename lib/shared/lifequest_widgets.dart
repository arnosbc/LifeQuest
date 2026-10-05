import 'package:flutter/material.dart';

abstract final class LifeQuestColors {
  static const green = Color(0xFF29B951);
  static const deepGreen = Color(0xFF168B3B);
  static const ink = Color(0xFF1D3B2B);
  static const muted = Color(0xFF78887E);
  static const background = Color(0xFFF4F9F6);
  static const line = Color(0xFFD5EBDD);
  static const softGreen = Color(0xFFE8F7EC);
}

class LifeQuestPage extends StatelessWidget {
  const LifeQuestPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(19, 17, 19, 22),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: LifeQuestColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 3),
      Text(
        subtitle,
        style: const TextStyle(color: LifeQuestColors.muted, fontSize: 11),
      ),
      const SizedBox(height: 17),
      ...children,
    ],
  );
}

class LifeQuestSurface extends StatelessWidget {
  const LifeQuestSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: LifeQuestColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 7,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class LifeQuestSectionHeading extends StatelessWidget {
  const LifeQuestSectionHeading(
    this.title, {
    super.key,
    this.action,
    this.onTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF64786B),
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (action != null)
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
            child: Text(
              action!,
              style: const TextStyle(
                color: LifeQuestColors.green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  );
}

class LifeQuestStat extends StatelessWidget {
  const LifeQuestStat({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFFF0FAF3),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: LifeQuestColors.ink,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: LifeQuestColors.muted, fontSize: 8),
        ),
      ],
    ),
  );
}

class LifeQuestIconTile extends StatelessWidget {
  const LifeQuestIconTile(this.icon, {super.key, this.size = 34});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFEAF8EE),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Icon(icon, color: LifeQuestColors.deepGreen, size: size * .55),
  );
}

void showLifeQuestMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: LifeQuestColors.ink,
      ),
    );
}
