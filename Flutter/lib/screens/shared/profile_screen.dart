import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../store/auth_store.dart';
import '../../store/theme_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/section_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeProvider);
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              border: null,
              largeTitle: Text('tabs.profile'.tr()),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _ProfileCard(user: user),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'profile.settings'.tr(),
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.labelTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _SettingsRow(
                          icon: CupertinoIcons.moon,
                          label: 'profile.theme'.tr(),
                          value: _themeLabel(themeMode),
                          onTap: () => _showThemePicker(context, ref),
                        ),
                        _divider(),
                        _SettingsRow(
                          icon: CupertinoIcons.globe,
                          label: 'profile.language'.tr(),
                          value: context.locale.languageCode.toUpperCase(),
                          onTap: () => _showLanguagePicker(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  CupertinoButton(
                    color: AppColors.destructive.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                    onPressed: () => _confirmLogout(context, ref),
                    child: Text(
                      'auth.logout'.tr(),
                      style: AppTypography.headline.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Center(
                    child: Text(
                      '${'profile.version'.tr()} 1.0.0',
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.labelTertiary,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'profile.theme_light'.tr();
      case AppThemeMode.dark:
        return 'profile.theme_dark'.tr();
      case AppThemeMode.system:
        return 'profile.theme_system'.tr();
    }
  }

  Widget _divider() => Container(
        height: 0.5,
        margin: const EdgeInsets.only(left: AppSpacing.huge),
        color: AppColors.separator,
      );

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('profile.theme'.tr()),
        actions: [
          for (final m in AppThemeMode.values)
            CupertinoActionSheetAction(
              onPressed: () {
                ref.read(themeProvider.notifier).set(m);
                Navigator.pop(ctx);
              },
              child: Text(_themeLabel(m)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text('common.cancel'.tr()),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text('profile.language'.tr()),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              context.setLocale(const Locale('uz'));
              Navigator.pop(ctx);
            },
            child: const Text('O\'zbekcha'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              context.setLocale(const Locale('ru'));
              Navigator.pop(ctx);
            },
            child: const Text('Русский'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text('common.cancel'.tr()),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('profile.logout_confirm'.tr()),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: Text('auth.logout'.tr()),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final User? user;
  const _ProfileCard({this.user});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryOf(context).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: AppColors.primaryOf(context),
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? '—', style: AppTypography.headline),
                const SizedBox(height: 2),
                Text(
                  user?.phone ?? '',
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.labelTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.labelSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.body)),
            if (value != null)
              Text(
                value!,
                style: AppTypography.subhead.copyWith(
                  color: AppColors.labelTertiary,
                ),
              ),
            const SizedBox(width: 6),
            const Icon(CupertinoIcons.chevron_right,
                size: 16, color: AppColors.labelTertiary),
          ],
        ),
      ),
    );
  }
}
