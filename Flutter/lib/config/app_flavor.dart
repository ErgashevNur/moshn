/// PitGo bitta kod bazasidan ikkita alohida ilova sifatida build qilinadi:
/// **PitGo** (mijoz) va **PitGo Pro** (servis egasi/usta/evakuator).
/// Har bir `main_*.dart` `runApp()`dan oldin shu qiymatni bir marta
/// o'rnatadi — qolgan barcha umumiy ekranlar (masalan `otp_screen.dart`)
/// shu orqali qaysi ilova ekanini biladi.
enum AppFlavor { customer, pro }

class AppFlavorConfig {
  AppFlavorConfig._();

  static AppFlavor current = AppFlavor.customer;

  static bool get isCustomer => current == AppFlavor.customer;
  static bool get isPro => current == AppFlavor.pro;

  static String get appName => isCustomer ? 'PitGo' : 'PitGo Pro';
  static String get otherAppName => isCustomer ? 'PitGo Pro' : 'PitGo';
}
