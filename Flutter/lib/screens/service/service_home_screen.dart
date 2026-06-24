import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../../services/booking_service.dart';
import '../../services/push_service.dart';
import '../../services/shop_service.dart';
import '../../services/ws_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_plate.dart';
import '../../widgets/section_card.dart';
import 'report_screen.dart';
import 'prices_screen.dart';

final _shopProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (_) => ShopService().getMyShop(),
);

final _allBookingsProvider = FutureProvider.autoDispose<List<Booking>>(
  (_) => BookingService().getShopBookings(),
);

final _filteredBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, String?>(
  (ref, status) => BookingService().getShopBookings(status: status),
);

const _filterStatuses = [
  'all', 'pending', 'confirmed', 'in_progress', 'completed'
];

class ServiceHomeScreen extends ConsumerStatefulWidget {
  final GlobalKey? burgerKey;
  const ServiceHomeScreen({super.key, this.burgerKey});

  @override
  ConsumerState<ServiceHomeScreen> createState() => _ServiceHomeScreenState();
}

class _ServiceHomeScreenState extends ConsumerState<ServiceHomeScreen> {
  int _filterIndex = 0;
  StreamSubscription<WsEvent>? _wsSub;

  String? get _status =>
      _filterIndex == 0 ? null : _filterStatuses[_filterIndex];

