import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/shop.dart';
import '../../models/service_type.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_moshn_icon.dart';
import '../../widgets/m_workshop_card.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

final _catShopsProvider =
    FutureProvider.autoDispose.family<List<Shop>, String>((ref, slug) {
  return ShopService().getShops(serviceType: slug);
});

final _serviceTypesForCatProvider =
    FutureProvider.autoDispose<List<ServiceType>>((ref) {
  return ShopService().getServiceTypes();
});

// ── Per-service metadata ───────────────────────────────────────────────────────

class _InfoChip {
  final IconData icon;
  final String labelUz;
  final String labelRu;
  const _InfoChip(this.icon, this.labelUz, this.labelRu);
}

class _Meta {
  final String nameUz;
  final String nameRu;
  final String iconName;
  final Color accent;
  final String descriptionUz;
  final String descriptionRu;
  final String priceFrom;
  final String durationUz;
  final String durationRu;
  final List<String> stepsUz;
  final List<String> stepsRu;
  final List<_InfoChip> chips;

  const _Meta({
    required this.nameUz,
    required this.nameRu,
    required this.iconName,
    required this.accent,
    required this.descriptionUz,
    required this.descriptionRu,
    required this.priceFrom,
    required this.durationUz,
    required this.durationRu,
    required this.stepsUz,
    required this.stepsRu,
    required this.chips,
  });

  String nameFor(String locale) => locale == 'ru' ? nameRu : nameUz;
  String descriptionFor(String locale) =>
      locale == 'ru' ? descriptionRu : descriptionUz;
  String durationFor(String locale) => locale == 'ru' ? durationRu : durationUz;
  List<String> stepsFor(String locale) => locale == 'ru' ? stepsRu : stepsUz;
}

