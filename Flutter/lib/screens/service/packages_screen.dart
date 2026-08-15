import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/service_package.dart';
import '../../models/service_type.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Servis egasining paketlari + shu servis ko'rsatadigan xizmat turlari.
/// Ikkisi birga kerak: paket qo'shishda faqat o'z xizmatlari taklif qilinadi.
final _packagesDataProvider =
    FutureProvider.autoDispose<_PackagesData>((ref) async {
  final svc = ShopService();
  final results = await Future.wait([
    svc.getMyPackages(),
    svc.getServiceTypes(),
    svc.getMyShop(),
  ]);
  final packages = results[0] as List<ServicePackage>;
  final allTypes = results[1] as List<ServiceType>;
  final shop = results[2] as Map<String, dynamic>;

  final slugs = ((shop['serviceTypes'] ?? shop['service_types'] ?? []) as List<dynamic>)
      .map((e) => e as String)
      .toSet();
  final myTypes = allTypes.where((t) => slugs.contains(t.slug)).toList();

  return _PackagesData(packages: packages, types: myTypes);
});

class _PackagesData {
  final List<ServicePackage> packages;
  final List<ServiceType> types;
  const _PackagesData({required this.packages, required this.types});
}

class PackagesScreen extends ConsumerWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_packagesDataProvider);

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
                    icon: Icon(Icons.arrow_back_rounded,
                        color: AppColors.text(context)),
                  ),
                  Expanded(
                    child: Text('packages.title'.tr(),
                        style: AppTypography.displayLarge),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'packages.subtitle'.tr(),
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.text2(context)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: async.when(
                data: (data) => data.types.isEmpty
                    ? _empty(context, 'packages.no_service_types'.tr())
                    : _list(context, ref, data),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(_packagesDataProvider),
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

  Widget _list(BuildContext context, WidgetRef ref, _PackagesData data) {
    final locale = context.locale.languageCode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
      children: [
        for (final t in data.types) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.md, bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    t.nameFor(locale),
                    style: AppTypography.soraSize(14, weight: FontWeight.w700)
                        .copyWith(color: AppColors.text(context)),
                  ),
                ),
                GestureDetector(
                  onTap: () => _openForm(context, ref, serviceType: t),
                  child: Row(
                    children: [
                      Icon(Icons.add_rounded, size: 16, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text('packages.add'.tr(),
                          style: AppTypography.soraSize(12,
                                  weight: FontWeight.w600)
                              .copyWith(color: AppColors.gold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ...() {
            final items = data.packages
                .where((p) => p.serviceTypeId == t.id)
                .toList();
            if (items.isEmpty) {
              return [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface(context),
                    borderRadius: BorderRadius.circular(AppSpacing.r_md),
                    border: Border.all(color: AppColors.hairline(context)),
                  ),
                  child: Text('packages.empty_hint'.tr(),
                      style: AppTypography.body
                          .copyWith(color: AppColors.text3(context))),
                ),
              ];
            }
            return items
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _PackageTile(
                        package: p,
                        onTap: () =>
                            _openForm(context, ref, serviceType: t, package: p),
                      ),
                    ))
                .toList();
          }(),
        ],
      ],
    );
  }

  Widget _empty(BuildContext context, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.text3(context))),
        ),
      );

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    required ServiceType serviceType,
    ServicePackage? package,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageForm(serviceType: serviceType, package: package),
    );
    if (saved == true) ref.invalidate(_packagesDataProvider);
  }
}

// ── Paket qatori ─────────────────────────────────────────────────────────────

class _PackageTile extends StatelessWidget {
  final ServicePackage package;
  final VoidCallback onTap;

  const _PackageTile({required this.package, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = package;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Row(
          children: [
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
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.schedule_rounded,
                          size: 11, color: AppColors.text3(context)),
                      const SizedBox(width: 2),
                      Text(p.durationLabel,
                          style: AppTypography.body.copyWith(
                              color: AppColors.text3(context), fontSize: 11)),
                    ],
                  ),
                  if (p.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(p.description,
                        style: AppTypography.body.copyWith(
                            color: AppColors.text3(context), fontSize: 11.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _fmt(p.price),
              style: AppTypography.soraSize(14, weight: FontWeight.w700)
                  .copyWith(color: AppColors.text(context)),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.text3(context)),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) =>
      n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
}

// ── Qo'shish / tahrirlash ────────────────────────────────────────────────────

class _PackageForm extends ConsumerStatefulWidget {
  final ServiceType serviceType;
  final ServicePackage? package;

  const _PackageForm({required this.serviceType, this.package});

  @override
  ConsumerState<_PackageForm> createState() => _PackageFormState();
}

class _PackageFormState extends ConsumerState<_PackageForm> {
  late final _name = TextEditingController(text: widget.package?.name ?? '');
  late final _desc =
      TextEditingController(text: widget.package?.description ?? '');
  late final _duration = TextEditingController(
      text: (widget.package?.durationMin ?? 60).toString());
  late final _price = TextEditingController(
      text: (widget.package?.price ?? 0) > 0
          ? widget.package!.price.toString()
          : '');

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.package != null;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _duration.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'packages.name_required'.tr());
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final svc = ShopService();
      final dur = int.tryParse(_duration.text.replaceAll(' ', '')) ?? 60;
      final price = int.tryParse(_price.text.replaceAll(' ', '')) ?? 0;

      if (_isEdit) {
        await svc.updatePackage(
          widget.package!.id,
          name: name,
          description: _desc.text.trim(),
          durationMin: dur,
          price: price,
        );
      } else {
        await svc.createPackage(
          serviceTypeId: widget.serviceType.id,
          name: name,
          description: _desc.text.trim(),
          durationMin: dur,
          price: price,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() {
        _error = 'packages.save_error'.tr();
        _saving = false;
      });
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        title: Text('packages.delete_title'.tr(),
            style: AppTypography.titleSmall),
        content: Text('packages.delete_hint'.tr(),
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.text2(ctx))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.delete'.tr(),
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _saving = true);
    try {
      await ShopService().deletePackage(widget.package!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() {
        _error = 'packages.save_error'.tr();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit
                    ? 'packages.edit_title'.tr()
                    : 'packages.new_title'.tr(),
                style: AppTypography.titleSmall
                    .copyWith(color: AppColors.text(context)),
              ),
              const SizedBox(height: 2),
              Text(
                widget.serviceType.nameFor(context.locale.languageCode),
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.text3(context)),
              ),
              const SizedBox(height: AppSpacing.md),
              _field(_name, 'packages.name_hint'.tr()),
              const SizedBox(height: AppSpacing.sm),
              _field(_desc, 'packages.desc_hint'.tr(), maxLines: 2),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _field(_duration, 'packages.duration_hint'.tr(),
                        numeric: true),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _field(_price, 'packages.price_hint'.tr(),
                        numeric: true),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.inverseBg(context),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r_md)),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.inverseText(context)))
                    : Text('common.save'.tr(),
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.inverseText(context),
                            fontWeight: FontWeight.w600)),
              ),
              if (_isEdit)
                TextButton(
                  onPressed: _saving ? null : _delete,
                  child: Text('packages.delete'.tr(),
                      style: TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: AppTypography.labelMedium.copyWith(color: AppColors.text(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTypography.labelMedium.copyWith(color: AppColors.text3(context)),
        filled: true,
        fillColor: AppColors.surface2(context),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r_sm),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
