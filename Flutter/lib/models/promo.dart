class Promo {
  final String id;
  final String badgeUz;
  final String badgeRu;
  final String titleUz;
  final String titleRu;

  Promo({
    required this.id,
    required this.badgeUz,
    required this.badgeRu,
    required this.titleUz,
    required this.titleRu,
  });

  factory Promo.fromJson(Map<String, dynamic> json) => Promo(
        id: json['id'] as String,
        badgeUz: (json['badgeUz'] ?? json['badge_uz'] ?? '') as String,
        badgeRu: (json['badgeRu'] ?? json['badge_ru'] ?? '') as String,
        titleUz: (json['titleUz'] ?? json['title_uz'] ?? '') as String,
        titleRu: (json['titleRu'] ?? json['title_ru'] ?? '') as String,
      );

  String badgeFor(String locale) =>
      locale == 'ru' && badgeRu.isNotEmpty ? badgeRu : badgeUz;

  String titleFor(String locale) =>
      locale == 'ru' && titleRu.isNotEmpty ? titleRu : titleUz;
}
