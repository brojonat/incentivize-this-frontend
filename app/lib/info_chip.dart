import 'package:flutter/material.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color? backgroundColor;
  final Color? textColor;

  const InfoChip({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finalBackgroundColor = backgroundColor ?? color.withOpacity(0.1);
    final finalTextColor = textColor ?? color;
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      color: finalTextColor,
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: finalBackgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        text: TextSpan(
          style: textStyle,
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                icon,
                size: 16,
                color: finalTextColor,
              ),
            ),
            const WidgetSpan(
              child: SizedBox(width: 5),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
