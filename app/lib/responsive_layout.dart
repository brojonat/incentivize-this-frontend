import 'package:flutter/material.dart';

class CenteredConstrainedView extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const CenteredConstrainedView({
    super.key,
    required this.child,
    this.maxWidth = 1200.0, // A common max-width for web content
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
