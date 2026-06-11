import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import 'm_stars.dart';
import 'm_ph.dart';

class WorkshopCard extends StatelessWidget {
  const WorkshopCard({
    super.key,
    required this.name,
    this.imageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.address,
    this.distance,
    this.duration,
    this.isOpen,
    this.isVip = false,
    this.compact = false,
    this.onTap,
  });

  final String name;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final String? address;
  final String? distance;
  final String? duration;
  final bool? isOpen;
  final bool isVip;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;

      // Responsive ölçüler
      final imgSize  = compact ? 60.0 : (w < 320 ? 62.0 : 72.0);
      final nameSize = w < 320 ? 13.5  : 15.0;
      final metaSize = w < 320 ? 11.5  : 12.5;
      final pad      = w < 320 ? 11.0  : 13.0;
      final gap      = w < 320 ? 10.0  : 12.0;
      final starSize = w < 320 ? 11.0  : 12.5;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_lg),
            border: Border.all(color: AppColors.hairline(context), width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        width: imgSize,
                        height: imgSize,
                        fit: BoxFit.cover,
                        errorBuilder: (context, e, s) =>
                            MPh(width: imgSize, height: imgSize, label: 'SERVIS'),
                      )
                    : MPh(width: imgSize, height: imgSize, label: 'SERVIS'),
              ),
              SizedBox(width: gap),

              // Ma'lumotlar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + VIP
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTypography.soraSize(nameSize,
                                    weight: FontWeight.w600)
                                .copyWith(color: AppColors.text(context)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVip) ...[
                          const SizedBox(width: 5),
                          Icon(Icons.workspace_premium_rounded,
                              size: 14, color: AppColors.gold),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Reyting
                    Row(
                      children: [
                        MStars(value: rating, size: starSize, gap: 1.5),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${rating.toStringAsFixed(1)} · $reviewCount sharh',
                            style: AppTypography.soraSize(metaSize)
                                .copyWith(color: AppColors.text2(context)),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),

                    // Manzil
                    if (address != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: metaSize, color: AppColors.text3(context)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address!,
                              style: AppTypography.soraSize(metaSize)
                                  .copyWith(color: AppColors.text2(context)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Status qatori
                    if (isOpen != null || distance != null) ...[
                      const SizedBox(height: 4),
                      _StatusRow(
                        isOpen: isOpen,
                        distance: distance,
                        duration: duration,
                        fontSize: metaSize,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Status qatori (Hozir ochiq · 0.8 km · 4 daq) ──────────────────────────────

class _StatusRow extends StatelessWidget {
  final bool? isOpen;
  final String? distance;
  final String? duration;
  final double fontSize;

  const _StatusRow({
    this.isOpen,
    this.distance,
    this.duration,
    this.fontSize = 12.5,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Text(
      ' · ',
      style: AppTypography.soraSize(fontSize)
          .copyWith(color: AppColors.text3(context)),
    );

    return Row(
      children: [
        if (isOpen != null) ...[
          Flexible(
            child: Text(
              isOpen! ? 'common.now_open'.tr() : 'common.closed'.tr(),
              style: AppTypography.soraSize(fontSize, weight: FontWeight.w600)
                  .copyWith(
                      color: isOpen! ? AppColors.success : AppColors.danger),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        if (isOpen != null && distance != null) dot,
        if (distance != null)
          Text(
            distance!,
            style: AppTypography.soraSize(fontSize)
                .copyWith(color: AppColors.text2(context)),
          ),
        if (duration != null) ...[
          dot,
          Text(
            duration!,
            style: AppTypography.soraSize(fontSize)
                .copyWith(color: AppColors.text2(context)),
          ),
        ],
      ],
    );
  }
}
