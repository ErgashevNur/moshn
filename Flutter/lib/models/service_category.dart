/// Bosh ekrandagi guruhlash uchun kategoriyalar — admin panel
/// (`service-types/page.tsx`, `CATEGORIES`) bilan bir xil id'lar va tartib.
class ServiceCategoryMeta {
  final String id;
  final String icon;
  const ServiceCategoryMeta(this.id, this.icon);

  /// `assets/translations/{uz,ru}.json`dagi `category.<id>` kaliti.
  String get labelKey => 'category.$id';

  /// Katak ostidagi izoh — kategoriya ichida nima borligi (`category.<id>_sub`).
  String get subLabelKey => 'category.${id}_sub';
}

const List<ServiceCategoryMeta> kServiceCategories = [
  ServiceCategoryMeta('service', 'wrench'),
  ServiceCategoryMeta('oil', 'droplet'),
  ServiceCategoryMeta('tires', 'wheel'),
  ServiceCategoryMeta('body', 'car'),
  ServiceCategoryMeta('electrics', 'zap'),
];

/// Bosh ekranda bulardan tashqari 6-chi katak bor — SOS ("Автосигнал").
/// U bu ro'yxatga kirmaydi: ortida `ServiceType` yo'q, to'g'ridan-to'g'ri
/// `/owner/sos` oqimiga olib boradi (`_SosCategoryTile`, home_screen.dart).

/// Noma'lum id kelsa (eski deep-link, admin qo'shgan yangi kategoriya) —
/// hech qanday mavjud kategoriya sifatida ko'rsatilmasin, umumiy belgi bilan
/// o'z id'sini qaytaradi.
ServiceCategoryMeta serviceCategoryMeta(String id) => kServiceCategories
    .firstWhere((c) => c.id == id, orElse: () => ServiceCategoryMeta(id, 'wrench'));
