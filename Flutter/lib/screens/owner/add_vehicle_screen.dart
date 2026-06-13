import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _plate = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _plate.dispose();
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_plate.text.trim().isEmpty) {
      _showError('vehicle.plate_required'.tr());
      return;
    }
    setState(() => _saving = true);
    try {
      await VehicleService().createVehicle(
        plate: _plate.text.trim().toUpperCase(),
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text) ?? 0,
        color: _color.text.trim(),
      );
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
        return 'Server bilan ulanishda xatolik. WiFi ulanishingizni tekshiring.';
      }
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      }
      if (e.response?.statusCode == 409) {
        return 'Bu davlat raqami allaqachon ro\'yxatda';
      }
      if (e.response?.statusCode == 400) return 'Ma\'lumotlarni to\'g\'ri kiriting';
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
                    child: Text('vehicle.add'.tr(),
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
                  _label('vehicle.plate'.tr()),
                  AppTextField(
                    controller: _plate,
                    placeholder: 'vehicle.plate_hint'.tr(),
                    icon: CupertinoIcons.creditcard,
                    textCapitalization: TextCapitalization.characters,
                  ),
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
