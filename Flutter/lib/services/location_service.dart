import 'package:geolocator/geolocator.dart';

enum LocationFailure { serviceDisabled, permissionDenied }

class LocationResult {
  final Position? position;
  final LocationFailure? failure;
  const LocationResult._(this.position, this.failure);
  const LocationResult.ok(Position position) : this._(position, null);
  const LocationResult.fail(LocationFailure failure) : this._(null, failure);
  bool get isOk => position != null;
}

/// map_screen.dart'dagi joylashuv-so'rash bloki bilan bir xil — shu yerga
/// chiqarildi, chunki endi SOS ham xuddi shu tekshiruvni qaytaradi.
class LocationService {
  Future<LocationResult> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationResult.fail(LocationFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return const LocationResult.fail(LocationFailure.permissionDenied);
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LocationResult.ok(pos);
  }
}
