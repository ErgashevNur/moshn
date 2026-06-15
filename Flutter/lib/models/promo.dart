class Promo {
  final String id;
  final String badgeUz;
  final String badgeRu;
  final String titleUz;
  final String titleRu;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  Promo({
    required this.id,
    required this.badgeUz,
    required this.badgeRu,
    required this.titleUz,
    required this.titleRu,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  factory Promo.fromJson(Map<String, dynamic> j) => Promo(
        id: j['id'] as String,
        badgeUz: (j['badgeUz'] ?? j['badge_uz'] ?? '') as String,
        badgeRu: (j['badgeRu'] ?? j['badge_ru'] ?? '') as String,
        titleUz: (j['titleUz'] ?? j['title_uz'] ?? '') as String,
        titleRu: (j['titleRu'] ?? j['title_ru'] ?? '') as String,
        isActive: (j['isActive'] ?? j['is_active'] ?? true) as bool,
        startDate: j['startDate'] != null || j['start_date'] != null
            ? DateTime.tryParse((j['startDate'] ?? j['start_date']) as String)
            : null,
        endDate: j['endDate'] != null || j['end_date'] != null
            ? DateTime.tryParse((j['endDate'] ?? j['end_date']) as String)
            : null,
      );

  String badgeFor(String locale) =>
      locale == 'ru' && badgeRu.isNotEmpty ? badgeRu : badgeUz;

  String titleFor(String locale) =>
      locale == 'ru' && titleRu.isNotEmpty ? titleRu : titleUz;
}
