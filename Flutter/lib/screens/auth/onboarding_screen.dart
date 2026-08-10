import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_brand_mark.dart';
import '../../widgets/m_button.dart';
import '../../widgets/m_pitgo_icon.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final slides = [
      _SlideData(
        title: 'Любой автосервис — в одном приложении',
        sub: 'Шины, масло, тормоза, двигатель — выберите услугу и запишитесь к мастеру рядом за пару касаний.',
        visual: 'services',
      ),
      _SlideData(
        title: 'Сломались в пути? Жмите SOS',
        sub: 'Запрос улетит ближайшим мастерам — кто первым откликнется, тот уже едет к вам. Нужен эвакуатор? Тоже вызовем.',
        visual: 'sos',
      ),
      _SlideData(
        title: 'Записывайтесь сейчас — платите позже',
        sub: 'Забронируйте время и оплатите после — всё в приложении.',
        visual: 'pay',
      ),
    ];
    final isLast = _page == slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.go('/phone'),
                    child: Text(
                      'Пропустить',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.text2(context)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildVisual(slides[_page].visual, key: ValueKey(_page)),
                    ),
                    const SizedBox(height: 40),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Column(
                        key: ValueKey('t$_page'),
                        children: [
                          Text(
                            slides[_page].title,
                            textAlign: TextAlign.center,
                            style: AppTypography.displayLarge.copyWith(
                              color: AppColors.text(context),
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slides[_page].sub,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.text2(context),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (i) {
                      final active = i == _page;
                      return GestureDetector(
                        onTap: () => setState(() => _page = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 22 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.text(context)
                                : AppColors.text3(context),
                            borderRadius: BorderRadius.circular(AppSpacing.r_full),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  MButton(
                    label: isLast ? 'Начать' : 'Далее',
                    onTap: () {
                      if (isLast) {
                        context.go('/phone');
                      } else {
                        setState(() => _page++);
                      }
                    },
                    trailing: isLast
                        ? const Icon(Icons.arrow_forward_rounded)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisual(String type, {Key? key}) {
    if (type == 'pay') {
      return SizedBox(
        key: key,
        width: 200,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: -8 * math.pi / 180,
              child: Transform.translate(
                offset: const Offset(-26, 14),
                child: Container(
                  width: 150,
                  height: 94,
                  decoration: BoxDecoration(
                    color: AppColors.surface3(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.hairline2(context), width: 1),
                  ),
                ),
              ),
            ),
            Container(
              width: 160,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.inverseBg(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppSpacing.shadow2,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BrandMark(size: 26, color: AppColors.inverseText(context)),
                  Text(
                    '•••• 4417',
                    style: AppTypography.mono.copyWith(
                      color: AppColors.inverseText(context),
                      fontSize: 14,
                      letterSpacing: 0.12 * 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (type == 'sos') {
      // Qizil SOS doirasi + atrofida to'lqin halqalari (pastki bardagi
      // yangi SOS tugmasi bilan bir xil vizual til).
      return SizedBox(
        key: key,
        width: 200,
        height: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.10), width: 2),
              ),
            ),
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.22), width: 2),
              ),
            ),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'SOS',
                  style: AppTypography.soraSize(22, weight: FontWeight.w800)
                      .copyWith(color: Colors.white, letterSpacing: -0.3),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 18,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.inverseBg(context),
                  boxShadow: AppSpacing.shadow2,
                ),
                child: Icon(Icons.local_shipping_rounded,
                    size: 22, color: AppColors.inverseText(context)),
              ),
            ),
          ],
        ),
      );
    }

    // 'services' — turli avtoservis yo'nalishlari to'plami (2x2 katak).
    Widget tile(String icon, {bool accent = false}) => Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: accent
                ? AppColors.inverseBg(context)
                : AppColors.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: accent
                ? null
                : Border.all(color: AppColors.hairline2(context)),
            boxShadow: accent ? AppSpacing.shadow2 : null,
          ),
          child: Center(
            child: PitGoIcon(
              name: icon,
              size: 32,
              color: accent
                  ? AppColors.inverseText(context)
                  : AppColors.text2(context),
            ),
          ),
        );

    return SizedBox(
      key: key,
      width: 200,
      height: 180,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile('wheel'),
                const SizedBox(width: 12),
                tile('droplet', accent: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                tile('settings'),
                const SizedBox(width: 12),
                tile('wrench'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  final String title, sub, visual;
  const _SlideData({required this.title, required this.sub, required this.visual});
}
