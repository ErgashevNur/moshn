import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/service_type.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/section_card.dart';

// ── Currencies ────────────────────────────────────────────────────────────────

class _Currency {
  final String code;
  final String symbol;
  final String flag;
  const _Currency(this.code, this.symbol, this.flag);
}

const _currencies = [
  _Currency('UZS', 'сўм', '🇺🇿'),
  _Currency('USD', '\$',  '🇺🇸'),
  _Currency('EUR', '€',   '🇪🇺'),
  _Currency('RUB', '₽',   '🇷🇺'),
  _Currency('GBP', '£',   '🇬🇧'),
  _Currency('KZT', '₸',   '🇰🇿'),
];

_Currency _getCur(String code) =>
    _currencies.firstWhere((c) => c.code == code, orElse: () => _currencies[0]);

// ── Data provider ─────────────────────────────────────────────────────────────

final _pricesDataProvider =
    FutureProvider.autoDispose<_PricesData>((ref) async {
  final shop = ShopService();
  final results = await Future.wait([
    shop.getServiceTypes(),
    shop.getMyShop(),
    shop.getMyPrices(),
  ]);
  final allTypes      = results[0] as List<ServiceType>;
  final shopData      = results[1] as Map<String, dynamic>;
  final currentPrices = results[2] as List<Map<String, dynamic>>;

  final slugs = ((shopData['serviceTypes'] ?? []) as List<dynamic>)
      .map((e) => e as String)
      .toSet();

  final types = allTypes.where((t) => slugs.contains(t.slug)).toList();

  // serviceTypeId → (min, max, currency)
  final priceMap = <String, (int, int, String)>{};
  for (final p in currentPrices) {
    final id   = (p['serviceTypeId'] ?? p['service_type_id'] ?? '') as String;
    final st   = p['serviceType'] as Map<String, dynamic>? ?? {};
    final stId = id.isNotEmpty ? id : (st['id'] ?? '') as String;
    if (stId.isNotEmpty) {
      priceMap[stId] = (
        ((p['priceMin'] ?? p['price_min'] ?? 0) as num).toInt(),
        ((p['priceMax'] ?? p['price_max'] ?? 0) as num).toInt(),
        (p['currency'] ?? 'UZS') as String,
      );
    }
  }

  return _PricesData(types: types, priceMap: priceMap);
});