const _metas = <String, _Meta>{
  'tire_change': _Meta(
    nameUz: "G'ildirak almashtirish",
    nameRu: "Замена шины",
    iconName: 'disc',
    accent: Color(0xFFD4A843),
    descriptionUz:
        "Yozgi yoki qishki shinalarga almashtirish. Professional uskunalar "
        "bilan tez va sifatli bajariladi. Tanlangan shinomontajda jo'nating.",
    descriptionRu:
        "Замена на летние или зимние шины. Выполняется быстро и качественно "
        "с профессиональным оборудованием. Запишитесь в выбранный шиномонтаж.",
    priceFrom: '35 000',
    durationUz: '30 daq',
    durationRu: '30 мин',
    stepsUz: ["Eski shinani yechish", "Yangi shinani o'rnatish", "Balanslash", "Nazorat"],
    stepsRu: ["Снять старую шину", "Установить новую шину", "Балансировка", "Контроль"],
    chips: [
      _InfoChip(Icons.timer_outlined, '30 daq', '30 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "35 000 so'mdan", 'от 35 000 сум'),
      _InfoChip(Icons.verified_outlined, 'Kafolat bilan', 'С гарантией'),
    ],
  ),
  'pumping': _Meta(
    nameUz: "Havo to'ldirish",
    nameRu: "Подкачка",
    iconName: 'gauge',
    accent: Color(0xFF4CA8D9),
    descriptionUz:
        "Shinangizning havo bosimini to'g'ri darajaga keltirish. "
        "Qurilma bilan aniq bosim o'lchanadi va to'ldiriladi. "
        "Tez xizmat — 5 daqiqa.",
    descriptionRu:
        "Доведение давления в шинах до нужного уровня. "
        "Точное измерение и накачка специальным оборудованием. "
        "Быстрая услуга — 5 минут.",
    priceFrom: '5 000',
    durationUz: '5 daq',
    durationRu: '5 мин',
    stepsUz: ["Bosimni o'lchash", "Havo to'ldirish", "Qayta tekshirish"],
    stepsRu: ["Измерить давление", "Накачать", "Повторная проверка"],
    chips: [
      _InfoChip(Icons.timer_outlined, '5 daq', '5 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "5 000 so'mdan", 'от 5 000 сум'),
      _InfoChip(Icons.speed_rounded, 'Aniq bosim', 'Точное давление'),
    ],
  ),
  'podkachka': _Meta(
    nameUz: "Havo to'ldirish",
    nameRu: "Подкачка",
    iconName: 'gauge',
    accent: Color(0xFF4CA8D9),
    descriptionUz:
        "Shinangizning havo bosimini to'g'ri darajaga keltirish. "
        "Qurilma bilan aniq bosim o'lchanadi va to'ldiriladi.",
    descriptionRu:
        "Доведение давления в шинах до нужного уровня. "
        "Точное измерение и накачка специальным оборудованием.",
    priceFrom: '5 000',
    durationUz: '5 daq',
    durationRu: '5 мин',
    stepsUz: ["Bosimni o'lchash", "Havo to'ldirish", "Qayta tekshirish"],
    stepsRu: ["Измерить давление", "Накачать", "Повторная проверка"],
    chips: [
      _InfoChip(Icons.timer_outlined, '5 daq', '5 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "5 000 so'mdan", 'от 5 000 сум'),
      _InfoChip(Icons.speed_rounded, 'Aniq bosim', 'Точное давление'),
    ],
  ),
  'patch': _Meta(
    nameUz: "Teshik yamash",
    nameRu: "Ремонт прокола",
    iconName: 'wrench',
    accent: Color(0xFFE87D3E),
    descriptionUz:
        "Shinangiz teshilgan bo'lsa, tez va ishonchli yamaymiz. "
        "Zamonaviy usulda ichdan yamash — ko'rinmas natija. "
        "Shinani almashtirmasdan davom eting.",
    descriptionRu:
        "Если шина пробита, отремонтируем быстро и надёжно. "
        "Современный метод вулканизации — незаметный результат. "
        "Продолжайте движение без замены шины.",
    priceFrom: '20 000',
    durationUz: '20 daq',
    durationRu: '20 мин',
    stepsUz: ["Teshikni topish", "Shinani yechish", "Yamash", "Qaytarish"],
    stepsRu: ["Найти прокол", "Снять шину", "Вулканизация", "Установить обратно"],
    chips: [
      _InfoChip(Icons.timer_outlined, '20 daq', '20 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "20 000 so'mdan", 'от 20 000 сум'),
      _InfoChip(Icons.build_circle_outlined, 'Vulkanizatsiya', 'Вулканизация'),
    ],
  ),
  'remont_prokola': _Meta(
    nameUz: "Teshik yamash",
    nameRu: "Ремонт прокола",
    iconName: 'wrench',
    accent: Color(0xFFE87D3E),
    descriptionUz:
        "Shinangiz teshilgan bo'lsa, tez va ishonchli yamaymiz. "
        "Zamonaviy usulda ichdan yamash xizmati.",
    descriptionRu:
        "Если шина пробита, отремонтируем быстро и надёжно. "
        "Современный метод вулканизации изнутри.",
    priceFrom: '20 000',
    durationUz: '20 daq',
    durationRu: '20 мин',
    stepsUz: ["Teshikni topish", "Shinani yechish", "Yamash", "Qaytarish"],
    stepsRu: ["Найти прокол", "Снять шину", "Вулканизация", "Установить обратно"],
    chips: [
      _InfoChip(Icons.timer_outlined, '20 daq', '20 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "20 000 so'mdan", 'от 20 000 сум'),
      _InfoChip(Icons.build_circle_outlined, 'Vulkanizatsiya', 'Вулканизация'),
    ],
  ),
  'balancing': _Meta(
    nameUz: "Balanslash",
    nameRu: "Балансировка",
    iconName: 'disc',
    accent: Color(0xFF30D158),
    descriptionUz:
        "G'ildirak balansini rostlash. Rulda titrash va shinaning "
        "noto'g'ri eyilishini oldini oladi. Kompyuter bilan aniq hisoblash.",
    descriptionRu:
        "Балансировка колеса на станке. Устраняет вибрацию руля "
        "и неравномерный износ шины. Точный компьютерный расчёт.",
    priceFrom: '25 000',
    durationUz: '25 daq',
    durationRu: '25 мин',
    stepsUz: ["Balanslash stanogida tekshirish", "Og'irlik qo'yish", "Nazorat"],
    stepsRu: ["Проверка на балансировочном станке", "Установка грузиков", "Контроль"],
    chips: [
      _InfoChip(Icons.timer_outlined, '25 daq', '25 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "25 000 so'mdan", 'от 25 000 сум'),
      _InfoChip(Icons.computer_rounded, 'Kompyuter bilan', 'Компьютерная'),
    ],
  ),
  'rim_repair': _Meta(
    nameUz: "Disk ta'mirlash",
    nameRu: "Рихтовка диска",
    iconName: 'disc',
    accent: Color(0xFF9B72CF),
    descriptionUz:
        "Disk (rim) egri yoki shikastlangan bo'lsa, to'g'irlaymiz. "
        "Aylana disk, alyuminiy va po'lat disklarni ta'mirlash. "
        "Ko'rinishini asl holiga qaytaramiz.",
    descriptionRu:
        "Исправляем погнутый или повреждённый диск (rim). "
        "Работаем с литыми, алюминиевыми и стальными дисками. "
        "Возвращаем первоначальный вид.",
    priceFrom: '80 000',
    durationUz: '60 daq',
    durationRu: '60 мин',
    stepsUz: ["Ko'zdan kechirish", "To'g'rilash", "Pardozlash", "Tekshirish"],
    stepsRu: ["Осмотр", "Рихтовка", "Полировка", "Проверка"],
    chips: [
      _InfoChip(Icons.timer_outlined, '60 daq', '60 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "80 000 so'mdan", 'от 80 000 сум'),
      _InfoChip(Icons.auto_fix_high_rounded, 'Alyuminiy ham', 'Алюминий тоже'),
    ],
  ),
  'disk_repair': _Meta(
    nameUz: "Disk ta'mirlash",
    nameRu: "Рихтовка диска",
    iconName: 'disc',
    accent: Color(0xFF9B72CF),
    descriptionUz:
        "Disk (rim) egri yoki shikastlangan bo'lsa, to'g'irlaymiz. "
        "Aylana disk, alyuminiy va po'lat disklarni ta'mirlash.",
    descriptionRu:
        "Исправляем погнутый или повреждённый диск (rim). "
        "Работаем с литыми, алюминиевыми и стальными дисками.",
    priceFrom: '80 000',
    durationUz: '60 daq',
    durationRu: '60 мин',
    stepsUz: ["Ko'zdan kechirish", "To'g'rilash", "Pardozlash", "Tekshirish"],
    stepsRu: ["Осмотр", "Рихтовка", "Полировка", "Проверка"],
    chips: [
      _InfoChip(Icons.timer_outlined, '60 daq', '60 мин'),
      _InfoChip(Icons.currency_exchange_rounded, "80 000 so'mdan", 'от 80 000 сум'),
      _InfoChip(Icons.auto_fix_high_rounded, 'Alyuminiy ham', 'Алюминий тоже'),
    ],
  ),
  'storage': _Meta(
    nameUz: "Mavsumiy saqlash",
    nameRu: "Сезонное хранение",
    iconName: 'layers',
    accent: Color(0xFF2EC6C6),
    descriptionUz:
        "Mavsumdan so'ng shinalaringizni xavfsiz va quruq saqlash ombori. "
        "Har bir shina raqamlanadi, saqlanadi va mavsum boshlanishida topshiriladi.",
    descriptionRu:
        "Безопасное и сухое хранение шин после сезона. "
        "Каждая шина нумеруется и хранится до начала следующего сезона.",
    priceFrom: '120 000',
    durationUz: 'Mavsum',
    durationRu: 'Сезон',
    stepsUz: ["Qabul qilish", "Raqamlash", "Saqlash", "Topshirish"],
    stepsRu: ["Приём", "Нумерация", "Хранение", "Выдача"],
    chips: [
      _InfoChip(Icons.calendar_month_outlined, 'Butun mavsum', 'Весь сезон'),
      _InfoChip(Icons.currency_exchange_rounded, "120 000 so'mdan", 'от 120 000 сум'),
      _InfoChip(Icons.security_rounded, "Sug'urtalangan", 'Застраховано'),
    ],
  ),
  'hranenie': _Meta(
    nameUz: "Mavsumiy saqlash",
    nameRu: "Сезонное хранение",
    iconName: 'layers',
    accent: Color(0xFF2EC6C6),
    descriptionUz:
        "Mavsumdan so'ng shinalaringizni xavfsiz va quruq saqlash ombori. "
        "Mavsum boshlanishida topshiriladi.",
    descriptionRu:
        "Безопасное и сухое хранение шин после сезона. "
        "Выдаются в начале следующего сезона.",
    priceFrom: '120 000',
    durationUz: 'Mavsum',
    durationRu: 'Сезон',
    stepsUz: ["Qabul qilish", "Raqamlash", "Saqlash", "Topshirish"],
    stepsRu: ["Приём", "Нумерация", "Хранение", "Выдача"],
    chips: [
      _InfoChip(Icons.calendar_month_outlined, 'Butun mavsum', 'Весь сезон'),
      _InfoChip(Icons.currency_exchange_rounded, "120 000 so'mdan", 'от 120 000 сум'),
      _InfoChip(Icons.security_rounded, "Sug'urtalangan", 'Застраховано'),
    ],
  ),
};

_Meta _metaForSlug(String slug, String locale, [ServiceType? fromApi]) {
  if (_metas.containsKey(slug)) return _metas[slug]!;
  return _Meta(
    nameUz: fromApi?.nameUz ?? slug,
    nameRu: fromApi?.nameRu ?? slug,
    iconName: 'wrench',
    accent: const Color(0xFFD4A843),
    descriptionUz: 'service_category.generic_desc'.tr(),
    descriptionRu: 'service_category.generic_desc'.tr(),
    priceFrom: '30 000',
    durationUz: '30 daq',
    durationRu: '30 мин',
    stepsUz: ["Tekshirish", "Bajarish", "Topshirish"],
    stepsRu: ["Осмотр", "Выполнение", "Сдача"],
    chips: [
      const _InfoChip(Icons.timer_outlined, '30 daq', '30 мин'),
      const _InfoChip(Icons.currency_exchange_rounded, "30 000 so'mdan", 'от 30 000 сум'),
    ],
  );
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class ServiceCategoryScreen extends ConsumerWidget {
  final String slug;
  const ServiceCategoryScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final shopsAsync = ref.watch(_catShopsProvider(slug));
    final typesAsync = ref.watch(_serviceTypesForCatProvider);

    final apiType = typesAsync.asData?.value
        .where((t) => t.slug == slug)
        .firstOrNull;

    final meta = _metaForSlug(slug, locale, apiType);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Hero
                SliverToBoxAdapter(child: _HeroSection(meta: meta, locale: locale)),

                // Info chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                    child: _ChipsRow(meta: meta, locale: locale),
                  ),
                ),

                // Description
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                    child: Text(
                      meta.descriptionFor(locale),
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.text2(context), height: 1.55),
                    ),
                  ),
                ),

                // Qadamlar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                    child: _StepsSection(meta: meta, locale: locale),
                  ),
                ),

                // Servislar header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 26, 18, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'service_category.near_services'.tr(),
                            style: AppTypography.soraSize(17,
                                    weight: FontWeight.w700)
                                .copyWith(
                                    color: AppColors.text(context),
                                    letterSpacing: -0.3),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/owner/map'),
                          child: Text(
                            'home.view_on_map'.tr(),
                            style: AppTypography.soraSize(12.5,
                                    weight: FontWeight.w500)
                                .copyWith(color: AppColors.text2(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Servislar ro'yxati
                shopsAsync.when(
                  data: (shops) {
                    if (shops.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _EmptyShops(accent: meta.accent),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      sliver: SliverList.separated(
                        itemCount: shops.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final s = shops[i];
                          return WorkshopCard(
                            name: s.shopName,
                            imageUrl: null,
                            rating: s.ratingAvg,
                            reviewCount: s.ratingCount,
                            address: s.address,
                            distance: s.distanceKm != null
                                ? '${s.distanceKm!.toStringAsFixed(1)} km'
                                : null,
                            isOpen: true,
                            onTap: () =>
                                ctx.push('/owner/shops/${s.id}'),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child:
                          Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                  error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                ),

                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.bottom + 24)),
              ],
            ),
          ),

          // Sticky bottom
          _BottomBar(meta: meta, locale: locale),
        ],
      ),
    );
  }
}

