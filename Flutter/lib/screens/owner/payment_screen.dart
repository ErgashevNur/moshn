import 'dart:math';

import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../services/booking_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_plate.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _bookingForPayProvider =
    FutureProvider.autoDispose.family<Booking, String>(
  (ref, id) => BookingService().getBooking(id),
);

// ── Mock cards ────────────────────────────────────────────────────────────────

class _CardInfo {
  final String brand;
  final String last4;
  const _CardInfo(this.brand, this.last4);
}

const _mockCards = [
  _CardInfo('UZCARD', '4417'),
  _CardInfo('HUMO', '8830'),
  _CardInfo('VISA', '1234'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final int amount;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _methodIndex = 0; // 0=now, 1=later, 2=installment
  int _selectedCard = 0;
  int _tipAmount = 0;
  bool _paying = false;
  bool _paid = false;
  Booking? _confirmedBooking;

  final _cardScrollCtrl = ScrollController();
  final _cardFrac = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _cardScrollCtrl.addListener(() {
      final max = _cardScrollCtrl.position.maxScrollExtent;
      if (max > 0) {
        _cardFrac.value = (_cardScrollCtrl.offset / max).clamp(0.0, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _cardScrollCtrl.dispose();
    _cardFrac.dispose();
    super.dispose();
  }

  int get _total => widget.amount + _tipAmount;

  // ── Action ────────────────────────────────────────────────────────────────

  Future<void> _confirm() async {
    setState(() => _paying = true);

    final method = switch (_methodIndex) {
      1 => 'later',
      2 => 'installment',
      _ => 'card_qr',
    };

    try {
      await BookingService().markPaid(widget.bookingId, method);
      if (_tipAmount > 0) {
        await BookingService().addTip(widget.bookingId, _tipAmount);
      }
      if (!mounted) return;
      final booking = ref.read(_bookingForPayProvider(widget.bookingId)).valueOrNull;
      setState(() {
        _paying = false;
        _paid = true;
        _confirmedBooking = booking;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('to_pay_error'.tr()), backgroundColor: Colors.red),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_paid) return _successScreen(context, _confirmedBooking);

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
                  _bookingSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _paymentSection(context),
                  const SizedBox(height: AppSpacing.xl),
                  _tipSection(context),
                  SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24),
                ],
              ),
            ),
          ),
          _bottomBar(context),
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
            Text('payment.title'.tr(),
                style: AppTypography.appbarTitle
                    .copyWith(color: AppColors.text(context))),
          ],
        ),
      ),
    );
  }

  // ── Booking summary ───────────────────────────────────────────────────────

  Widget _bookingSection(BuildContext context) {
    final bookingAsync =
        ref.watch(_bookingForPayProvider(widget.bookingId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(context, 'payment.section_order'.tr()),
        const SizedBox(height: AppSpacing.sm),
        bookingAsync.when(
          data: (b) => _bookingCard(context, b),
          loading: () => _skeletonCard(context),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _bookingCard(BuildContext context, Booking b) {
    final shop = b.shop;
    final vehicle = b.vehicle;
    final serviceType = b.serviceType;
    final initial = (shop?.shopName ?? 'S').isNotEmpty
        ? (shop?.shopName ?? 'S')[0].toUpperCase()
        : 'S';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.goldDim,
                    borderRadius: BorderRadius.circular(AppSpacing.r_xs),
                  ),
                  alignment: Alignment.center,
                  child: Text(initial,
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.gold)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop?.shopName ?? '—',
                        style: AppTypography.labelLarge.copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (serviceType != null) ...[
                            Text(
                              serviceType.nameFor(context.locale.languageCode),
                              style: AppTypography.body.copyWith(
                                  color: AppColors.text3(context),
                                  fontSize: 12.5),
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
          Divider(height: 1, color: AppColors.hairline(context)),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 13, color: AppColors.text3(context)),
                const SizedBox(width: 6),
                Text(
                  _fmtDate(b.scheduledAt),
                  style: AppTypography.body.copyWith(
                      color: AppColors.text2(context), fontSize: 13),
                ),
                const Spacer(),
                Text(
                  _fmtTime(b.scheduledAt),
                  style: AppTypography.mono
                      .copyWith(color: AppColors.text(context), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
      ),
    );
  }

  // ── Payment methods ───────────────────────────────────────────────────────

  Widget _paymentSection(BuildContext context) {
    final methods = [
      (Icons.credit_card_rounded, 'payment.pay_now_label'.tr(), 'payment.pay_now_sub'.tr()),
      (Icons.schedule_rounded, 'payment.pay_later_label'.tr(), 'payment.pay_later_sub'.tr()),
      (Icons.credit_score_rounded, 'payment.installment_label'.tr(), 'payment.installment_sub'.tr()),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _eyebrow(context, 'payment.section_payment'.tr()),
        const SizedBox(height: AppSpacing.sm),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_md),
            border: Border.all(color: AppColors.hairline(context)),
          ),
          child: Column(
            children: List.generate(methods.length, (i) {
              final (icon, title, sub) = methods[i];
              final sel = _methodIndex == i;
              return Column(
                children: [
                  if (i > 0)
                    Divider(height: 1, color: AppColors.hairline(context)),
                  GestureDetector(
                    onTap: () => setState(() => _methodIndex = i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.surface2(context),
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.r_xs),
                            ),
                            child: Icon(icon,
                                size: 18,
                                color: sel
                                    ? AppColors.text(context)
                                    : AppColors.text2(context)),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: AppTypography.labelMedium.copyWith(
                                        color: AppColors.text(context),
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text(sub,
                                    style: AppTypography.body.copyWith(
                                        color: AppColors.text3(context),
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          _RadioCircle(selected: sel, ctx: context),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        if (_methodIndex == 0) ...[
          const SizedBox(height: AppSpacing.md),
          _cardSelector(context),
        ],
      ],
    );
  }

  // ── Card selector ─────────────────────────────────────────────────────────

  Widget _cardSelector(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 72,
          child: ListView.separated(
            controller: _cardScrollCtrl,
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemCount: _mockCards.length,
            itemBuilder: (_, i) {
              final card = _mockCards[i];
              final sel = _selectedCard == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedCard = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 128,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.inverseBg(context)
                        : AppColors.surface(context),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.r_sm),
                    border: Border.all(
                      color: sel
                          ? Colors.transparent
                          : AppColors.hairline(context),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            card.brand,
                            style: AppTypography.eyebrow.copyWith(
                              fontSize: 9,
                              color: sel
                                  ? AppColors.inverseText(context)
                                  : AppColors.text2(context),
                            ),
                          ),
                          Icon(
                            Icons.credit_card_rounded,
                            size: 15,
                            color: sel
                                ? AppColors.inverseText(context)
                                    .withValues(alpha: 0.55)
                                : AppColors.text3(context),
                          ),
                        ],
                      ),
                      Text(
                        '•••• ${card.last4}',
                        style: AppTypography.mono.copyWith(
                          fontSize: 13,
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
        _scrollBar(context, _cardFrac, _mockCards.length),
      ],
    );
  }

  // ── Tip section ───────────────────────────────────────────────────────────

  Widget _tipSection(BuildContext context) {
    const tips = [0, 10000, 20000, 50000];
    final labels = ['payment.tip_none'.tr(), '10k', '20k', '50k'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('payment.tip_title'.tr(),
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('payment.tip_sub'.tr(),
                        style: AppTypography.body.copyWith(
                            color: AppColors.text3(context),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(tips.length, (i) {
              final sel = _tipAmount == tips[i];
              return Expanded(
                child: Padding(
                  padding:
                      EdgeInsets.only(right: i < tips.length - 1 ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _tipAmount = tips[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding:
                          const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.inverseBg(context)
                            : AppColors.surface2(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.r_xs),
                        border: Border.all(
                          color: sel
                              ? Colors.transparent
                              : AppColors.hairline(context),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: AppTypography.labelSmall.copyWith(
                            color: sel
                                ? AppColors.inverseText(context)
                                : AppColors.text2(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────

  Widget _bottomBar(BuildContext context) {
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
                Text('payment.total'.tr(),
                    style: AppTypography.eyebrow
                        .copyWith(color: AppColors.text3(context))),
                const SizedBox(height: 3),
                Text(
                  "${_fmtPrice(_total)} ${'common.sum'.tr()}",
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.text(context)),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _paying ? null : _confirm,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: _paying ? 0.5 : 1.0,
                  child: Container(
                    height: AppSpacing.buttonHeight,
                    decoration: BoxDecoration(
                      color: AppColors.inverseBg(context),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.r_full),
                    ),
                    child: Center(
                      child: _paying
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.gold),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_rounded,
                                    size: 16,
                                    color: AppColors.inverseText(context)),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'payment.confirm_btn'.tr(),
                                    style: AppTypography.labelMedium
                                        .copyWith(
                                      color: AppColors.inverseText(context),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success screen ────────────────────────────────────────────────────────

  Widget _successScreen(BuildContext context, Booking? b) {
    final shop = b?.shop;
    final isVerified = shop?.verificationStatus == 'verified';
    final initial = (shop?.shopName ?? 'S').isNotEmpty
        ? (shop?.shopName ?? 'S')[0].toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.huge),

                    // ── Green check circle ──────────────────────────────────
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            color: Colors.white, size: 38),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // ── Title ──────────────────────────────────────────────
                    Text(
                      'payment.success_title'.tr(),
                      style: AppTypography.titleLarge
                          .copyWith(color: AppColors.text(context)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'payment.success_body'.tr(),
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.text3(context)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // ── Booking card ───────────────────────────────────────
                    if (b != null)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.r_md),
                          border:
                              Border.all(color: AppColors.hairline(context)),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface3(context),
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.r_xs),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(initial,
                                        style: AppTypography.labelLarge
                                            .copyWith(
                                                color:
                                                    AppColors.text2(context))),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          shop?.shopName ?? '—',
                                          style:
                                              AppTypography.labelLarge.copyWith(
                                            color: AppColors.text(context),
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if ((shop?.address ?? '').isNotEmpty)
                                          Text(
                                            shop!.address,
                                            style: AppTypography.body.copyWith(
                                                color:
                                                    AppColors.text3(context),
                                                fontSize: 12.5),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isVerified) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    const Text('👑',
                                        style: TextStyle(fontSize: 18)),
                                  ],
                                ],
                              ),
                            ),
                            Divider(
                                height: 1,
                                color: AppColors.hairline(context)),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today_rounded,
                                      size: 13,
                                      color: AppColors.text3(context)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _fmtDate(b.scheduledAt),
                                    style: AppTypography.body.copyWith(
                                        color: AppColors.text2(context),
                                        fontSize: 13),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _fmtTime(b.scheduledAt),
                                    style: AppTypography.mono.copyWith(
                                        color: AppColors.text(context),
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Bottom buttons ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Column(
                children: [
                  // Добавить в календарь
                  GestureDetector(
                    onTap: b == null ? null : () => _addToCalendar(b),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.r_full),
                        border: Border.all(
                            color: AppColors.hairline2(context)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 17,
                              color: AppColors.text(context)),
                          const SizedBox(width: 8),
                          Text(
                            'payment.add_to_calendar'.tr(),
                            style: AppTypography.labelMedium.copyWith(
                                color: AppColors.text(context),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Просмотр брони
                  GestureDetector(
                    onTap: () => context.go('/owner', extra: 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md),
                      child: Text(
                        'payment.view_booking'.tr(),
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCalendar(Booking b) {
    final shop = b.shop;
    final serviceType = b.serviceType;
    final locale = context.locale.languageCode;
    final svcName = locale == 'ru'
        ? (serviceType?.nameRu.isNotEmpty == true ? serviceType!.nameRu : serviceType?.nameUz ?? 'booking.title'.tr())
        : (serviceType?.nameUz ?? 'booking.title'.tr());
    final title = '${shop?.shopName ?? 'booking.shop'.tr()} — $svcName';
    final location = shop?.address ?? '';
    final event = Event(
      title: title,
      description: 'calendar.booked_via'.tr(),
      location: location,
      startDate: b.scheduledAt,
      endDate: b.scheduledAt.add(const Duration(hours: 1)),
      iosParams: const IOSParams(reminder: Duration(minutes: 30)),
      androidParams: const AndroidParams(emailInvites: []),
    );
    Add2Calendar.addEvent2Cal(event);
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _eyebrow(BuildContext context, String text) => Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(text,
            style: AppTypography.eyebrow
                .copyWith(color: AppColors.text3(context))),
      );

  Widget _scrollBar(
      BuildContext context, ValueNotifier<double> frac, int count) {
    const trackW = 64.0;
    const h = 3.0;
    final thumbW = (trackW / max(count, 1)).clamp(14.0, trackW);
    return Center(
      child: SizedBox(
        width: trackW,
        height: h,
        child: Stack(children: [
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
        ]),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final locale = context.locale.languageCode;
    final months = locale == 'ru'
        ? ['', 'янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек']
        : ['', 'yanvar', 'fevral', 'mart', 'aprel', 'may', 'iyun', 'iyul', 'avgust', 'sentyabr', 'oktyabr', 'noyabr', 'dekabr'];
    return '${dt.day} ${months[dt.month]}';
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

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
}

// ── Radio circle widget ───────────────────────────────────────────────────────

class _RadioCircle extends StatelessWidget {
  final bool selected;
  final BuildContext ctx;
  const _RadioCircle({required this.selected, required this.ctx});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.inverseBg(ctx)
              : AppColors.hairline2(ctx),
          width: 1.5,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.inverseBg(ctx),
                ),
              ),
            )
          : null,
    );
  }
}
