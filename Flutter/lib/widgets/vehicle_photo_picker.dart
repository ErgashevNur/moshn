import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/vehicle.dart';
import '../services/vehicle_service.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Kamera/galereya tanlash oynasini ochadi, rasmni serverga yuklaydi va
/// yangilangan `Vehicle`ni qaytaradi. Foydalanuvchi bekor qilsa yoki xato
/// bo'lsa — `null`.
///
/// Bosh ekrandagi karta ham, mashinani tahrirlash ekrani ham shu yerdan
/// foydalanadi (mantiq ikki joyda takrorlanmasin).
Future<Vehicle?> pickAndUploadVehiclePhoto(
  BuildContext context,
  String vehicleId,
) async {
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
            leading: Icon(Icons.photo_camera_rounded, color: AppColors.text(ctx)),
            title: Text('vehicle.photo_camera'.tr(),
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.text(ctx))),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: Icon(Icons.photo_library_rounded, color: AppColors.text(ctx)),
            title: Text('vehicle.photo_gallery'.tr(),
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.text(ctx))),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;

  try {
    // Kartada baribir kesib ko'rsatiladi — juda katta faylni yubormaymiz
    // (server chegarasi 8 MB).
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return await VehicleService().uploadPhoto(vehicleId, picked.path);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('vehicle.photo_error'.tr()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    }
    return null;
  }
}
