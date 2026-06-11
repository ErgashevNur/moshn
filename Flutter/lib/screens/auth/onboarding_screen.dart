import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_brand_mark.dart';
import '../../widgets/m_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;

  String _t(String uz, String ru) =>
      context.locale.languageCode == 'ru' ? ru : uz;

  @override
  Widget build(BuildContext context) {
    final slides = [
      _SlideData(
        title: _t(
          'Eng yaqin shinomontaj — qo\'l ostingizda',
          'Ближайший шиномонтаж — под рукой',
        ),
        sub: _t(
          'Xizmatni tanlang, narxni ko\'ring, vaqtga yoziling — bir necha tegishda.',
          'Выберите услугу, сравните цены и забронируйте время за пару касаний.',
        ),
        visual: 'search',
      ),
      _SlideData(
        title: _t(
          'Hozir yozeling — keyin to\'lang',
          'Записывайтесь сейчас — платите позже',
        ),
        sub: _t(
          'Bron qiling, xizmatdan keyin to\'lang — hammasi ilovada.',
          'Забронируйте время и оплатите после — всё в приложении.',
        ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _LangToggle(),
                  TextButton(
                    onPressed: () => context.go('/phone'),
                    child: Text(
                      _t('O\'tkazib yuborish', 'Пропустить'),
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
                    label: isLast
                        ? _t('Boshlash', 'Начать')
                        : _t('Keyingi', 'Далее'),
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

    // search / tire wheel visual
    return SizedBox(
      key: key,
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface3(context), width: 12),
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.text3(context), width: 10),
                ),
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 22,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.inverseBg(context),
                boxShadow: AppSpacing.shadow2,
              ),
              child: Icon(Icons.location_on_rounded,
                  size: 24, color: AppColors.inverseText(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideData {
  final String title, sub, visual;
  const _SlideData({required this.title, required this.sub, required this.visual});
}

class _LangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['uz', 'ru'].map((l) {
          final active = lang == l;
          return GestureDetector(
            onTap: () => context.setLocale(Locale(l)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.bgElevated(context) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.r_full),
                boxShadow: active ? AppSpacing.shadow1 : null,
              ),
              child: Text(
                l == 'uz' ? "O'z" : 'Ру',
                style: AppTypography.soraSize(12.5, weight: FontWeight.w600)
                    .copyWith(
                  color: active ? AppColors.text(context) : AppColors.text2(context),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
