import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MStars extends StatelessWidget {
  const MStars({
    super.key,
    required this.value,
    this.size = 14,
    this.gap = 2,
  });

  final double value;
  final double size;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final filled = value.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? gap : 0),
          child: Icon(
            isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: isFilled ? AppColors.gold : AppColors.text3(context),
          ),
        );
      }),
    );
  }
}
