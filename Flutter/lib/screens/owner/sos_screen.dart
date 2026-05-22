import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/sos_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

/// Toshkent markazi — GPS aniqlanmaguncha standart ko'rinish.
const _fallbackCenter = LatLng(41.311081, 69.279737);

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final _phoneController = TextEditingController();
  final _mapController = MapController();

  LatLng _selected = _fallbackCenter;
  String? _address;
  bool _locating = false;
  bool _submitting = false;
  Timer? _geocodeDebounce;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _phoneController.text = user?.phone ?? '';
    // Ekran ochilishi bilan joriy joylashuvni aniqlashga harakat qilamiz.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _geocodeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('sos.location_disabled'.tr());
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('sos.location_denied'.tr());
        return;
      }

      // Aniq joylashuv: yuqori aniqlik + vaqt chegarasi. Olinmasa — oxirgi
      // ma'lum joylashuvga qaytamiz (fallback markazga emas).
      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            timeLimit: Duration(seconds: 12),
          ),
        );
      } catch (_) {
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) {
        _showMessage('sos.location_error'.tr());
        return;
      }
      final latlng = LatLng(pos.latitude, pos.longitude);
      _selected = latlng;
      _mapController.move(latlng, 16);
      await _reverseGeocode(latlng);
    } catch (_) {
      _showMessage('sos.location_error'.tr());
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (placemarks.isEmpty) return;
      final p = placemarks.first;
      final parts = [
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
      ].where((e) => e != null && e.trim().isNotEmpty).toList();
      if (mounted) setState(() => _address = parts.join(', '));
    } catch (_) {
      // Manzil nomi ixtiyoriy — koordinatalar baribir yuboriladi.
    }
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    _selected = camera.center;
    if (!hasGesture) return;
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 700), () {
      _reverseGeocode(_selected);
    });
  }

  Future<void> _confirmAndSend() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showMessage('sos.phone_required'.tr());
      return;
    }

    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('sos.confirm_title'.tr()),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'sos.phone_label'.tr()}: $phone'),
              const SizedBox(height: 4),
              Text(
                '${'sos.location_label'.tr()}: ${_address ?? _coordsText()}',
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('sos.send'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _send(phone);
  }

  Future<void> _send(String phone) async {
    setState(() => _submitting = true);
    try {
      await SosService().send(
        phone: phone,
        latitude: _selected.latitude,
        longitude: _selected.longitude,
        address: _address,
      );
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('sos.sent_title'.tr()),
          content: Text('sos.sent_body'.tr()),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.ok'.tr()),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      _showMessage('sos.send_error'.tr());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _coordsText() =>
      '${_selected.latitude.toStringAsFixed(5)}, ${_selected.longitude.toStringAsFixed(5)}';

  void _showMessage(String message) {
    if (!mounted) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('sos.title'.tr()),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(
              'sos.subtitle'.tr(),
              style: AppTypography.body.copyWith(
                color: AppColors.labelSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 1-qadam — aloqa raqamini tasdiqlash.
            _Label(text: 'sos.phone_label'.tr()),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              controller: _phoneController,
              placeholder: '+998 90 123 45 67',
              icon: CupertinoIcons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 6),
            Text(
              'sos.phone_hint'.tr(),
              style: AppTypography.footnote.copyWith(
                color: AppColors.labelTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // 2-qadam — joylashuvni aniqlash / xaritadan tanlash.
            _Label(text: 'sos.location_label'.tr()),
            const SizedBox(height: AppSpacing.sm),
            _MapPicker(
              controller: _mapController,
              initialCenter: _selected,
              onPositionChanged: _onMapMoved,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _address ?? _coordsText(),
                    style: AppTypography.footnote.copyWith(
                      color: AppColors.labelSecondary,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  onPressed: _locating ? null : _useCurrentLocation,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_locating)
                        const CupertinoActivityIndicator()
                      else
                        Icon(
                          CupertinoIcons.location_fill,
                          size: 18,
                          color: AppColors.primaryOf(context),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        'sos.my_location'.tr(),
                        style: AppTypography.subhead.copyWith(
                          color: AppColors.primaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              'sos.map_hint'.tr(),
              style: AppTypography.caption1.copyWith(
                color: AppColors.labelTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            PrimaryButton(
              label: 'sos.send'.tr(),
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              destructive: true,
              loading: _submitting,
              onPressed: _confirmAndSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.headline);
  }
}

/// Markazda qotirilgan pin bilan xarita — xaritani surib joy tanlanadi,
/// tanlangan nuqta har doim markaz.
class _MapPicker extends StatelessWidget {
  final MapController controller;
  final LatLng initialCenter;
  final void Function(MapCamera, bool) onPositionChanged;

  const _MapPicker({
    required this.controller,
    required this.initialCenter,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 15,
                onPositionChanged: onPositionChanged,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'uz.moshn.moshn',
                ),
              ],
            ),
            // Markaziy pin (xarita ostida — gesturega xalaqit bermaydi).
            const IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 28),
                child: Icon(
                  CupertinoIcons.placemark_fill,
                  size: 36,
                  color: AppColors.destructive,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
