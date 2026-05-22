import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/sos_request.dart';
import '../../services/sos_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/section_card.dart';

final _sosProvider = FutureProvider.autoDispose<List<SosRequest>>((ref) {
  return SosService().mine();
});

/// Bizdagi asosiy xizmatlar — bosh sahifada ko'rsatish uchun.
const _services = [
  (icon: CupertinoIcons.gauge, title: 'Dvigatel ta\'miri', subtitle: 'Motor, moy, diagnostika'),
  (icon: CupertinoIcons.car_detailed, title: 'Xodovoy va tormoz', subtitle: 'Podveska, balatka'),
  (icon: CupertinoIcons.bolt_fill, title: 'Elektrika', subtitle: 'Provodka, akkumulyator'),
  (icon: CupertinoIcons.snow, title: 'Konditsioner', subtitle: 'Sovutish, to\'ldirish'),
];

const _sosStatusLabels = {
  'new': 'Yangi',
  'in_progress': 'Jarayonda',
  'resolved': 'Hal qilindi',
  'cancelled': 'Bekor qilindi',
};

Color _sosStatusColor(String s) {
  switch (s) {
    case 'in_progress':
      return AppColors.info;
    case 'resolved':
      return AppColors.success;
    case 'cancelled':
      return AppColors.labelTertiary;
    default:
      return AppColors.destructive; // new
  }
}

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final sos = ref.watch(_sosProvider);

    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              border: null,
              largeTitle:
                  Text('${'owner.home_title'.tr()}, ${user?.name ?? ""}'),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                onPressed: () => context.push('/owner/find-mechanic'),
                child: Icon(CupertinoIcons.search,
                    color: AppColors.primaryOf(context)),
              ),
            ),
            CupertinoSliverRefreshControl(
              onRefresh: () async {
                ref.invalidate(_sosProvider);
                await ref.read(_sosProvider.future);
              },
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  const SizedBox(height: AppSpacing.sm),
                  _SectionHeader(title: 'SOS holati'),
                  const SizedBox(height: AppSpacing.sm),
                  _SosStatusSection(state: sos),
                  const SizedBox(height: AppSpacing.xl),
                  _SectionHeader(title: 'Xizmatlar'),
                  const SizedBox(height: AppSpacing.sm),
                  const _ServicesSection(),
                  const SizedBox(height: AppSpacing.huge),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Text(title, style: AppTypography.title3),
    );
  }
}

class _SosStatusSection extends StatelessWidget {
  final AsyncValue<List<SosRequest>> state;
  const _SosStatusSection({required this.state});

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (items) {
        if (items.isEmpty) {
          return SectionCard(
            onTap: () => context.push('/owner/sos'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(CupertinoIcons.exclamationmark_shield_fill,
                      color: AppColors.destructive),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Faol SOS so\'rovi yo\'q',
                          style: AppTypography.headline),
                      const SizedBox(height: 2),
                      Text('Yo\'lda qolsangiz — SOS tugmasini bosing',
                          style: AppTypography.footnote
                              .copyWith(color: AppColors.labelTertiary)),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right,
                    color: AppColors.labelTertiary, size: 18),
              ],
            ),
          );
        }
        // Eng so'nggi 3 ta SOS so'rovi.
        return Column(
          children: items
              .take(3)
              .map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SosCard(req: s),
                  ))
              .toList(),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (_, _) => SectionCard(
        child: Text('common.error'.tr(),
            style: AppTypography.body
                .copyWith(color: AppColors.destructive)),
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  final SosRequest req;
  const _SosCard({required this.req});

  @override
  Widget build(BuildContext context) {
    final color = _sosStatusColor(req.status);
    return SectionCard(
      onTap: () => _showSosDetail(context, req),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(CupertinoIcons.exclamationmark_shield_fill, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.assignedMechanicName != null
                      ? 'Usta: ${req.assignedMechanicName}'
                      : 'SOS so\'rovi',
                  style: AppTypography.headline,
                ),
                const SizedBox(height: 2),
                Text(
                  req.address?.isNotEmpty == true
                      ? req.address!
                      : '${req.latitude.toStringAsFixed(4)}, ${req.longitude.toStringAsFixed(4)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.footnote
                      .copyWith(color: AppColors.labelTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusBadge(status: req.status),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _sosStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        _sosStatusLabels[status] ?? status,
        style: AppTypography.caption1
            .copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

void _showSosDetail(BuildContext context, SosRequest req) {
  showCupertinoModalPopup(
    context: context,
    builder: (_) => CupertinoPopupSurface(
      isSurfacePainted: true,
      child: Container(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('SOS so\'rovi', style: AppTypography.title3),
                  const Spacer(),
                  _StatusBadge(status: req.status),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _DetailRow(label: 'Aloqa raqami', value: req.phone),
              if (req.address?.isNotEmpty == true)
                _DetailRow(label: 'Manzil', value: req.address!),
              _DetailRow(
                label: 'Koordinata',
                value:
                    '${req.latitude.toStringAsFixed(5)}, ${req.longitude.toStringAsFixed(5)}',
              ),
              _DetailRow(
                label: 'Yo\'naltirilgan usta',
                value: req.assignedMechanicName ?? 'Hali biriktirilmagan',
              ),
              if (req.adminNotes?.isNotEmpty == true)
                _DetailRow(label: 'Operator izohi', value: req.adminNotes!),
              if (req.createdAt != null)
                _DetailRow(
                  label: 'Yuborilgan',
                  value: DateFormat('dd.MM.yyyy HH:mm').format(req.createdAt!),
                ),
              const SizedBox(height: AppSpacing.lg),
              CupertinoButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Yopish'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption1
                  .copyWith(color: AppColors.labelTertiary)),
          const SizedBox(height: 2),
          Text(value, style: AppTypography.body),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _services
          .map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SectionCard(
                  onTap: () => context.push('/owner/find-mechanic'),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primaryOf(context)
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(s.icon,
                            color: AppColors.primaryOf(context), size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.title, style: AppTypography.headline),
                            const SizedBox(height: 2),
                            Text(s.subtitle,
                                style: AppTypography.footnote.copyWith(
                                    color: AppColors.labelTertiary)),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          color: AppColors.labelTertiary, size: 18),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}
