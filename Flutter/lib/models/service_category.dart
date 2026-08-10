/// Bosh ekrandagi guruhlash uchun kategoriyalar — admin panel
/// (`service-types/page.tsx`, `CATEGORIES`) bilan bir xil id'lar va tartib.
class ServiceCategoryMeta {
  final String id;
  final String icon;
  const ServiceCategoryMeta(this.id, this.icon);

  /// `assets/translations/{uz,ru}.json`dagi `category.<id>` kaliti.
  String get labelKey => 'category.$id';
}

const List<ServiceCategoryMeta> kServiceCategories = [
  ServiceCategoryMeta('tires', 'wheel'),
  ServiceCategoryMeta('engine', 'droplet'),
  ServiceCategoryMeta('brakes', 'shield'),
  ServiceCategoryMeta('transmission', 'settings'),
  ServiceCategoryMeta('electrics', 'zap'),
  ServiceCategoryMeta('body', 'car'),
  ServiceCategoryMeta('other', 'wrench'),
];

ServiceCategoryMeta serviceCategoryMeta(String id) =>
    kServiceCategories.firstWhere((c) => c.id == id, orElse: () => kServiceCategories.last);
