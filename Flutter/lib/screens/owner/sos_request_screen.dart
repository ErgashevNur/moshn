import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/vehicle.dart';
import '../../services/location_service.dart';
import '../../services/vehicle_service.dart';
import '../../store/sos_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_button.dart';
import '../../widgets/m_service_tile.dart';
import 'home_screen.dart' show serviceTypesProvider;

final _sosVehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  return VehicleService().getVehicles();
});

class SosRequestScreen extends ConsumerStatefulWidget {
  const SosRequestScreen({super.key});

  @override
  ConsumerState<SosRequestScreen> createState() => _SosRequestScreenState();
}

class _SosRequestScreenState extends ConsumerState<SosRequestScreen> {
  String? _vehicleId;
  String? _serviceTypeId;
  bool _locating = false;

  Future<void> _submit() async {
    if (_vehicleId == null) {
      _toast('sos.pick_vehicle'.tr());
      return;
    }
    if (_serviceTypeId == null) {
      _toast('sos.pick_service'.tr());
      return;
    }

    setState(() => _locating = true);
    final locationResult = await LocationService().getCurrentPosition();
    if (!mounted) return;
    setState(() => _locating = false);

    if (!locationResult.isOk) {
      final key = locationResult.failure == LocationFailure.serviceDisabled
          ? 'home.location_service_disabled'
          : 'home.location_permission_denied';
      _toast(key.tr());
      return;
    }

    final ok = await ref.read(sosProvider.notifier).create(
          vehicleId: _vehicleId!,
          serviceTypeId: _serviceTypeId!,
          lat: locationResult.position!.latitude,
          lng: locationResult.position!.longitude,
        );
    if (!mounted) return;
    if (ok) {
      final id = ref.read(sosProvider).request!.id;
      context.pushReplacement('/owner/sos/$id');
    } else {
      _toast(ref.read(sosProvider).error ?? 'sos.create_error'.tr());
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTypography.body.copyWith(color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.r_xs)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(_sosVehiclesProvider);
    final typesAsync = ref.watch(serviceTypesProvider);
    final creating = ref.watch(sosProvider).loading || _locating;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _appBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.dangerDim,
                        borderRadius: BorderRadius.circular(AppSpacing.r_md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: AppColors.danger, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'sos.intro'.tr(),
                              style: AppTypography.body.copyWith(color: AppColors.text(context)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text('sos.your_car'.tr(),
                        style: AppTypography.eyebrow.copyWith(color: AppColors.text3(context))),
                    const SizedBox(height: AppSpacing.sm),
                    vehiclesAsync.when(
                      data: (vehicles) => vehicles.isEmpty
                          ? _hintBox(context, 'sos.no_vehicles'.tr())
                          : Column(
                              children: vehicles
                                  .map((v) => Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                        child: _VehicleTile(
                                          vehicle: v,
                                          selected: _vehicleId == v.id,
                                          onTap: () => setState(() => _vehicleId = v.id),
                                        ),
                                      ))
                                  .toList(),
                            ),
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, _) => _hintBox(context, 'common.error'.tr()),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Text('sos.what_happened'.tr(),
                        style: AppTypography.eyebrow.copyWith(color: AppColors.text3(context))),
                    const SizedBox(height: AppSpacing.sm),
                    typesAsync.when(
                      data: (types) => GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: types.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, i) {
                          final t = types[i];
                          return MServiceTile(
                            label: t.nameFor(context.locale.languageCode),
                            iconName: t.icon,
                            active: _serviceTypeId == t.id,
                            onTap: () => setState(() => _serviceTypeId = t.id),
                          );
                        },
                      ),
                      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, _) => _hintBox(context, 'common.error'.tr()),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: MButton(
                label: creating ? 'sos.calling'.tr() : 'sos.call_button'.tr(),
                variant: MButtonVariant.danger,
                loading: creating,
                onTap: creating ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hintBox(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
      ),
      child: Text(text, style: AppTypography.body.copyWith(color: AppColors.text3(context))),
    );
  }

  Widget _appBar(BuildContext context) {
    return Padding(
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
          Text('SOS', style: AppTypography.appbarTitle.copyWith(color: AppColors.danger)),
        ],
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  final Vehicle vehicle;
  final bool selected;
  final VoidCallback onTap;
  const _VehicleTile({required this.vehicle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface2(context) : AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(
            color: selected ? AppColors.danger : AppColors.hairline(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface3(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_xs),
              ),
              child: Icon(Icons.directions_car_rounded, size: 20, color: AppColors.text2(context)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                vehicle.displayName,
                style: AppTypography.labelMedium.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w600),
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.danger, size: 20),
          ],
        ),
      ),
    );
  }
}