class _PricesData {
  final List<ServiceType> types;
  final Map<String, (int, int, String)> priceMap;
  const _PricesData({required this.types, required this.priceMap});
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PricesScreen extends ConsumerStatefulWidget {
  const PricesScreen({super.key});

  @override
  ConsumerState<PricesScreen> createState() => _PricesScreenState();
}

class _PricesScreenState extends ConsumerState<PricesScreen> {
  final Map<String, (TextEditingController, TextEditingController)> _ctrls = {};
  final Map<String, String> _selectedCurrency = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final pair in _ctrls.values) {
      pair.$1.dispose();
      pair.$2.dispose();
    }
    super.dispose();
  }

  void _initControllers(_PricesData data) {
    for (final t in data.types) {
      if (_ctrls.containsKey(t.id)) continue;
      final existing = data.priceMap[t.id];
      _ctrls[t.id] = (
        TextEditingController(
            text: existing != null && existing.$1 > 0 ? existing.$1.toString() : ''),
        TextEditingController(
            text: existing != null && existing.$2 > 0 ? existing.$2.toString() : ''),
      );
      _selectedCurrency[t.id] = existing?.$3 ?? 'UZS';
    }
  }

  Future<void> _save(List<ServiceType> types) async {
    final prices = <Map<String, dynamic>>[];
    for (final t in types) {
      final pair = _ctrls[t.id];
      if (pair == null) continue;
      final min = int.tryParse(pair.$1.text.replaceAll(' ', '')) ?? 0;
      final max = int.tryParse(pair.$2.text.replaceAll(' ', '')) ?? 0;
      if (min > 0 || max > 0) {
        prices.add({
          'serviceTypeId': t.id,
          'priceMin':  min,
          'priceMax':  max > 0 ? max : min,
          'currency':  _selectedCurrency[t.id] ?? 'UZS',
        });
      }
    }

    if (prices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Укажите хотя бы одну цену'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ));
      return;
    }

    setState(() => _saving = true);
    try {
      await ShopService().updatePrices(prices);
      ref.invalidate(_pricesDataProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Цены сохранены ✓',
              style: AppTypography.labelMedium.copyWith(color: Colors.white)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_pricesDataProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded, color: AppColors.text(context)),
                  ),
                  Expanded(
                    child: Text('Цены на услуги',
                        style: AppTypography.displayLarge),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Укажите диапазон и валюту для каждой услуги',
                style: AppTypography.labelSmall.copyWith(color: AppColors.text2(context)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: async.when(
                data: (data) {
                  _initControllers(data);
                  if (data.types.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined, size: 48, color: AppColors.text3(context)),
                          const SizedBox(height: AppSpacing.md),
                          Text('Виды услуг не найдены',
                              style: AppTypography.titleSmall.copyWith(color: AppColors.text2(context))),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Сначала выберите виды услуг в профиле',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.text3(context)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 120),
                    itemCount: data.types.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final t = data.types[i];
                      final pair = _ctrls[t.id]!;
                      final selectedCur = _selectedCurrency[t.id] ?? 'UZS';
                      return _PriceRow(
                        type: t,
                        minCtrl: pair.$1,
                        maxCtrl: pair.$2,
                        selectedCurrency: selectedCur,
                        onCurrencyChanged: (code) =>
                            setState(() => _selectedCurrency[t.id] = code),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Произошла ошибка',
                          style: AppTypography.titleSmall.copyWith(color: AppColors.text2(context))),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => ref.invalidate(_pricesDataProvider),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: async.valueOrNull == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton(
                  onPressed: _saving
                      ? null
                      : () => _save(ref.read(_pricesDataProvider).valueOrNull?.types ?? []),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inverseBg(context),
                    foregroundColor: AppColors.inverseText(context),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.r_md)),
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.inverseText(context)))
                      : Text('Сохранить',
                          style: AppTypography.labelMedium.copyWith(
                              color: AppColors.inverseText(context),
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
    );
  }
}

// ── Price row ─────────────────────────────────────────────────────────────────

IconData _slugIcon(String slug) {
  switch (slug) {
    case 'podkachka':      return Icons.air_rounded;
    case 'balancing':      return Icons.settings_rounded;
    case 'disk_repair':    return Icons.build_rounded;
    case 'perezobuvka':    return Icons.sync_rounded;
    case 'tire_storage':   return Icons.inventory_2_rounded;
    case 'vulkanizatsiya': return Icons.local_fire_department_rounded;
    default:               return Icons.miscellaneous_services_rounded;
  }
}

class _PriceRow extends StatelessWidget {
  final ServiceType type;
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;

  const _PriceRow({
    required this.type,
    required this.minCtrl,
    required this.maxCtrl,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = type.nameRu.isNotEmpty ? type.nameRu : type.nameUz;
    final cur  = _getCur(selectedCurrency);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service name row
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface2(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_slugIcon(type.slug), size: 18, color: AppColors.text2(context)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Min / Max / Currency row
          Row(
            children: [
              Expanded(
                child: _PriceField(
                  controller: minCtrl,
                  label: 'Мин. цена',
                  hint: '0',
                  suffix: cur.symbol,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('–',
                    style: AppTypography.titleSmall
                        .copyWith(color: AppColors.text3(context))),
              ),
              Expanded(
                child: _PriceField(
                  controller: maxCtrl,
                  label: 'Макс. цена',
                  hint: '0',
                  suffix: cur.symbol,
                ),
              ),
              const SizedBox(width: 8),
              // Currency picker
              _CurrencyPicker(
                selected: selectedCurrency,
                onChanged: onCurrencyChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Currency picker ───────────────────────────────────────────────────────────

class _CurrencyPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _CurrencyPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cur = _getCur(selected);
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface2(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_sm),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(cur.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            Text(cur.code,
                style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text(context))),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _currencies.map((c) {
              final isSelected = c.code == selected;
              return ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                title: Text('${c.code}  ${c.symbol}',
                    style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
                trailing: isSelected
                    ? Icon(Icons.check_rounded,
                        color: AppColors.inverseBg(context))
                    : null,
                onTap: () {
                  onChanged(c.code);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Price text field ──────────────────────────────────────────────────────────

class _PriceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;

  const _PriceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.text3(context))),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.titleSmall.copyWith(color: AppColors.text(context)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.titleSmall
                .copyWith(color: AppColors.text3(context)),
            suffix: Text(suffix,
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.text3(context))),
            filled: true,
            fillColor: AppColors.surface2(context),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              borderSide: BorderSide(color: AppColors.hairline(context)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.r_sm),
              borderSide: BorderSide(color: AppColors.text(context), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
