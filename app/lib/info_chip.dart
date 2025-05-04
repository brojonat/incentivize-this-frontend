import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const InfoChip({
    Key? key,
    required this.icon,
    required this.text,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18, // Keeping the slightly larger size
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelLarge?.copyWith(
              // Keeping the prominent style
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