  @override
  void initState() {
    super.initState();
    _wsSub = WsService.instance.events.listen(_onWsEvent);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  void _onWsEvent(WsEvent event) {
    if (event.type != 'new_booking') return;
    ref.invalidate(_allBookingsProvider);
    ref.invalidate(_filteredBookingsProvider);

    final customerName =
        (event.data['customer'] as Map<String, dynamic>?)?['fullName'] as String? ??
            'Клиент';
    final serviceTypeName =
        (event.data['serviceType'] as Map<String, dynamic>?)?['nameRu'] as String? ??
            (event.data['serviceType'] as Map<String, dynamic>?)?['nameUz'] as String? ??
            'Новая запись';

    showLocalNotification(
      title: 'Новая запись! 🔔',
      body: '$customerName — $serviceTypeName',
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Новая запись!',
                      style: AppTypography.labelMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('$customerName — $serviceTypeName',
                      style: AppTypography.labelSmall
                          .copyWith(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(_shopProfileProvider);
    final allAsync = ref.watch(_allBookingsProvider);
    final filteredAsync = ref.watch(_filteredBookingsProvider(_status));

    final shopName =
        shopAsync.valueOrNull?['shopName'] as String? ?? 'Шиномонтаж';

    final allBookings = allAsync.valueOrNull ?? [];
    final todayAll = allBookings
        .where((b) => _isToday(b.scheduledAt))
        .toList();
    final todayCompleted =
        todayAll.where((b) => b.status == 'completed').toList();
    final todayRevenue =
        todayCompleted.fold<int>(0, (sum, b) => sum + b.totalPrice);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_shopProfileProvider);
            ref.invalidate(_allBookingsProvider);
            ref.invalidate(_filteredBookingsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildHeader(context, shopName),
              ),
              SliverToBoxAdapter(
                child: _buildStats(
                  context,
                  total: todayAll.length,
                  completed: todayCompleted.length,
                  totalToday: todayAll.length,
                  revenue: todayRevenue,
                  loading: allAsync.isLoading,
                ),
              ),
              SliverToBoxAdapter(
                child: _buildScheduleHeader(context),
              ),
              SliverToBoxAdapter(
                child: _buildFilter(context),
              ),
              filteredAsync.when(
                data: (bookings) {
                  final list = _filterIndex == 0
                      ? bookings.where((b) => _isToday(b.scheduledAt)).toList()
                      : bookings.where((b) => _isToday(b.scheduledAt)).toList();
                  if (list.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmpty(context));
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (ctx, i) => _BookingCard(
                        booking: list[i],
                        onTap: () =>
                            ctx.push('/service/bookings/${list[i].id}'),
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                ),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: TextButton(
                      onPressed: () =>
                          ref.invalidate(_filteredBookingsProvider),
                      child: Text('common.retry'.tr()),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String shopName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SHINA24 PARTNER',
                  style: AppTypography.soraSize(10, weight: FontWeight.w600)
                      .copyWith(
                    color: AppColors.text3(context),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shopName,
                  style: AppTypography.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _BurgerMenu(spotlightKey: widget.burgerKey),
        ],
      ),
    );
  }

  Widget _buildStats(
    BuildContext context, {
    required int total,
    required int completed,
    required int totalToday,
    required int revenue,
    required bool loading,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
      child: Column(
        children: [
          _StatCard(
            label: 'ВСЕГО ЗАПИСЕЙ',
            value: loading ? '—' : total.toString(),
            icon: Icons.calendar_month_rounded,
            iconColor: const Color(0xFF0A84FF),
            iconBg: const Color(0xFF0A84FF).withValues(alpha: 0.18),
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatCard(
            label: 'ВЫПОЛНЕНО',
            value: loading ? '—' : '$completed/$totalToday',
            icon: Icons.check_rounded,
            iconColor: AppColors.success,
            iconBg: AppColors.successDim,
            valueColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatCard(
            label: 'ВЫРУЧКА',
            value: loading
                ? '—'
                : revenue > 0
                    ? _fmtMoney(revenue)
                    : '0',
            icon: Icons.credit_card_rounded,
            iconColor: AppColors.gold,
            iconBg: AppColors.goldDim,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader(BuildContext context) {
    final now = DateTime.now();
    final months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    final dateStr =
        '${now.day} ${months[now.month]} ${now.year}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        'РАСПИСАНИЕ НА СЕГОДНЯ — $dateStr',
        style: AppTypography.soraSize(10, weight: FontWeight.w600).copyWith(
          color: AppColors.text3(context),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFilter(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: _filterStatuses.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (ctx, i) {
          final isSelected = _filterIndex == i;
          final accent = AppColors.inverseBg(context);
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent
                    : accent.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppSpacing.radiusFull),
              ),
              alignment: Alignment.center,
              child: Text(
                _statusLabel(_filterStatuses[i]),
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.inverseText(context)
                      : accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: AppColors.text3(context)),
          const SizedBox(height: AppSpacing.md),
          Text('Сегодня нет записей',
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.text2(context))),
        ],
      ),
    );
  }

  bool _isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  String _fmtMoney(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} сум';
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'all':         return 'Все';
      case 'pending':     return 'Ожидает';
      case 'confirmed':   return 'Подтверждено';
      case 'in_progress': return 'В процессе';
      case 'completed':   return 'Выполнено';
      default:            return s;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.soraSize(10, weight: FontWeight.w600)
                      .copyWith(
                    color: AppColors.text3(context),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: AppTypography.displayMedium.copyWith(
                    color: valueColor ?? AppColors.text(context),
                    fontSize: 28,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      onTap: onTap,
      child: Row(
        children: [
          _StatusDot(booking.status),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _carName(booking.vehicle),
                        style: AppTypography.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (booking.vehicle?.plate != null &&
                        booking.vehicle!.plate.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      MPlate(plate: booking.vehicle!.plate),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  booking.serviceType
                          ?.nameFor(context.locale.languageCode) ??
                      '—',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text3(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  booking.customer?.name ?? '—',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text3(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusBadge(booking.status),
              const SizedBox(height: 4),
              Text(
                _formatTime(booking.scheduledAt),
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.text3(context)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _carName(Vehicle? vehicle) {
    if (vehicle == null) return '—';
    final parts = [
      if (vehicle.make.isNotEmpty) vehicle.make,
      if (vehicle.model.isNotEmpty) vehicle.model,
    ];
    return parts.isNotEmpty ? parts.join(' ') : vehicle.plate;
  }
}

class _StatusDot extends StatelessWidget {
  final String status;
  const _StatusDot(this.status);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: _color(status), shape: BoxShape.circle),
    );
  }

  Color _color(String s) {
    switch (s) {
      case 'pending':     return AppColors.gold;
      case 'confirmed':   return AppColors.success;
      case 'in_progress': return const Color(0xFF0A84FF);
      case 'completed':   return AppColors.success;
      case 'cancelled':   return AppColors.danger;
      default:            return const Color(0xFF8E8E93);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) => Text(
        _label(status),
        style: AppTypography.labelMedium
            .copyWith(color: _color(status), fontWeight: FontWeight.w600),
      );

  String _label(String s) {
    switch (s) {
      case 'pending':     return 'Ожидает';
      case 'confirmed':   return 'Подтверждено';
      case 'in_progress': return 'В процессе';
      case 'completed':   return 'Выполнено';
      case 'cancelled':   return 'Отменено';
      default:            return s;
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'pending':     return AppColors.gold;
      case 'confirmed':   return AppColors.success;
      case 'in_progress': return const Color(0xFF0A84FF);
      case 'completed':   return AppColors.success;
      case 'cancelled':   return AppColors.danger;
      default:            return const Color(0xFF8E8E93);
    }
  }
}

class _BurgerMenu extends ConsumerWidget {
  final GlobalKey? spotlightKey;
  const _BurgerMenu({this.spotlightKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const _BurgerSheet(),
      ),
      child: Container(
        key: spotlightKey,
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface2(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_sm),
        ),
        child: Icon(Icons.menu_rounded, color: AppColors.text(context), size: 22),
      ),
    );
  }
}

class _BurgerSheet extends StatelessWidget {
  const _BurgerSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_xl),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.text3(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _MenuItem(
            icon: Icons.bar_chart_rounded,
            label: 'Отчёт',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()));
            },
          ),
          _BurgerDivider(),
          _MenuItem(
            icon: Icons.sell_rounded,
            label: 'Цены',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PricesScreen()));
            },
          ),
          _BurgerDivider(),
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Выйти',
            color: AppColors.danger,
            onTap: () async {
              Navigator.pop(context);
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.surface(context),
                  title: Text('Выйти', style: AppTypography.titleSmall),
                  content: Text('Выйти из аккаунта?',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.text2(context))),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Выйти',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                context.go('/auth/login');
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.text(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.r_md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md + 2),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.titleSmall.copyWith(color: c)),
          ],
        ),
      ),
    );
  }
}

class _BurgerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        indent: AppSpacing.xl,
        endIndent: AppSpacing.xl,
        color: AppColors.hairline(context),
      );
}
