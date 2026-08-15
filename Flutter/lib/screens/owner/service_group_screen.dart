import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_category.dart';
import 'home_screen.dart' show serviceTypesProvider;
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_service_tile.dart';

/// Bosh ekranda tanlangan kategoriya ichidagi xizmat turlari (2-bosqich).
/// Tur bosilsa `/owner/services/:slug` (BookServiceScreen — zapis oqimi) ochiladi.
///
/// `categoryId == 'all'` — maxsus rejim: bosh ekrandagi "Barcha xizmatlar"
/// havolasi, kategoriyaga bo'lmasdan butun katalogni ko'rsatadi.
class ServiceGroupScreen extends ConsumerWidget {
  final String categoryId;
  const ServiceGroupScreen({super.key, required this.categoryId});

  static const _allId = 'all';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(serviceTypesProvider);
    final isAll = categoryId == _allId;
    final meta = serviceCategoryMeta(categoryId);
    final locale = context.locale.languageCode;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(AppSpacing.r_xs),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 17),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      isAll ? 'category.all_services'.tr() : meta.labelKey.tr(),
                      style: AppTypography.appbarTitle.copyWith(color: AppColors.text(context)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: typesAsync.when(
                data: (types) {
                  final items = isAll
                      ? types.toList()
                      : types.where((t) => t.categoryOrOther == categoryId).toList();
                  if (items.isEmpty) {
                    return Center(
                      child: Text('category.empty'.tr(), style: AppTypography.body.copyWith(color: AppColors.text3(context))),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, i) {
                      final t = items[i];
                      return MServiceTile(
                        label: t.nameFor(locale),
                        iconName: t.icon,
                        active: false,
                        onTap: () => context.push('/owner/services/${t.slug}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text('common.error'.tr(), style: AppTypography.body.copyWith(color: AppColors.text3(context))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
