import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ResponsiveContent(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tight = constraints.maxHeight < 640;
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: tight ? AppSpacing.xl : AppSpacing.huge),
                        const _Logo(),
                        const SizedBox(height: AppSpacing.xxl),
                        Text(
                          'auth.welcome_title'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTypography.largeTitle,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'auth.welcome_subtitle'.tr(),
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.labelTertiary,
                          ),
                        ),
                        SizedBox(height: tight ? AppSpacing.xxl : AppSpacing.huge * 1.5),
                        PrimaryButton(
                          label: 'auth.login'.tr(),
                          onPressed: () => context.push('/login'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SecondaryButton(
                          label: 'auth.register'.tr(),
                          onPressed: () => context.push('/role'),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    // Logo is pure black-on-transparent. On dark backgrounds it would vanish,
    // so wrap it in a white rounded plate that doubles as a visual emblem.
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl + 8),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Image.asset(
          'assets/images/moshn_logo.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
