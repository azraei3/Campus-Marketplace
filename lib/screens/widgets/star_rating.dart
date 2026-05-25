import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double value;
  final double size;
  final ValueChanged<int>? onChanged;
  final int max;

  const StarRating({
    super.key,
    required this.value,
    this.size = 24,
    this.onChanged,
    this.max = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final int index = i + 1;
        final bool filled = value >= index;
        final bool half = !filled && value >= index - 0.5;
        final icon = filled
            ? Icons.star
            : half
                ? Icons.star_half
                : Icons.star_border;
        final color = filled || half ? Colors.amber : Colors.grey.shade400;

        if (onChanged == null) {
          return Icon(icon, size: size, color: color);
        }
        return InkResponse(
          onTap: () => onChanged!(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, size: size, color: color),
          ),
        );
      }),
    );
  }
}
