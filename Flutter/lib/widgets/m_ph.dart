import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';

/// Placeholder image widget with diagonal stripe pattern.
class MPh extends StatelessWidget {
  const MPh({
    super.key,
    required this.width,
    required this.height,
    this.radius = 0,
    this.label = '',
  });

  final double width;
  final double height;
  final double radius;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: const Alignment(-1, -1),
          end: const Alignment(1, 1),
          colors: [
            AppColors.surface2(context),
            AppColors.surface(context),
          ],
          stops: const [0.0, 1.0],
          tileMode: TileMode.repeated,
        ),
      ),
      child: label.isNotEmpty
          ? Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.bg(context).withAlpha(230),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  label.length > 10 ? label.substring(0, 8).toUpperCase() : label.toUpperCase(),
                  style: AppTypography.eyebrow.copyWith(
                    color: AppColors.text3(context),
                    fontSize: 9,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
