import 'package:flutter/material.dart';
import '../theme/typography.dart';

class MPlate extends StatelessWidget {
  const MPlate({
    super.key,
    required this.plate,
    this.large = false,
  });

  final String plate;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: large
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F2),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: const Color(0x33000000),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Text(
        plate,
        style: (large ? AppTypography.mono.copyWith(fontSize: 18) : AppTypography.mono.copyWith(fontSize: 13))
            .copyWith(
          color: const Color(0xFF111111),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
