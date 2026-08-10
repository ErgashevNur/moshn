class ServiceType {
  final String id;
  final String slug;
  final String nameUz;
  final String nameRu;
  final String icon;
  final String category;
  final int priceMin;
  final int priceMax;

  ServiceType({
    required this.id,
    required this.slug,
    required this.nameUz,
    required this.nameRu,
    required this.icon,
    this.category = '',
    required this.priceMin,
    required this.priceMax,
  });

  factory ServiceType.fromJson(Map<String, dynamic> json) => ServiceType(
        id: json['id'] as String,
        slug: json['slug'] as String,
        nameUz: (json['nameUz'] ?? json['name_uz'] ?? '') as String,
        nameRu: (json['nameRu'] ?? json['name_ru'] ?? '') as String,
        icon: (json['icon'] ?? '') as String,
        category: (json['category'] ?? '') as String,
        priceMin: ((json['priceMin'] ?? json['price_min'] ?? 0) as num).toInt(),
        priceMax: ((json['priceMax'] ?? json['price_max'] ?? 0) as num).toInt(),
      );

  /// Bo'sh/tanilmagan kategoriya "other"ga tushadi (admin/ServiceCategories bilan bir xil qoida).
  String get categoryOrOther => category.isNotEmpty ? category : 'other';

  String get name => nameRu.isNotEmpty ? nameRu : nameUz;

  String nameFor(String locale) =>
      nameRu.isNotEmpty ? nameRu : nameUz;

  /// "20 000 – 80 000 so'm" kabi diapazon matni, ikkalasi ham 0 bo'lsa bo'sh.
  bool get hasPriceRange => priceMin > 0 || priceMax > 0;
}
