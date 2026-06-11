class ServiceType {
  final String id;
  final String slug;
  final String nameUz;
  final String nameRu;
  final String icon;
  final int basePrice;

  ServiceType({
    required this.id,
    required this.slug,
    required this.nameUz,
    required this.nameRu,
    required this.icon,
    required this.basePrice,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) => ServiceType(
        id: json['id'] as String,
        slug: json['slug'] as String,
        nameUz: (json['name_uz'] ?? '') as String,
        nameRu: (json['name_ru'] ?? '') as String,
        icon: (json['icon'] ?? '🔧') as String,
        basePrice: (json['base_price'] ?? 0) as int,
      );

  String get name => nameUz;

  String nameFor(String locale) =>
      locale == 'ru' && nameRu.isNotEmpty ? nameRu : nameUz;
}
