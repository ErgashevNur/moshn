import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/m_plate.dart';
import '../../widgets/primary_button.dart';
import 'my_vehicles_screen.dart' show vehiclesProvider;
import 'owner_root.dart';

/// Mashina qo'shishning birinchi qadami (maket bo'yicha): texpasport
/// surati + asosiy uchta maydon.
///
/// ⚠️ **Tanish (OCR) hali yo'q** — repo egasining qarori: avval ekran,
/// tanish keyinroq. Shuning uchun bu yerda maketdagi "мы распознаем
/// госномер, марку и год" va'dasi YOZILMAGAN va natija qatorida
/// "Распознано с техпаспорта" deyilmaydi — hech narsa tanilmagan holda
/// buni yozish foydalanuvchini aldash bo'lardi. OCR ulangach almashadigan
/// joylar shu faylda `TODO(ocr)` bilan belgilangan.
///
/// Texpasport surati **serverga yuborilmaydi** — faqat ekranda, foydalanuvchi
/// qog'ozni qo'lida ushlab turmasdan ko'chirib yozishi uchun turadi.
class AddVehicleScanScreen extends ConsumerStatefulWidget {
  /// `true` — ekran «Авто» bo'limi ichida, bo'sh holat sifatida chiziladi:
  /// o'z Scaffold'i, orqaga tugmasi va pastki navigatsiyasi bo'lmaydi
  /// (bo'limda ular allaqachon bor), saqlagandan keyin ham hech qayerga
  /// qaytmaydi — ro'yxat shu yerning o'zida yangilanadi.
  final bool embedded;

  const AddVehicleScanScreen({super.key, this.embedded = false});

  @override
  ConsumerState<AddVehicleScanScreen> createState() =>
      _AddVehicleScanScreenState();
}

class _AddVehicleScanScreenState extends ConsumerState<AddVehicleScanScreen> {
  final _plate = TextEditingController();
  final _makeModel = TextEditingController();
  final _year = TextEditingController();

