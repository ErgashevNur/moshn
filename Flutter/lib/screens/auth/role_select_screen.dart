import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_button.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'auth.role_select_title'.tr(),
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.text(context),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'auth.role_select_subtitle'.tr(),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.text2(context),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _RoleCard(
                      selected: _selected == UserRole.owner,
                      icon: Icons.directions_car_rounded,
                      title: 'auth.role_owner'.tr(),
                      subtitle: 'auth.role_owner_sub'.tr(),
                      onTap: () => setState(() => _selected = UserRole.owner),
                    ),
                    const SizedBox(height: 12),
                    _RoleCard(
                      selected: _selected == UserRole.service,
                      icon: Icons.tire_repair_rounded,
                      title: 'auth.role_service'.tr(),
                      subtitle: 'auth.role_service_sub'.tr(),
                      onTap: () => setState(() => _selected = UserRole.service),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: MButton(
                label: 'auth.continue_btn'.tr(),
                onTap: _selected != null
                    ? () => context.push('/profile-setup', extra: _selected)
                    : null,
                enabled: _selected != null,
                trailing: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.inverseBg(context)
              : AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
          border: Border.all(
            color: selected
                ? AppColors.inverseBg(context)
                : AppColors.hairline(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.inverseText(context).withValues(alpha: 0.15)
                    : AppColors.surface2(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_md),
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected
                    ? AppColors.inverseText(context)
                    : AppColors.text(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.soraSize(16, weight: FontWeight.w700)
                        .copyWith(
                      color: selected
                          ? AppColors.inverseText(context)
                          : AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body.copyWith(
                      color: selected
                          ? AppColors.inverseText(context)
                              .withValues(alpha: 0.7)
                          : AppColors.text2(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? AppColors.inverseText(context)
                    : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.inverseText(context)
                      : AppColors.hairline2(context),
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded,
                      size: 14, color: AppColors.inverseBg(context))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
