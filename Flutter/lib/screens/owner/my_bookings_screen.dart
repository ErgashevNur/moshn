import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_plate.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final allBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) {
  return BookingService().getMyBookings();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen> {
  int _tab = 0; // 0=Будущие, 1=Прошедшие

  static const _upcomingStatuses = {
    'pending', 'confirmed', 'in_progress'
  };
  static const _pastStatuses = {'completed', 'cancelled'};

  List<Booking> _filter(List<Booking> all) {
    final statuses = _tab == 0 ? _upcomingStatuses : _pastStatuses;
    return all.where((b) => statuses.contains(b.status)).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(allBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: AppSpacing.md),
            _tabs(context),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: async.when(
                data: (all) {
                  final list = _filter(all);
                  if (list.isEmpty) return _empty(context);
                  return RefreshIndicator(
                    color: AppColors.gold,
                    backgroundColor: AppColors.surface(context),
                    onRefresh: () async =>
                        ref.invalidate(allBookingsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.huge),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _BookingCard(booking: list[i]),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.gold),
                ),
                error: (_, _) => Center(
                  child: GestureDetector(
                    onTap: () => ref.invalidate(allBookingsProvider),
                    child: Text('common.retry'.tr(),
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.gold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Text(
        'booking.list_title'.tr(),
        style: AppTypography.displayLarge.copyWith(
          color: AppColors.text(context),
        ),
      ),
    );
  }

  // ── Tab switcher ──────────────────────────────────────────────────────────

  Widget _tabs(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_full),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _tabItem(context, 0, 'booking.tab_upcoming'.tr()),
            _tabItem(context, 1, 'booking.tab_past'.tr()),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(BuildContext context, int index, String label) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: selected ? AppColors.inverseBg(context) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.r_full),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: selected
                  ? AppColors.inverseText(context)
                  : AppColors.text3(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _empty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📋', style: TextStyle(fontSize: 52)),
          const SizedBox(height: AppSpacing.md),
          Text(
            _tab == 0 ? 'booking.no_upcoming'.tr() : 'booking.no_past'.tr(),
            style: AppTypography.titleSmall
                .copyWith(color: AppColors.text(context)),
          ),
          const SizedBox(height: 4),
          Text(
            _tab == 0 ? 'booking.find_hint'.tr() : '',
            style: AppTypography.body
                .copyWith(color: AppColors.text3(context)),
          ),
        ],
      ),
    );
  }
}

// ── Booking card ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final shop = booking.shop;
    final vehicle = booking.vehicle;
    final serviceType = booking.serviceType;
    final initial =
        (shop?.shopName ?? 'S').isNotEmpty ? (shop?.shopName ?? 'S')[0] : 'S';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Column(
        children: [
          // ── Row 1: shop info + status badge ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface3(context),
                    borderRadius: BorderRadius.circular(AppSpacing.r_xs),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial.toUpperCase(),
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.text2(context)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              shop?.shopName ?? '—',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.text(context),
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _StatusBadge(status: booking.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (serviceType != null) ...[
                            Text(
                              serviceType.nameFor(context.locale.languageCode),
                              style: AppTypography.body.copyWith(
                                color: AppColors.text3(context),
                                fontSize: 12.5,
                              ),
                            ),
                            if (vehicle?.plate != null &&
                                vehicle!.plate.isNotEmpty)
                              const SizedBox(width: 8),
                          ],
                          if (vehicle?.plate != null &&
                              vehicle!.plate.isNotEmpty)
                            MPlate(plate: vehicle.plate),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          Divider(height: 1, color: AppColors.hairline(context)),

          // ── Row 2: date + price ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 14, color: AppColors.text3(context)),
                const SizedBox(width: 6),
                Text(
                  _smartDate(context, booking.scheduledAt),
                  style: AppTypography.body.copyWith(
                      color: AppColors.text2(context), fontSize: 13),
                ),
                const Spacer(),
                if (booking.totalPrice > 0)
                  Text(
                    _fmtPrice(booking.totalPrice),
                    style: AppTypography.mono.copyWith(
                      color: AppColors.text(context),
                      fontSize: 15,
                    ),
                  ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────────────
          Divider(height: 1, color: AppColors.hairline(context)),

          // ── Row 3: action buttons ─────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.near_me_rounded,
                    label: 'booking.direction'.tr(),
                    onTap: shop != null && (shop.latitude != 0 || shop.longitude != 0)
                        ? () => _openMaps(shop.latitude, shop.longitude,
                            shop.shopName)
                        : null,
                  ),
                ),
                VerticalDivider(
                    width: 1, color: AppColors.hairline(context)),
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.phone_rounded,
                    label: 'booking.call'.tr(),
                    onTap: (shop?.phone ?? '').isNotEmpty
                        ? () => _call(shop!.phone)
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _smartDate(BuildContext context, DateTime dt) {
    final locale = context.locale.languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final diff = d.difference(today).inDays;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return '${'dates.today'.tr()}, $time';
    if (diff == 1) return '${'dates.tomorrow'.tr()}, $time';
    if (diff == -1) return '${'dates.yesterday'.tr()}, $time';
    final months = locale == 'ru'
        ? ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек']
        : ['', 'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentyabr', 'oktyabr', 'noyabr', 'dekabr'];
    return '${dt.day} ${months[dt.month]}, $time';
  }

  String _fmtPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Future<void> _openMaps(double lat, double lng, String label) async {
    final uri = Uri.parse(
        'https://maps.google.com/?q=${Uri.encodeComponent(label)}&ll=$lat,$lng');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _resolve(context);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.r_full),
      ),
      child: Text(
        label,
        style: AppTypography.eyebrow.copyWith(color: fg, fontSize: 10),
      ),
    );
  }

  (String, Color, Color) _resolve(BuildContext context) {
    switch (status) {
      case 'pending':
        return ('booking.status_pending'.tr(), AppColors.goldDim, AppColors.gold);
      case 'confirmed':
        return ('booking.status_confirmed_short'.tr(), AppColors.successDim, AppColors.success);
      case 'in_progress':
        return ('booking.status_in_progress'.tr(), const Color(0x2938BDF8), const Color(0xFF38BDF8));
      case 'completed':
        return ('booking.status_completed'.tr(), AppColors.surface2(context),
            AppColors.text2(context));
      case 'cancelled':
        return ('booking.status_cancelled_short'.tr(), AppColors.dangerDim, AppColors.danger);
      default:
        return (status, AppColors.surface2(context), AppColors.text3(context));
    }
  }
}

// ── Action button ─────────────────────────────────────────────────────────────

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active
                  ? AppColors.text2(context)
                  : AppColors.text3(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: active
                    ? AppColors.text2(context)
                    : AppColors.text3(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
