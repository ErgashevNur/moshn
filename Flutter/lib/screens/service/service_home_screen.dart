import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../models/vehicle.dart';
import '../../services/booking_service.dart';
import '../../services/push_service.dart';
import '../../services/ws_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_plate.dart';
import '../../widgets/section_card.dart';

final _shopBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, String?>(
  (ref, status) => BookingService().getShopBookings(status: status),
);

const _filterStatuses = [
  'all', 'pending', 'confirmed', 'in_progress', 'completed'
];

class ServiceHomeScreen extends ConsumerStatefulWidget {
  const ServiceHomeScreen({super.key});

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
    // Ro'yxatni refresh qil
    ref.invalidate(_shopBookingsProvider);

    final customerName = (event.data['customer'] as Map<String, dynamic>?)?['fullName'] as String? ?? 'Mijoz';
    final serviceTypeName = (event.data['serviceType'] as Map<String, dynamic>?)?['nameUz'] as String? ?? 'Yangi bron';

    // Telefon notification ovozi bilan chiqarish
    showLocalNotification(
      title: 'Yangi bron! 🔔',
      body: '$customerName — $serviceTypeName',
      id: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
    );

    // Ilovada ham banner ko'rsat
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Yangi bron!',
                      style: AppTypography.labelMedium.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('$customerName — $serviceTypeName',
                      style: AppTypography.labelSmall.copyWith(color: Colors.white)),
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
    final bookingsAsync = ref.watch(_shopBookingsProvider(_status));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilter(),
            Expanded(
              child: bookingsAsync.when(
                data: (bookings) => bookings.isEmpty
                    ? const _Empty()
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(_shopBookingsProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: bookings.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (ctx, i) => _BookingCard(
                            booking: bookings[i],
                            onTap: () => ctx
                                .push('/service/bookings/${bookings[i].id}'),
                          ),
                        ),
                      ),
                loading: () => const Center(
                    child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_shopBookingsProvider),
                    child: Text('common.retry'.tr()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.xs, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'service.home_title'.tr(),
              style: AppTypography.displayLarge,
            ),
          ),
          IconButton(
            onPressed: () => ref.invalidate(_shopBookingsProvider),
            icon: Icon(Icons.refresh_rounded,
                color: AppColors.text2(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter() {
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
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
                  color: isSelected ? Colors.white : accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'all':         return 'service.filter_all'.tr();
      case 'pending':     return 'booking.status_pending'.tr();
      case 'confirmed':   return 'booking.status_confirmed'.tr();
      case 'in_progress': return 'booking.status_in_progress'.tr();
      case 'completed':   return 'booking.status_completed'.tr();
      default:            return s;
    }
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
                // Mashina markasi + raqami (asosiy)
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
                // Xizmat turi
                Text(
                  booking.serviceType?.nameFor(context.locale.languageCode) ?? '—',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text3(context)),
                ),
                const SizedBox(height: 2),
                // Mijoz ismi (ikkinchi darajali)
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
    final Color color;
    switch (status) {
      case 'pending':    color = AppColors.gold; break;
      case 'confirmed':  color = AppColors.success; break;
      case 'in_progress': color = const Color(0xFF0A84FF); break;
      case 'completed':  color = AppColors.success; break;
      case 'cancelled':  color = AppColors.danger; break;
      default:           color = AppColors.text3(context);
    }
    return Container(
      width: 10, height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  static String _label(String s) {
    switch (s) {
      case 'pending':     return 'booking.status_pending'.tr();
      case 'confirmed':   return 'booking.status_confirmed'.tr();
      case 'in_progress': return 'booking.status_in_progress'.tr();
      case 'completed':   return 'booking.status_completed'.tr();
      case 'cancelled':   return 'booking.status_cancelled_short'.tr();
      default:            return s;
    }
  }

  static Color _color(String s) {
    switch (s) {
      case 'pending':    return AppColors.gold;
      case 'confirmed':  return AppColors.success;
      case 'in_progress': return const Color(0xFF0A84FF);
      case 'completed':  return AppColors.success;
      case 'cancelled':  return AppColors.danger;
    }
    return const Color(0xFF8E8E93);
  }

  @override
  Widget build(BuildContext context) => Text(
        _label(status),
        style: AppTypography.labelMedium
            .copyWith(color: _color(status), fontWeight: FontWeight.w600),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('📅', style: TextStyle(fontSize: 48)),
          const SizedBox(height: AppSpacing.md),
          Text('service.no_bookings'.tr(), style: AppTypography.titleSmall),
        ],
      ),
    );
  }
}
