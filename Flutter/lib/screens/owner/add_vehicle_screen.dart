import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _vin = TextEditingController();
  final _plate = TextEditingController();
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _color = TextEditingController();

  bool _scanning = false;
  bool _saving = false;

  @override
  void dispose() {
    _vin.dispose();
    _plate.dispose();
    _make.dispose();
    _model.dispose();
    _year.dispose();
    _color.dispose();
    super.dispose();
  }

  Future<void> _scanPassport() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file == null) return;
    setState(() => _scanning = true);
    try {
      final parsed = await VehicleService().scanPassport(file.path);
      _vin.text = (parsed['vin'] ?? '').toString();
      _plate.text = (parsed['plate'] ?? '').toString();
      _make.text = (parsed['make'] ?? '').toString();
      _model.text = (parsed['model'] ?? '').toString();
      _year.text = (parsed['year'] ?? '').toString();
      _color.text = (parsed['color'] ?? '').toString();
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _save() async {
    if (_vin.text.isEmpty || _plate.text.isEmpty || _make.text.isEmpty) {
      _showError('common.error'.tr());
      return;
    }
    setState(() => _saving = true);
    try {
      await VehicleService().create({
        'vin': _vin.text.trim(),
        'current_plate': _plate.text.trim(),
        'make': _make.text.trim(),
        'model': _model.text.trim(),
        'year': int.tryParse(_year.text) ?? 0,
        'color': _color.text.trim(),
      });
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('common.error'.tr()),
        content: Text(msg),
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
        middle: Text('owner.add_car'.tr()),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCard(
                onTap: _scanning ? null : _scanPassport,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryOf(context).withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: _scanning
                          ? const CupertinoActivityIndicator()
                          : Icon(
                              CupertinoIcons.camera,
                              color: AppColors.primaryOf(context),
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('owner.scan_passport'.tr(),
                              style: AppTypography.headline),
                          const SizedBox(height: 2),
                          Text(
                            'OCR',
                            style: AppTypography.footnote.copyWith(
                              color: AppColors.labelTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _label('owner.vin'.tr()),
              AppTextField(
                controller: _vin,
                placeholder: 'XTA21099011234567',
                icon: CupertinoIcons.barcode,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppSpacing.md),
              _label('owner.plate'.tr()),
              AppTextField(
                controller: _plate,
                placeholder: '01 A 123 BC',
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
                        _label('owner.make_model'.tr()),
                        AppTextField(controller: _make, placeholder: 'Chevrolet'),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label(''),
                        AppTextField(controller: _model, placeholder: 'Cobalt'),
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
                        _label('owner.year'.tr()),
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
                        _label('owner.color'.tr()),
                        AppTextField(controller: _color, placeholder: '—'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
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
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(
          text,
          style: AppTypography.footnote
              .copyWith(color: AppColors.labelTertiary),
        ),
      );
}