  File? _passportShot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_plate, _makeModel, _year]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _plate.dispose();
    _makeModel.dispose();
    _year.dispose();
    super.dispose();
  }

  bool get _ready => _plate.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Bo'lim ichida ota-vidjet o'z scroll'iga o'raydi — bu yerda
    // SingleChildScrollView qo'yilsa ichma-ich scroll bo'lib qolardi.
    if (widget.embedded) return _column(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      bottomNavigationBar: OwnerBottomBar(
        index: 2,
        showSosSlot: false,
        onTap: (i) => context.go('/owner', extra: i),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.text(context),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _content(context)),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xl,
    ),
    child: _column(context),
  );

  Widget _column(BuildContext context) {
    return Column(
      children: [
        _hero(context),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'vehicle.scan_title'.tr(),
          textAlign: TextAlign.center,
          style: AppTypography.soraSize(
            25,
            weight: FontWeight.w700,
          ).copyWith(color: AppColors.text(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'vehicle.scan_subtitle'.tr(),
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: AppColors.text3(context),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _card(context),
        const SizedBox(height: AppSpacing.xl),
        PrimaryButton(
          brand: true,
          radius: AppSpacing.r_lg,
          loading: _saving,
          label: 'vehicle.scan_add'.tr(),
          onPressed: _ready ? _save : null,
        ),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: () => context.push('/owner/vehicles/manual'),
          child: Text(
            'vehicle.scan_manual'.tr(),
            style: AppTypography.labelMedium.copyWith(color: AppColors.gold),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'vehicle.scan_privacy'.tr(),
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: AppColors.text3(context),
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context) => Container(
    width: 68,
    height: 68,
    decoration: BoxDecoration(
      color: AppColors.goldDim,
      borderRadius: BorderRadius.circular(AppSpacing.r_lg),
    ),
    child: const Icon(
      Icons.directions_car_outlined,
      size: 32,
      color: AppColors.gold,
    ),
  );

  Widget _card(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface(context),
      borderRadius: BorderRadius.circular(AppSpacing.r_xl),
      border: Border.all(color: AppColors.hairline(context)),
    ),
    child: Column(
      // Surat maydoni va natija bloki karta kengligini to'liq egallasin.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _shotArea(context),
        const SizedBox(height: AppSpacing.md),
        _resultBlock(context),
      ],
    ),
  );

  /// Texpasport suratini olish joyi — maketdagi burchakli ramka.
  Widget _shotArea(BuildContext context) {
    return GestureDetector(
      onTap: _takeShot,
      child: SizedBox(
        height: 150,
        child: CustomPaint(
          painter: _CornersPainter(AppColors.gold),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface2(context),
              borderRadius: BorderRadius.circular(AppSpacing.r_md),
            ),
            clipBehavior: Clip.antiAlias,
            child: _passportShot == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 30,
                        color: AppColors.text3(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'vehicle.scan_hint'.tr(),
                        style: AppTypography.body.copyWith(
                          color: AppColors.text3(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(_passportShot!, fit: BoxFit.cover),
                      Positioned(
                        right: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.r_sm,
                            ),
                          ),
                          child: Text(
                            'vehicle.scan_retake'.tr(),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Maketdagi yashil natija qatori. Farqi: qiymatlar tahrirlanadi va
  /// "Распознано" deyilmaydi — OCR yo'q.
  /// TODO(ocr): tanish ulanganda bu blok read-only bo'lib,
  /// izohi `vehicle.scan_recognized` ga o'zgaradi.
  Widget _resultBlock(BuildContext context) {
    final ok = _ready;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: ok ? AppColors.successDim : AppColors.surface2(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ok
                      ? AppColors.success
                      : AppColors.text3(context).withValues(alpha: 0.25),
                ),
                child: Icon(
                  ok ? Icons.check_rounded : Icons.edit_outlined,
                  size: 15,
                  color: ok ? Colors.white : AppColors.text3(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  ok ? 'vehicle.scan_ready'.tr() : 'vehicle.scan_fill'.tr(),
                  style: AppTypography.body.copyWith(
                    color: ok ? AppColors.success : AppColors.text3(context),
                    fontSize: 12,
                  ),
                ),
              ),
              if (_plate.text.trim().isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                // Kenglik cheklanmasa uzun raqam butun qatorni egallab,
                // holat matnini nolga siqib qatorni toshirib yuboradi.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: MPlate(plate: _plate.text.trim().toUpperCase()),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _plate,
            placeholder: 'vehicle.plate_hint'.tr(),
            textCapitalization: TextCapitalization.characters,
            // O'zbekiston raqami 8 belgi ("01A123BB"); zaxira bilan 10.
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: AppTextField(
                  controller: _makeModel,
                  placeholder: 'vehicle.make_model_hint'.tr(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppTextField(
                  controller: _year,
                  placeholder: 'vehicle.year'.tr(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(4),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _takeShot() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(
                Icons.photo_camera_rounded,
                color: AppColors.text(ctx),
              ),
              title: Text(
                'vehicle.photo_camera'.tr(),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.text(ctx),
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: AppColors.text(ctx),
              ),
              title: Text(
                'vehicle.photo_gallery'.tr(),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.text(ctx),
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _passportShot = File(picked.path));
  }

  /// "Марка и модель" bitta maydonda kiritiladi (maketdagidek), bazada esa
  /// ikkita ustun — birinchi so'z marka, qolgani model.
  (String, String) _splitMakeModel() {
    final raw = _makeModel.text.trim();
    if (raw.isEmpty) return ('', '');
    final i = raw.indexOf(' ');
    if (i < 0) return (raw, '');
    return (raw.substring(0, i), raw.substring(i + 1).trim());
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final (make, model) = _splitMakeModel();
      await VehicleService().createVehicle(
        plate: _plate.text.trim().toUpperCase(),
        make: make,
        model: model,
        year: int.tryParse(_year.text.trim()) ?? 0,
        color: '',
      );
      if (!mounted) return;
      ref.invalidate(vehiclesProvider);
      // Bo'lim ichida chizilganda qaytadigan joy yo'q — ro'yxat
      // yangilanishi bilan ekran o'zi mashinalar ko'rinishiga almashadi.
      if (!widget.embedded) context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Maketdagi to'rtta burchak — skaner ramkasi hissi.
class _CornersPainter extends CustomPainter {
  final Color color;
  const _CornersPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const len = 18.0;
    const pad = -4.0; // ramka kartaning chetidan biroz tashqarida
    final r = Rect.fromLTWH(
      pad,
      pad,
      size.width - pad * 2,
      size.height - pad * 2,
    );

    // Har burchakda "L" shakli
    for (final (corner, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawLine(corner, corner.translate(len * dx, 0), p);
      canvas.drawLine(corner, corner.translate(0, len * dy), p);
    }
  }

  @override
  bool shouldRepaint(_CornersPainter old) => old.color != color;
}
