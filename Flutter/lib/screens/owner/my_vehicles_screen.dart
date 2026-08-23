import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/vehicle.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'add_vehicle_scan_screen.dart';

/// Bosh ekrandagi mashina karuseli ham shu providerdan foydalanadi (home_screen.dart).
final vehiclesProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) {
  return VehicleService().getVehicles();
});

/// «Авто» bo'limi — maketning o'zi, boshqa hech nima.
///
/// Repo egasining qarori: bo'limda faqat "Добавьте автомобиль" ekrani
/// tursin. Mashinalar ro'yxati, «Штрафы» va «Шиномонтаж» kataklari olib
/// tashlandi (maketda ular yo'q edi).
///
/// Mavjud mashinaga kirish yo'qolmadi — u bosh ekrandagi mashina
/// kartasidan ochiladi (`home_screen.dart` → `/owner/vehicles/edit`).
class MyVehiclesScreen extends ConsumerWidget {
  const MyVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.huge + MediaQuery.of(context).padding.bottom,
          ),
          child: const AddVehicleScanScreen(embedded: true),
        ),
      ),
    );
  }
}
