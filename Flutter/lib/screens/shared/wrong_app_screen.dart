import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_flavor.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_button.dart';

/// PitGo ikkita alohida ilovaga bo'lingan (PitGo — mijoz, PitGo Pro —
/// servis/usta/evakuator). Agar hisob joriy ilovaga mos rolga ega bo'lmasa
/// (masalan servis egasi PitGo (mijoz) ilovasiga kirsa), router shu ekranga
/// yo'naltiradi — foydalanuvchi tushunarli xabar oladi va chiqib, to'g'ri
/// ilovaga o'tishi mumkin.
class WrongAppScreen extends ConsumerWidget {
  const WrongAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(AppSpacing.r_xl),
                  border: Border.all(color: AppColors.hairline(context)),
                ),
                child: Icon(Icons.swap_horiz_rounded, size: 34, color: AppColors.text2(context)),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Bu ilova sizga mos emas',
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge.copyWith(color: AppColors.text(context)),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sizning hisobingiz "${AppFlavorConfig.otherAppName}" ilovasi uchun. '
                'Iltimos, o\'sha ilovani yuklab oling va shu hisob bilan kiring.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.text2(context)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              MButton(
                label: 'Chiqish',
                variant: MButtonVariant.outline,
                onTap: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/onboarding');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