// ── Hero ───────────────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final _Meta meta;
  final String locale;
  const _HeroSection({required this.meta, required this.locale});

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;
    final small = screenH < 700;
    final heroBase = small ? 210.0 : 248.0;
    final iconSz  = small ? 60.0 : 76.0;
    final iconIconSz = small ? 26.0 : 34.0;
    final titleSz = small ? 21.0 : 24.0;

    final priceChip = locale == 'ru'
        ? 'от ${meta.priceFrom} ${'common.sum'.tr()} · ${meta.durationFor(locale)}'
        : '${meta.priceFrom} ${'common.sum'.tr()}${'common.from_suffix'.tr()} · ${meta.durationFor(locale)}';

    return SizedBox(
      height: heroBase + safeTop,
      child: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface(context),
                    meta.accent.withAlpha(30),
                  ],
                ),
              ),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -30,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meta.accent.withAlpha(20),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            right: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: meta.accent.withAlpha(15),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.only(top: safeTop),
            child: Column(
              children: [
                // Back button row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(children: [_BackBtn()]),
                ),

                // Icon + title
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: iconSz,
                        height: iconSz,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: meta.accent.withAlpha(26),
                          border: Border.all(
                              color: meta.accent.withAlpha(60), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: MoshnIcon(
                          name: meta.iconName,
                          size: iconIconSz,
                          color: meta.accent,
                        ),
                      ),
                      SizedBox(height: small ? 10 : 14),
                      Text(
                        meta.nameFor(locale),
                        style: AppTypography.soraSize(titleSz,
                                weight: FontWeight.w700)
                            .copyWith(
                          color: AppColors.text(context),
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: small ? 4 : 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: meta.accent.withAlpha(26),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.r_full),
                        ),
                        child: Text(
                          priceChip,
                          style: AppTypography.soraSize(12,
                                  weight: FontWeight.w600)
                              .copyWith(color: meta.accent),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.hairline(context), width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.chevron_left_rounded,
            size: 22, color: AppColors.text(context)),
      ),
    );
  }
}

