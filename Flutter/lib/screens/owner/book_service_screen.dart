import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/service_package.dart';
import '../../models/service_type.dart';
import '../../models/shop.dart';
import '../../models/vehicle.dart';
import '../../services/booking_service.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'home_screen.dart' show serviceTypesProvider;
import 'my_vehicles_screen.dart' show vehiclesProvider;

/// Saralash tablari — maketdagi "По рейтингу / Дешевле / Рядом".
enum _Sort { rating, price, distance }

extension on _Sort {
  String get api => switch (this) {
        _Sort.rating => 'rating',
        _Sort.price => 'price',
        _Sort.distance => 'distance',
      };
  String get labelKey => switch (this) {
        _Sort.rating => 'booking.sort_rating',
        _Sort.price => 'booking.sort_price',
        _Sort.distance => 'booking.sort_distance',
      };
}

/// Tanlangan xizmat turi bo'yicha zapis oqimi:
/// servis → paket → sana → vaqt → tasdiqlash.
class BookServiceScreen extends ConsumerStatefulWidget {
  final String serviceSlug;
  const BookServiceScreen({super.key, required this.serviceSlug});

  @override
  ConsumerState<BookServiceScreen> createState() => _BookServiceScreenState();
}

class _BookServiceScreenState extends ConsumerState<BookServiceScreen> {
  _Sort _sort = _Sort.rating;

  List<Shop> _shops = [];
  bool _shopsLoading = true;

  Shop? _shop;
  List<ServicePackage> _packages = [];
  ServicePackage? _package;

  late DateTime _date = _dayOnly(DateTime.now());
  List<DateTime> _slots = [];
  DateTime? _slot;
  bool _slotsLoading = false;

  String? _vehicleId;
  bool _saving = false;

