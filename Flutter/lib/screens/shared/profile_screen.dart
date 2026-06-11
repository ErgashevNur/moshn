import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../store/auth_store.dart';
import '../../store/theme_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_moshn_icon.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user      = ref.watch(authProvider).user;
    final themeMode = ref.watch(themeProvider);
    final locale    = context.locale.languageCode;
    final safeBot   = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(18, 16, 18, 32 + safeBot),
          children: [
            // ── Sarlavha ──────────────────────────────────────────────────
            Text(
              'profile.title'.tr(),
              style: AppTypography.soraSize(28, weight: FontWeight.w700)
                  .copyWith(
                    color: AppColors.text(context),
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
            ),
            const SizedBox(height: 20),

            // ── Foydalanuvchi kartochkasi ─────────────────────────────────
            _UserCard(user: user),
            const SizedBox(height: 12),

            // ── Til + Ko'rinish ───────────────────────────────────────────
            _Group(children: [
              _SegmentRow(
                icon: Icons.language_rounded,
                label: 'profile.language'.tr(),
                options: const ["O'Z", 'РУ'],
                activeIndex: locale == 'uz' ? 0 : 1,
                onSelect: (i) => context.setLocale(
                    i == 0 ? const Locale('uz') : const Locale('ru')),
              ),
              _Hairline(),
              _SegmentRow(
                icon: Icons.nightlight_round,
                label: 'profile.appearance'.tr(),
                options: [
                  'profile.theme_day'.tr(),
                  'profile.theme_night'.tr(),
                ],
                activeIndex: themeMode == AppThemeMode.dark ? 1 : 0,
                onSelect: (i) => ref
                    .read(themeProvider.notifier)
                    .set(i == 1 ? AppThemeMode.dark : AppThemeMode.light),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Menu elementlari ──────────────────────────────────────────
            _Group(children: [
              _MenuItem(
                icon: Icons.credit_card_rounded,
                label: 'profile.payment_methods'.tr(),
              ),
              _Hairline(indent: 62),
              _MenuItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'profile.my_reviews'.tr(),
              ),
              _Hairline(indent: 62),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'profile.notifications'.tr(),
              ),
              _Hairline(indent: 62),
              _MenuItem(
                icon: Icons.shield_outlined,
                label: 'profile.help'.tr(),
              ),
            ]),
            const SizedBox(height: 12),

            // ── Servislar uchun ───────────────────────────────────────────
            _ServiceCard(),
            const SizedBox(height: 36),

            // ── Chiqish ───────────────────────────────────────────────────
            Center(
              child: GestureDetector(
                onTap: () => _confirmLogout(context, ref),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.logout_rounded,
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: 7),
                      Text(
                        'profile.logout'.tr(),
                        style: AppTypography.soraSize(15, weight: FontWeight.w600)
                            .copyWith(color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
          side: BorderSide(color: AppColors.hairline(ctx), width: 1),
        ),
        title: Text(
          'profile.logout_confirm_title'.tr(),
          style: AppTypography.soraSize(17, weight: FontWeight.w600)
              .copyWith(color: AppColors.text(ctx)),
        ),
        content: Text(
          'profile.logout_confirm_body'.tr(),
          style: AppTypography.body.copyWith(color: AppColors.text2(ctx)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'profile.logout_cancel'.tr(),
              style: AppTypography.soraSize(14, weight: FontWeight.w500)
                  .copyWith(color: AppColors.text2(ctx)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            child: Text(
              'profile.logout'.tr(),
              style: AppTypography.soraSize(14, weight: FontWeight.w600)
                  .copyWith(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Foydalanuvchi kartochkasi ──────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final User? user;
  const _UserCard({this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_lg),
          border: Border.all(color: AppColors.hairline(context), width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface2(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_md),
                border: Border.all(color: AppColors.hairline(context), width: 1),
              ),
              alignment: Alignment.center,
              child: MoshnIcon(
                name: 'user',
                size: 24,
                color: AppColors.text3(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'profile.user_placeholder'.tr(),
                    style: AppTypography.soraSize(16, weight: FontWeight.w600)
                        .copyWith(color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.phone ?? '+998 (__) ___-__-__',
                    style: AppTypography.body.copyWith(
                        color: AppColors.text3(context), fontSize: 13.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.text3(context)),
          ],
        ),
      ),
    );
  }
}

// ── Guruh konteyner ───────────────────────────────────────────────────────────

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        border: Border.all(color: AppColors.hairline(context), width: 1),
      ),
      child: Column(children: children),
    );
  }
}

// ── Segment qator (Til, Ko'rinish) ────────────────────────────────────────────

class _SegmentRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<String> options;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _SegmentRow({
    required this.icon,
    required this.label,
    required this.options,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.text2(context)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.text(context)),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          _SegmentPill(
            options: options,
            activeIndex: activeIndex,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  final List<String> options;
  final int activeIndex;
  final ValueChanged<int> onSelect;

  const _SegmentPill({
    required this.options,
    required this.activeIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final active = i == activeIndex;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.surface(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.r_xs),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(26),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              child: Text(
                options[i],
                style: AppTypography.soraSize(12.5,
                        weight: active ? FontWeight.w600 : FontWeight.w400)
                    .copyWith(
                  color: active
                      ? AppColors.text(context)
                      : AppColors.text2(context),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Menu elementi ─────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surface2(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_xs),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: AppColors.text2(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body
                    .copyWith(color: AppColors.text(context)),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.text3(context)),
          ],
        ),
      ),
    );
  }
}

// ── Hairline ajratuvchi ───────────────────────────────────────────────────────

class _Hairline extends StatelessWidget {
  final double indent;
  const _Hairline({this.indent = 0});

  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        margin: EdgeInsets.only(left: indent),
        color: AppColors.hairline(context),
      );
}

// ── Servislar uchun kartochka ─────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_lg),
          border: Border.all(color: AppColors.hairline(context), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface2(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_xs),
              ),
              alignment: Alignment.center,
              child: MoshnIcon(
                name: 'wrench',
                size: 20,
                color: AppColors.text2(context),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.for_services'.tr(),
                    style: AppTypography.soraSize(14.5, weight: FontWeight.w600)
                        .copyWith(color: AppColors.text(context)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'profile.for_services_sub'.tr(),
                    style: AppTypography.body.copyWith(
                        color: AppColors.text3(context), fontSize: 12),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.text3(context)),
          ],
        ),
      ),
    );
  }
}
