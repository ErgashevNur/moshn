import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/vehicle.dart';
import '../../services/api.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/plate_input.dart';
import '../../widgets/vehicle_photo_picker.dart';
import 'my_vehicles_screen.dart' show vehiclesProvider;
import '../../widgets/primary_button.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle? vehicle;
  const AddVehicleScreen({super.key, this.vehicle});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  bool get _isEditing => widget.vehicle != null;

  late final _plate = TextEditingController(text: widget.vehicle?.plate ?? '');
  late final _make = TextEditingController(text: widget.vehicle?.make ?? '');
  late final _model = TextEditingController(text: widget.vehicle?.model ?? '');
  late final _year = TextEditingController(
      text: widget.vehicle != null && widget.vehicle!.year > 0
          ? widget.vehicle!.year.toString()
          : '');
  late final _color = TextEditingController(text: widget.vehicle?.color ?? '');
  late final _mileage = TextEditingController(
      text: (widget.vehicle?.mileageKm ?? 0) > 0
          ? widget.vehicle!.mileageKm.toString()
          : '');
  late final _nextService = TextEditingController(
      text: (widget.vehicle?.nextServiceKm ?? 0) > 0
          ? widget.vehicle!.nextServiceKm.toString()
          : '');
  bool _saving = false;

  /// Rasm alohida endpoint orqali yuklanadi (formani saqlashdan mustaqil),
  /// shuning uchun joriy holat shu yerda saqlanadi.
  late String _photoUrl = widget.vehicle?.photoUrl ?? '';
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _plate.dispose();
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    _mileage.dispose();
    _nextService.dispose();
    super.dispose();
  }

  Future<void> _changePhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      final updated =
          await pickAndUploadVehiclePhoto(context, widget.vehicle!.id);
      if (updated != null && mounted) {
        setState(() => _photoUrl = updated.photoUrl ?? '');
        // Bosh ekrandagi karta ham yangilansin
        ref.invalidate(vehiclesProvider);
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (_plate.text.trim().isEmpty) {
      _showError('vehicle.plate_required'.tr());
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await VehicleService().updateVehicle(
          widget.vehicle!.id,
          plate: _plate.text.trim().toUpperCase(),
          make: _make.text.trim(),
          model: _model.text.trim(),
          year: int.tryParse(_year.text) ?? 0,
          color: _color.text.trim(),
          mileageKm: int.tryParse(_mileage.text.replaceAll(' ', '')) ?? 0,
          nextServiceKm: int.tryParse(_nextService.text.replaceAll(' ', '')) ?? 0,
        );
      } else {
        await VehicleService().createVehicle(
          plate: _plate.text.trim().toUpperCase(),
          make: _make.text.trim(),
          model: _model.text.trim(),
          year: int.tryParse(_year.text) ?? 0,
          color: _color.text.trim(),
          mileageKm: int.tryParse(_mileage.text.replaceAll(' ', '')) ?? 0,
          nextServiceKm: int.tryParse(_nextService.text.replaceAll(' ', '')) ?? 0,
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) _showError(_errMsg(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _errMsg(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Ошибка подключения к серверу. Проверьте подключение к Wi-Fi.';
      }
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      }
      if (e.response?.statusCode == 409) {
        return 'Этот номер уже зарегистрирован';
      }
      if (e.response?.statusCode == 400) return 'Введите данные правильно';
    }
    return e.toString();
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Text('common.error'.tr()),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: AppColors.text(context), size: 17),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                        _isEditing ? 'vehicle.edit'.tr() : 'vehicle.add'.tr(),
                        style: AppTypography.titleLarge),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Rasm faqat mavjud mashinaga biriktiriladi (yuklash uchun
                  // id kerak), shuning uchun yangi qo'shishda ko'rsatilmaydi —
                  // saqlagandan keyin shu ekranga qaytib qo'yiladi.
                  if (_isEditing) ...[
                    _label('vehicle.photo'.tr()),
                    _PhotoField(
                      photoUrl: _photoUrl,
                      uploading: _uploadingPhoto,
                      onTap: _changePhoto,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  _label('vehicle.plate'.tr()),
                  PlateInput(controller: _plate),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('vehicle.make'.tr()),
                            AppTextField(
                              controller: _make,
                              placeholder: 'vehicle.make_hint'.tr(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('vehicle.model'.tr()),
                            AppTextField(
                              controller: _model,
                              placeholder: 'vehicle.model_hint'.tr(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('vehicle.year'.tr()),
                            AppTextField(
                              controller: _year,
                              placeholder: '2020',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('vehicle.color'.tr()),
                            AppTextField(
                              controller: _color,
                              placeholder: 'vehicle.color_hint'.tr(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Probeg va keyingi TO — bosh ekrandagi mashina kartasida
                  // ko'rsatiladi. Ixtiyoriy: bo'sh qoldirilsa karta faqat
                  // model/raqamni chiqaradi.
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('vehicle.mileage'.tr()),
                            AppTextField(
                              controller: _mileage,
                              placeholder: '84200',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('vehicle.next_service'.tr()),
                            AppTextField(
                              controller: _nextService,
                              placeholder: '86000',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  PrimaryButton(
                    label: 'common.save'.tr(),
                    onPressed: _save,
                    loading: _saving,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(
          text,
          style: AppTypography.labelSmall
              .copyWith(color: AppColors.text3(context)),
        ),
      );
}

// ── Rasm maydoni ─────────────────────────────────────────────────────────────
// Joriy rasm (bo'lsa) + almashtirish tugmasi. Bosh ekrandagi karta bilan bir
// xil nisbatda ko'rsatiladi, shuning uchun natija oldindan ko'rinadi.

class _PhotoField extends StatelessWidget {
  final String photoUrl;
  final bool uploading;
  final VoidCallback onTap;

  const _PhotoField({
    required this.photoUrl,
    required this.uploading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final url = ApiClient.mediaUrl(photoUrl);
    final hasPhoto = url.isNotEmpty;

    return GestureDetector(
      onTap: uploading ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: SizedBox(
          height: 150,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasPhoto)
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _emptyArea(context),
                  errorWidget: (_, _, _) => _emptyArea(context),
                )
              else
                _emptyArea(context),

              if (uploading)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                )
              else
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_camera_rounded,
                            size: 14, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          (hasPhoto ? 'vehicle.photo_change' : 'vehicle.photo_add')
                              .tr(),
                          style: AppTypography.labelSmall
                              .copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyArea(BuildContext context) => ColoredBox(
        color: AppColors.surface2(context),
        child: Center(
          child: Icon(Icons.directions_car_rounded,
              size: 40, color: AppColors.text3(context)),
        ),
      );
}