  ServiceType? get _serviceType => ref
      .read(serviceTypesProvider)
      .valueOrNull
      ?.where((t) => t.slug == widget.serviceSlug)
      .firstOrNull;

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadShops());
  }

  // ── Ma'lumot yuklash ───────────────────────────────────────────────────────

  Future<void> _loadShops() async {
    setState(() => _shopsLoading = true);
    try {
      final st = _serviceType;
      final shops = await ShopService().getShops(
        serviceType: widget.serviceSlug,
        serviceTypeId: st?.id,
        sort: _sort.api,
      );
      if (!mounted) return;
      setState(() {
        _shops = shops;
        _shopsLoading = false;
        // Tanlangan servis ro'yxatda qolmasa — tanlovni tozalaymiz.
        if (_shop != null && !shops.any((s) => s.id == _shop!.id)) {
          _shop = null;
          _packages = [];
          _package = null;
          _slots = [];
          _slot = null;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _shopsLoading = false);
    }
  }

  Future<void> _selectShop(Shop shop) async {
    setState(() {
      _shop = shop;
      _packages = [];
      _package = null;
      _slots = [];
      _slot = null;
    });
    final st = _serviceType;
    if (st == null) return;
    try {
      final pkgs = await ShopService().getPackages(shop.id, st.id);
      if (!mounted) return;
      setState(() {
        _packages = pkgs;
        // Bitta paket bo'lsa avtomatik tanlanadi — ortiqcha bosish kerak emas.
        if (pkgs.length == 1) _package = pkgs.first;
      });
      if (_package != null) _loadSlots();
    } catch (_) {/* paketsiz ham davom etadi */}
  }

  Future<void> _loadSlots() async {
    final shop = _shop;
    if (shop == null) return;
    setState(() {
      _slotsLoading = true;
      _slot = null;
    });
    try {
      final slots = await ShopService()
          .getAvailability(shop.id, _date, _package?.durationMin ?? 60);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _slotsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  // ── Zapis ──────────────────────────────────────────────────────────────────

  Future<void> _book(List<Vehicle> vehicles) async {
    final shop = _shop;
    final slot = _slot;
    if (shop == null || slot == null) return;

    final vehicleId = _vehicleId ?? (vehicles.isNotEmpty ? vehicles.first.id : null);
    if (vehicleId == null) {
      _toast('booking.no_vehicle'.tr());
      return;
    }
    final st = _serviceType;
    if (st == null) return;

    setState(() => _saving = true);
    try {
      // Usta yuborilmaydi — server shu vaqtda bo'sh ustani o'zi tayinlaydi.
      final b = await BookingService().createBooking(
        shopId: shop.id,
        packageId: _package?.id,
        vehicleId: vehicleId,
        serviceTypeId: st.id,
        scheduledAt: slot,
      );
      if (!mounted) return;
      context.pushReplacement('/owner/bookings/${b.id}');
    } catch (e) {
      if (!mounted) return;
      String msg = 'booking.error'.tr();
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) msg = '${data['message']}';
      }
      _toast(msg);
      // Vaqt oralig'ida band bo'lib qolgan bo'lishi mumkin — ro'yxatni yangilaymiz.
      _loadSlots();
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
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider).valueOrNull ?? const <Vehicle>[];
    final st = _serviceType;
    final canBook = _shop != null && _slot != null && !_saving;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(st),
            _sortTabs(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 120),
                children: [
                  if (_shopsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  else if (_shops.isEmpty)
                    _empty('booking.no_shops'.tr())
                  else
                    ..._shops.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _ShopRow(
                            shop: s,
                            selected: _shop?.id == s.id,
                            onTap: () => _selectShop(s),
                          ),
                        )),

                  if (_shop != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    _sectionLabel('booking.package'.tr()),
                    const SizedBox(height: AppSpacing.sm),
                    if (_packages.isEmpty)
                      _hint('booking.no_packages'.tr())
                    else
                      ..._packages.map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _PackageRow(
                              package: p,
                              selected: _package?.id == p.id,
                              onTap: () {
                                setState(() => _package = p);
                                _loadSlots();
                              },
                            ),
                          )),

                    if (vehicles.length > 1) ...[
                      const SizedBox(height: AppSpacing.md),
                      _sectionLabel('booking.vehicle'.tr()),
                      const SizedBox(height: AppSpacing.sm),
                      _vehiclePicker(vehicles),
                    ],

                    const SizedBox(height: AppSpacing.md),
                    _sectionLabel('booking.date'.tr()),
                    const SizedBox(height: AppSpacing.sm),
                    _datePicker(),

                    const SizedBox(height: AppSpacing.md),
                    _sectionLabel('booking.time'.tr()),
                    const SizedBox(height: AppSpacing.sm),
                    _timeGrid(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _shop == null
          ? null
          : _bottomBar(canBook, () => _book(vehicles)),
    );
  }

  Widget _header(ServiceType? st) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, AppSpacing.lg, AppSpacing.sm),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.text(context)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    st?.nameFor(context.locale.languageCode) ?? '',
                    style: AppTypography.soraSize(20, weight: FontWeight.w700)
                        .copyWith(color: AppColors.text(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'booking.shops_count'
                        .tr(namedArgs: {'count': '${_shops.length}'}),
                    style: AppTypography.body.copyWith(
                        color: AppColors.text3(context), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _sortTabs() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface2(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_full),
          ),
          child: Row(
            children: _Sort.values.map((s) {
              final active = s == _sort;
              return Expanded(
                child: GestureDetector(
                  onTap: active
                      ? null
                      : () {
                          setState(() => _sort = s);
                          _loadShops();
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? AppColors.surface(context) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.r_full),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s.labelKey.tr(),
                      style: AppTypography.soraSize(12,
                              weight: active ? FontWeight.w700 : FontWeight.w500)
                          .copyWith(
                        color: active
                            ? AppColors.text(context)
                            : AppColors.text3(context),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: AppTypography.eyebrow.copyWith(color: AppColors.text3(context)),
      );

  Widget _hint(String text) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Text(text,
            style: AppTypography.body.copyWith(color: AppColors.text3(context))),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(text,
              style: AppTypography.body.copyWith(color: AppColors.text3(context))),
        ),
      );

  Widget _vehiclePicker(List<Vehicle> vehicles) {
    final selected = _vehicleId ?? vehicles.first.id;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final v = vehicles[i];
          final active = v.id == selected;
          return GestureDetector(
            onTap: () => setState(() => _vehicleId = v.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.inverseBg(context)
                    : AppColors.surface(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_full),
                border: Border.all(
                    color: active ? Colors.transparent : AppColors.hairline(context)),
              ),
              child: Text(
                v.plate,
                style: AppTypography.labelSmall.copyWith(
                  color: active
                      ? AppColors.inverseText(context)
                      : AppColors.text2(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _datePicker() {
    final days = List.generate(14, (i) => _dayOnly(DateTime.now()).add(Duration(days: i)));
    // Kun qisqartmalari interfeys tiliga qarab (`booking.wd_*`).
    final wd = List.generate(7, (i) => 'booking.wd_$i'.tr());
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final d = days[i];
          final active = d == _date;
          return GestureDetector(
            onTap: () {
              setState(() => _date = d);
              _loadSlots();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48,
              decoration: BoxDecoration(
                color: active ? AppColors.gold : AppColors.surface(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_sm),
                border: Border.all(
                    color: active ? Colors.transparent : AppColors.hairline(context)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    wd[d.weekday - 1],
                    style: AppTypography.soraSize(9, weight: FontWeight.w500).copyWith(
                      color: active ? Colors.white : AppColors.text3(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${d.day}',
                    style: AppTypography.soraSize(17, weight: FontWeight.w700)
                        .copyWith(color: active ? Colors.white : AppColors.text(context)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _timeGrid() {
    if (_slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_package == null && _packages.isNotEmpty) {
      return _hint('booking.pick_package_first'.tr());
    }
    if (_slots.isEmpty) return _hint('booking.no_slots'.tr());

    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: _slots.map((s) {
        final active = _slot == s;
        return GestureDetector(
          onTap: () => setState(() => _slot = s),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.gold : AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppSpacing.r_full),
              border: Border.all(
                  color: active ? Colors.transparent : AppColors.hairline(context)),
            ),
            child: Text(
              hhmm(s),
              style: AppTypography.mono.copyWith(
                fontSize: 13,
                color: active ? Colors.white : AppColors.text(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bottomBar(bool canBook, VoidCallback onBook) {
    final price = _package?.price ?? _shop?.minPrice ?? 0;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
        child: FilledButton(
          onPressed: canBook ? onBook : null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.gold,
            disabledBackgroundColor: AppColors.surface2(context),
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.r_full)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(
                  price > 0
                      ? 'booking.cta_price'.tr(namedArgs: {'price': fmtSum(price)})
                      : 'booking.cta'.tr(),
                  style: AppTypography.labelMedium.copyWith(
                    color: canBook ? Colors.white : AppColors.text3(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 480000 → "480 000"
String fmtSum(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');

// ── Servis qatori ────────────────────────────────────────────────────────────

class _ShopRow extends StatelessWidget {
  final Shop shop;
  final bool selected;
  final VoidCallback onTap;

  const _ShopRow({required this.shop, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = shop;
    final sub = [
      if (s.address.isNotEmpty) s.address,
      if (s.distanceKm != null && s.distanceKm! > 0)
        '${s.distanceKm!.toStringAsFixed(1)} km',
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.hairline(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.shopName.isNotEmpty ? s.shopName : 'PitGo',
                    style: AppTypography.soraSize(15, weight: FontWeight.w700)
                        .copyWith(color: AppColors.text(context)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (s.minPrice != null)
                  Text(
                    'booking.from_price'
                        .tr(namedArgs: {'price': fmtSum(s.minPrice!)}),
                    style: AppTypography.soraSize(13, weight: FontWeight.w700)
                        .copyWith(color: AppColors.text(context)),
                  ),
              ],
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(sub,
                  style: AppTypography.body.copyWith(
                      color: AppColors.text3(context), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                const SizedBox(width: 3),
                Text(
                  s.ratingCount > 0 ? s.ratingAvg.toStringAsFixed(1) : '—',
                  style: AppTypography.soraSize(12, weight: FontWeight.w600)
                      .copyWith(color: AppColors.text2(context)),
                ),
                if (s.ratingCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    'home.reviews_count'.tr(namedArgs: {'count': '${s.ratingCount}'}),
                    style: AppTypography.body.copyWith(
                        color: AppColors.text3(context), fontSize: 11),
                  ),
                ],
              ],
            ),
            if (s.nearestSlot != null) ...[
              const SizedBox(height: 5),
              Text(
                'booking.nearest'.tr(namedArgs: {'when': _whenLabel(s.nearestSlot!)}),
                style: AppTypography.soraSize(11.5, weight: FontWeight.w600)
                    .copyWith(color: AppColors.success),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _whenLabel(DateTime d) {
    final today = DateTime.now();
    final isToday = d.year == today.year && d.month == today.month && d.day == today.day;
    final hhmm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (isToday) return '${'booking.today'.tr()} $hhmm';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} $hhmm';
  }
}

// ── Paket qatori ─────────────────────────────────────────────────────────────

class _PackageRow extends StatelessWidget {
  final ServicePackage package;
  final bool selected;
  final VoidCallback onTap;

  const _PackageRow(
      {required this.package, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = package;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.goldDim : AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(
            color: selected ? AppColors.gold : AppColors.hairline(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Radio(selected: selected),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.name,
                          style: AppTypography.soraSize(14, weight: FontWeight.w700)
                              .copyWith(color: AppColors.text(context)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.schedule_rounded,
                          size: 11, color: AppColors.text3(context)),
                      const SizedBox(width: 2),
                      Text(
                        p.durationLabel,
                        style: AppTypography.body.copyWith(
                            color: AppColors.text3(context), fontSize: 11),
                      ),
                    ],
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      p.description,
                      style: AppTypography.body.copyWith(
                          color: AppColors.text3(context), fontSize: 11.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              fmtSum(p.price),
              style: AppTypography.soraSize(14, weight: FontWeight.w700).copyWith(
                color: selected ? AppColors.gold : AppColors.text(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  final bool selected;
  const _Radio({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.gold : AppColors.hairline2(context),
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 9,
                height: 9,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: AppColors.gold),
              ),
            )
          : null,
    );
  }
}