// ── Info chips ────────────────────────────────────────────────────────────────

class _ChipsRow extends StatelessWidget {
  final _Meta meta;
  final String locale;
  const _ChipsRow({required this.meta, required this.locale});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: meta.chips.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_md),
                border:
                    Border.all(color: AppColors.hairline(context), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(c.icon, size: 14, color: meta.accent),
                  const SizedBox(width: 6),
                  Text(
                    locale == 'ru' ? c.labelRu : c.labelUz,
                    style: AppTypography.soraSize(12.5,
                            weight: FontWeight.w500)
                        .copyWith(color: AppColors.text(context)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Steps ─────────────────────────────────────────────────────────────────────

class _StepsSection extends StatelessWidget {
  final _Meta meta;
  final String locale;
  const _StepsSection({required this.meta, required this.locale});

  @override
  Widget build(BuildContext context) {
    final steps = meta.stepsFor(locale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'service_category.process_title'.tr(),
          style: AppTypography.soraSize(15, weight: FontWeight.w700)
              .copyWith(color: AppColors.text(context), letterSpacing: -0.2),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_lg),
            border: Border.all(color: AppColors.hairline(context), width: 1),
          ),
          child: Column(
            children: steps.asMap().entries.map((e) {
              final i = e.key;
              final step = e.value;
              final isLast = i == steps.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: meta.accent.withAlpha(26),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: AppTypography.soraSize(12,
                                    weight: FontWeight.w700)
                                .copyWith(color: meta.accent),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: AppTypography.body
                                .copyWith(color: AppColors.text(context)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Container(
                      height: 1,
                      margin: const EdgeInsets.only(left: 54),
                      color: AppColors.hairline(context),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyShops extends StatelessWidget {
  final Color accent;
  const _EmptyShops({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
          border: Border.all(color: AppColors.hairline(context), width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.location_searching_rounded,
                size: 36, color: AppColors.text3(context)),
            const SizedBox(height: 10),
            Text(
              'service_category.no_services'.tr(),
              style: AppTypography.soraSize(14, weight: FontWeight.w600)
                  .copyWith(color: AppColors.text(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'service_category.no_services_hint'.tr(),
              style: AppTypography.body
                  .copyWith(color: AppColors.text2(context), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky bottom bar ─────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final _Meta meta;
  final String locale;
  const _BottomBar({required this.meta, required this.locale});

  @override
  Widget build(BuildContext context) {
    final safeBot = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, 12 + safeBot),
      decoration: BoxDecoration(
        color: AppColors.bgElevated(context),
        border: Border(
            top: BorderSide(color: AppColors.hairline(context), width: 1)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'service_category.price_from_label'.tr(),
                style: AppTypography.eyebrow
                    .copyWith(color: AppColors.text3(context)),
              ),
              const SizedBox(height: 2),
              Text(
                "${meta.priceFrom} ${'common.sum'.tr()}",
                style: AppTypography.soraSize(17, weight: FontWeight.w700)
                    .copyWith(color: AppColors.text(context)),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/owner/map'),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: meta.accent,
                  borderRadius: BorderRadius.circular(AppSpacing.r_md),
                ),
                alignment: Alignment.center,
                child: Text(
                  'service_category.select_service'.tr(),
                  style: AppTypography.soraSize(15, weight: FontWeight.w700)
                      .copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
