import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_type.dart';
import '../../models/vehicle.dart';
import '../../services/booking_service.dart';
import '../../services/shop_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _vehiclesForBookingProvider =
    FutureProvider.autoDispose<List<Vehicle>>((ref) {
  return VehicleService().getVehicles();
});

final _serviceTypesForBookingProvider =
    FutureProvider.autoDispose<List<ServiceType>>((ref) {
  return ShopService().getServiceTypes();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class CreateBookingScreen extends ConsumerStatefulWidget {
  final String shopId;
  final String shopName;
  final String shopAddress;
  final bool isVerified;

  const CreateBookingScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    this.shopAddress = '',
    this.isVerified = false,
  });

  @override
  ConsumerState<CreateBookingScreen> createState() =>
      _CreateBookingScreenState();
}

class _CreateBookingScreenState extends ConsumerState<CreateBookingScreen> {
  String? _vehicleId;
  String? _serviceTypeId;
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  bool _saving = false;

  final _chipScrollCtrl = ScrollController();
  final _dateScrollCtrl = ScrollController();
  final _chipFrac = ValueNotifier<double>(0);
  final _dateFrac = ValueNotifier<double>(0);

  static const _unavailableSlots = <String>{};
  static final _timeSlots = _buildSlots();

  static List<String> _buildSlots() {
    final slots = <String>[];
    for (var h = 9; h <= 18; h++) {
      for (final m in [0, 30]) {
        if (h == 18 && m == 30) break;
        slots.add(
            '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
      }
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _chipScrollCtrl.addListener(_onChipScroll);
    _dateScrollCtrl.addListener(_onDateScroll);
  }

  void _onChipScroll() {
    final max = _chipScrollCtrl.position.maxScrollExtent;
    if (max > 0) {
      _chipFrac.value = (_chipScrollCtrl.offset / max).clamp(0.0, 1.0);
    }
  }

  void _onDateScroll() {
    final max = _dateScrollCtrl.position.maxScrollExtent;
    if (max > 0) {
      _dateFrac.value = (_dateScrollCtrl.offset / max).clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _chipScrollCtrl
      ..removeListener(_onChipScroll)
      ..dispose();
    _dateScrollCtrl
      ..removeListener(_onDateScroll)
      ..dispose();
    _chipFrac.dispose();
    _dateFrac.dispose();
    super.dispose();
  }

  // ── Action ────────────────────────────────────────────────────────────────

  Future<void> _confirm(int price) async {
    if (_vehicleId == null) {
      _toast('Avtomobilingizni tanlang');
      return;
    }
    if (_serviceTypeId == null) {
      _toast('Xizmat turini tanlang');
      return;
    }
    if (_selectedTime == null) {
      _toast('Vaqtni tanlang');
      return;
    }

    final parts = _selectedTime!.split(':');
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );

    setState(() => _saving = true);
    try {
      final booking = await BookingService().createBooking(
        shopId: widget.shopId,
        vehicleId: _vehicleId!,
        serviceTypeId: _serviceTypeId!,
        scheduledAt: scheduledAt,
        notes: '',
      );
      if (!mounted) return;
      context.push('/owner/bookings/${booking.id}/pay?amount=$price');
    } catch (e) {
      if (mounted) _toast(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: AppTypography.body.copyWith(color: Colors.white)),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r_xs)),
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  List<DateTime> get _dates {
    final today = DateTime.now();
    return List.generate(
        14,
        (i) =>
            DateTime(today.year, today.month, today.day).add(Duration(days: i)));
  }

  String _dayLabel(DateTime date) {
    final today = DateTime.now();
    final diff = date
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
    if (diff == 0) return 'Bugun';
    if (diff == 1) return 'Ert';
    const abbr = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return abbr[date.weekday - 1];
  }

  String _fmtPrice(int price) {
    if (price <= 0) return '0';
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  bool _dateSelected(DateTime d) =>
      d.day == _selectedDate.day && d.month == _selectedDate.month;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(_vehiclesForBookingProvider);
    final typesAsync = ref.watch(_serviceTypesForBookingProvider);
    final price = typesAsync.valueOrNull
            ?.where((t) => t.id == _serviceTypeId)
            .firstOrNull
            ?.basePrice ??
        0;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          _appBar(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  _shopCard(context),
                  const SizedBox(height: AppSpacing.xl),
                  _serviceSection(context, typesAsync),
                  const SizedBox(height: AppSpacing.xl),
                  _vehicleSection(context, vehiclesAsync),
                  const SizedBox(height: AppSpacing.xl),
                  _dateSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _slotsSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          _bottomBar(context, price),
        ],
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────

  Widget _appBar(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
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
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.text(context), size: 17),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              'Vaqtga yozilish',
              style: AppTypography.appbarTitle
                  .copyWith(color: AppColors.text(context)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shop card ─────────────────────────────────────────────────────────────

  Widget _shopCard(BuildContext context) {
    final initial =
        widget.shopName.isNotEmpty ? widget.shopName[0].toUpperCase() : 'S';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.goldDim,
              borderRadius: BorderRadius.circular(AppSpacing.r_xs),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppTypography.titleSmall.copyWith(color: AppColors.gold),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shopName.isNotEmpty ? widget.shopName : 'Shinomontaj',
                  style: AppTypography.labelLarge
                      .copyWith(color: AppColors.text(context)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.shopAddress.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11, color: AppColors.text3(context)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          widget.shopAddress,
                          style: AppTypography.body.copyWith(
                              color: AppColors.text3(context), fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (widget.isVerified) ...[
            const SizedBox(width: AppSpacing.sm),
            const Text('👑', style: TextStyle(fontSize: 22)),
          ],
        ],
      ),
    );
  }

  // ── Eyebrow label ─────────────────────────────────────────────────────────

  Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          text,
          style: AppTypography.eyebrow.copyWith(color: AppColors.text3(context)),
        ),
      );

  // ── Scroll indicator ──────────────────────────────────────────────────────

  Widget _scrollBar(
      BuildContext context, ValueNotifier<double> frac, int count) {
    const trackW = 72.0;
    const h = 3.0;
    final thumbW = (trackW / max(count, 1)).clamp(14.0, trackW);
    return Center(
      child: SizedBox(
        width: trackW,
        height: h,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.hairline2(context),
                borderRadius: BorderRadius.circular(h),
              ),
            ),
            ValueListenableBuilder<double>(
              valueListenable: frac,
              builder: (_, v, _) => AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                margin: EdgeInsets.only(left: v * (trackW - thumbW)),
                width: thumbW,
                decoration: BoxDecoration(
                  color: AppColors.inverseBg(context),
                  borderRadius: BorderRadius.circular(h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Service type chips ────────────────────────────────────────────────────

  Widget _serviceSection(
      BuildContext context, AsyncValue<List<ServiceType>> async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, 'XIZMATNI TANLANG'),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          data: (types) => Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView.separated(
                  controller: _chipScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemCount: types.length,
                  itemBuilder: (_, i) {
                    final t = types[i];
                    final sel = _serviceTypeId == t.id;
                    return GestureDetector(
                      onTap: () => setState(() => _serviceTypeId = t.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.inverseBg(context)
                              : AppColors.surface(context),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.r_full),
                          border: Border.all(
                            color: sel
                                ? Colors.transparent
                                : AppColors.hairline2(context),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t.icon,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              t.nameFor(context.locale.languageCode),
                              style: AppTypography.labelSmall.copyWith(
                                color: sel
                                    ? AppColors.inverseText(context)
                                    : AppColors.text2(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _scrollBar(context, _chipFrac, types.length),
            ],
          ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SizedBox(
                height: 44,
                child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Vehicle list ──────────────────────────────────────────────────────────

  Widget _vehicleSection(
      BuildContext context, AsyncValue<List<Vehicle>> async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, 'AVTOMOBILINGIZ'),
        const SizedBox(height: AppSpacing.sm),
        async.when(
          data: (vehicles) => vehicles.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.r_md),
                    ),
                    child: Text(
                      'Avtomobil qo\'shilmagan. Avval avtomobil qo\'shing.',
                      style: AppTypography.body
                          .copyWith(color: AppColors.text3(context)),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(vehicles.length, (i) {
                    final v = vehicles[i];
                    final sel = _vehicleId == v.id;
                    return Padding(
                      padding: EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: i < vehicles.length - 1 ? AppSpacing.sm : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _vehicleId = v.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.surface2(context)
                                : AppColors.surface(context),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.r_md),
                            border: Border.all(
                              color: sel
                                  ? AppColors.inverseBg(context)
                                      .withValues(alpha: 0.25)
                                  : AppColors.hairline(context),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.surface3(context),
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.r_xs),
                                ),
                                child: Icon(Icons.directions_car_rounded,
                                    size: 20,
                                    color: AppColors.text2(context)),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${v.make} ${v.model}'.trim().isEmpty
                                          ? v.plate
                                          : '${v.make} ${v.model}'.trim(),
                                      style:
                                          AppTypography.labelMedium.copyWith(
                                        color: AppColors.text(context),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'R15 185/65',
                                      style: AppTypography.body.copyWith(
                                          color: AppColors.text3(context),
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm, vertical: 3),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppColors.hairline2(context)),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.r_xs),
                                ),
                                child: Text(
                                  v.plate,
                                  style: AppTypography.mono.copyWith(
                                      fontSize: 11,
                                      color: AppColors.text2(context)),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              _RadioDot(
                                  selected: sel,
                                  context: context),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child:
                Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Date selector ─────────────────────────────────────────────────────────

  Widget _dateSection(BuildContext context) {
    final dates = _dates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, 'SANA'),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 68,
          child: ListView.separated(
            controller: _dateScrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemCount: dates.length,
            itemBuilder: (_, i) {
              final d = dates[i];
              final sel = _dateSelected(d);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDate = d;
                  _selectedTime = null;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.inverseBg(context)
                        : AppColors.surface(context),
                    borderRadius: BorderRadius.circular(AppSpacing.r_sm),
                    border: Border.all(
                      color: sel
                          ? Colors.transparent
                          : AppColors.hairline(context),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _dayLabel(d),
                        style: AppTypography.eyebrow.copyWith(
                          fontSize: 9,
                          color: sel
                              ? AppColors.inverseText(context)
                                  .withValues(alpha: 0.55)
                              : AppColors.text3(context),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${d.day}',
                        style: AppTypography.soraSize(22,
                                weight: FontWeight.w700)
                            .copyWith(
                          color: sel
                              ? AppColors.inverseText(context)
                              : AppColors.text(context),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _scrollBar(context, _dateFrac, dates.length),
      ],
    );
  }

  // ── Time slots grid ───────────────────────────────────────────────────────

  Widget _slotsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context, 'booking.free_slots'.tr()),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: LayoutBuilder(
            builder: (_, box) {
              const cols = 4;
              const gap = AppSpacing.sm;
              final cellW = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _timeSlots.map((slot) {
                  final unavail = _unavailableSlots.contains(slot);
                  final sel = _selectedTime == slot && !unavail;
                  return GestureDetector(
                    onTap:
                        unavail ? null : () => setState(() => _selectedTime = slot),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: cellW,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.inverseBg(context)
                            : unavail
                                ? AppColors.surface(context)
                                    .withValues(alpha: 0.4)
                                : AppColors.surface(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.r_xs),
                        border: Border.all(
                          color: sel
                              ? Colors.transparent
                              : unavail
                                  ? AppColors.hairline(context)
                                      .withValues(alpha: 0.35)
                                  : AppColors.hairline(context),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          slot,
                          style: AppTypography.mono.copyWith(
                            fontSize: 13,
                            color: sel
                                ? AppColors.inverseText(context)
                                : unavail
                                    ? AppColors.text3(context)
                                    : AppColors.text(context),
                            decoration: unavail
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.text3(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _bottomBar(BuildContext context, int price) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bg(context),
          border: Border(top: BorderSide(color: AppColors.hairline(context))),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'JAMI',
                  style: AppTypography.eyebrow
                      .copyWith(color: AppColors.text3(context)),
                ),
                const SizedBox(height: 3),
                Text(
                  price > 0 ? "${_fmtPrice(price)} ${'common.sum'.tr()}" : "— ${'common.sum'.tr()}",
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.text(context)),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: _saving ? null : () => _confirm(price),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 150),
                opacity: _saving ? 0.5 : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _saving
                      ? [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.gold,
                            ),
                          ),
                        ]
                      : [
                          Text(
                            'booking.to_payment'.tr(),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.text(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded,
                              size: 18, color: AppColors.text(context)),
                        ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Radio dot ─────────────────────────────────────────────────────────────────

class _RadioDot extends StatelessWidget {
  final bool selected;
  final BuildContext context;

  const _RadioDot({required this.selected, required this.context});

  @override
  Widget build(BuildContext _) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            selected ? AppColors.inverseBg(context) : Colors.transparent,
        border: Border.all(
          color: selected
              ? AppColors.inverseBg(context)
              : AppColors.hairline2(context),
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded,
              size: 11, color: AppColors.inverseText(context))
          : null,
    );
  }
}
