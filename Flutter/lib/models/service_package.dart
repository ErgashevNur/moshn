/// Servisning xizmat paketi ("Bazoviy / Standart / Premium").
/// Nomi, tarkibi, muddati va narxi — har bir servis o'zi belgilaydi.
class ServicePackage {
  final String id;
  final String shopId;
  final String serviceTypeId;
  final String name;
  final String description;
  final int durationMin;
  final int price;
  final String currency;

  ServicePackage({
    required this.id,
    required this.shopId,
    required this.serviceTypeId,
    required this.name,
    required this.description,
    required this.durationMin,
    required this.price,
    this.currency = 'UZS',
  });

  factory ServicePackage.fromJson(Map<String, dynamic> j) => ServicePackage(
        id: j['id'] as String,
        shopId: (j['shopId'] ?? j['shop_id'] ?? '') as String,
        serviceTypeId: (j['serviceTypeId'] ?? j['service_type_id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        description: (j['description'] ?? '') as String,
        durationMin: ((j['durationMin'] ?? j['duration_min'] ?? 60) as num).toInt(),
        price: ((j['price'] ?? 0) as num).toInt(),
        currency: (j['currency'] ?? 'UZS') as String,
      );

  /// "40 daq" / "1 soat" / "1 soat 30 daq"
  String get durationLabel {
    final h = durationMin ~/ 60;
    final m = durationMin % 60;
    if (h == 0) return '$m daq';
    if (m == 0) return '$h soat';
    return '$h soat $m daq';
  }
}
