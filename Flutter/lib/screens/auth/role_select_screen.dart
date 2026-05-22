import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/responsive.dart';
import '../../widgets/section_card.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(border: null),
      child: SafeArea(
        child: ResponsiveContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text('auth.role_select_title'.tr(),
                    style: AppTypography.largeTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'auth.role_select_subtitle'.tr(),
                  style: AppTypography.body
                      .copyWith(color: AppColors.labelTertiary),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _RoleCard(
                  icon: CupertinoIcons.car_detailed,
                  title: 'auth.role_owner'.tr(),
                  subtitle: 'auth.welcome_subtitle'.tr(),
                  onTap: () => context.push('/register?role=owner'),
                ),
                const SizedBox(height: AppSpacing.md),
                _RoleCard(
                  icon: CupertinoIcons.wrench_fill,
                  title: 'auth.role_mechanic'.tr(),
                  subtitle: 'mechanic.home_title'.tr(),
                  onTap: () => context.push('/register?role=mechanic'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.primaryOf(context);
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.headline),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_right,
              color: AppColors.labelTertiary, size: 18),
        ],
      ),
    );
  }
}
