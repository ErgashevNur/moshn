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
        nameUz: (json['nameUz'] ?? json['name_uz'] ?? '') as String,
        nameRu: (json['nameRu'] ?? json['name_ru'] ?? '') as String,
        icon: (json['icon'] ?? '') as String,
        basePrice: ((json['basePrice'] ?? json['base_price'] ?? 0) as num).toInt(),
      );

  static const _emojiMap = {
    'balance':       '⚖️',
    'disk_repair':   '🔩',
    'tire_inflate':  '💨',
    'tire_change':   '🔄',
    'tire_storage':  '📦',
    'vulcanize':     '🔥',
    'podkachka':     '💨',
    'perezobuvka':   '🔄',
    'vulkanizatsiya':'🔥',
    'balancing':     '⚖️',
  };

  String get emoji => _emojiMap[icon] ?? _emojiMap[slug] ?? '🛞';

  String get name => nameRu.isNotEmpty ? nameRu : nameUz;

  String nameFor(String locale) =>
      nameRu.isNotEmpty ? nameRu : nameUz;
}
