import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showLabel;

  const VerifiedBadge({super.key, this.size = 16, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    final icon = Icon(Icons.verified, color: color, size: size);
    if (!showLabel) return icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(width: 4),
        Text(
          'Verified',
          style: TextStyle(
            color: color,
            fontSize: size * 0.75,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
