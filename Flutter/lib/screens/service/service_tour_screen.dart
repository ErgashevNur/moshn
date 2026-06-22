import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_button.dart';

class ServiceTourScreen extends StatefulWidget {
  final VoidCallback onDone;
  const ServiceTourScreen({super.key, required this.onDone});

  @override
  State<ServiceTourScreen> createState() => _ServiceTourScreenState();
}

class _ServiceTourScreenState extends State<ServiceTourScreen>
    with SingleTickerProviderStateMixin {
  int _page = 0;
  late final AnimationController _fadeCtrl;
  late Animation<double> _fade;

  String _t(String uz, String ru) =>
      context.locale.languageCode == 'ru' ? ru : uz;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1,
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goTo(int next) async {
    await _fadeCtrl.reverse();
    if (!mounted) return;
    setState(() => _page = next);
    _fadeCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _buildSlides();
    final isLast = _page == slides.length - 1;
    final slide = slides[_page];

    return Material(
      color: AppColors.bg(context),
      child: SafeArea(
        child: Column(
          children: [
            // top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // step indicator chips
                  Row(
                    children: List.generate(slides.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.only(right: 5),
                        width: active ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.text(context)
                              : AppColors.text3(context),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      );
                    }),
                  ),
                  TextButton(
                    onPressed: widget.onDone,
                    child: Text(
                      _t("O'tkazib yuborish", 'Пропустить'),
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.text2(context)),
                    ),
                  ),
                ],
              ),
            ),

            // content
            Expanded(
              child: FadeTransition(
                opacity: _fade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _TourVisual(slide: slide),
                      const SizedBox(height: 40),
                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.displayLarge.copyWith(
                          color: AppColors.text(context),
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        slide.sub,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.text2(context),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // bottom nav
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Row(
                children: [
                  if (_page > 0)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _BackButton(
                        onTap: () => _goTo(_page - 1),
                      ),
                    ),
                  Expanded(
                    child: MButton(
                      label: isLast
                          ? _t('Boshlash', 'Начать')
                          : _t('Keyingi', 'Далее'),
                      onTap: () {
                        if (isLast) {
                          widget.onDone();
                        } else {
                          _goTo(_page + 1);
                        }
                      },
                      trailing: isLast
                          ? const Icon(Icons.check_rounded, size: 20)
                          : const Icon(Icons.arrow_forward_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TourSlide> _buildSlides() => [
        _TourSlide(
          icon: Icons.calendar_today_rounded,
          color: const Color(0xFF4A90E2),
          tabIndex: 0,
          title: _t(
            'Bronlar real vaqtda keladi',
            'Брони приходят в реальном времени',
          ),
          sub: _t(
            'Mijoz bron qilgan zahoti ekranda paydo bo\'ladi. Tasdiqlang yoki bekor qiling.',
            'Как только клиент записывается — запись сразу появляется на экране.',
          ),
        ),
        _TourSlide(
          icon: Icons.format_list_bulleted_rounded,
          color: const Color(0xFF7B61FF),
          tabIndex: 1,
          title: _t(
            'Navbatni boshqaring',
            'Управляйте очередью',
          ),
          sub: _t(
            'Barcha bronlarni ko\'ring, sana bo\'yicha filtrlang va «Bajarildi» ga o\'tkazing.',
            'Просматривайте все записи, фильтруйте по дате и переводите в статус «Выполнено».',
          ),
        ),
        _TourSlide(
          icon: Icons.people_rounded,
          color: const Color(0xFF34C759),
          tabIndex: 2,
          title: _t(
            'Mijozlar bazasi — CRM',
            'База клиентов — CRM',
          ),
          sub: _t(
            'VIP belgilang, eslatmalar qo\'shing va mijozning tashrif tarixini ko\'ring.',
            'Отмечайте VIP, добавляйте заметки и просматривайте историю посещений.',
          ),
        ),
        _TourSlide(
          icon: Icons.credit_card_rounded,
          color: const Color(0xFFFF9500),
          tabIndex: 3,
          title: _t(
            'To\'lovni qabul qiling',
            'Принимайте оплату',
          ),
          sub: _t(
            'QR kod orqali mijoz to\'lovini bir teg bilan qabul qiling.',
            'Принимайте оплату от клиента одним касанием через QR-код.',
          ),
        ),
        _TourSlide(
          icon: Icons.store_rounded,
          color: const Color(0xFFFF3B30),
          tabIndex: 4,
          title: _t(
            'Servis profilingizni to\'ldiring',
            'Заполните профиль сервиса',
          ),
          sub: _t(
            'Ish vaqti, xizmat turlari va narxlarni kiriting — mijozlar to\'g\'ri ma\'lumotni ko\'radi.',
            'Укажите часы работы, виды услуг и цены — клиенты увидят актуальную информацию.',
          ),
        ),
      ];
}

// ── Visual ──────────────────────────────────────────────────────────────────

class _TourVisual extends StatelessWidget {
  final _TourSlide slide;
  const _TourVisual({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: slide.color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: slide.color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(slide.icon, size: 44, color: slide.color),
        ),
      ),
    );
  }
}

// ── Back button ─────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface2(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 22,
          color: AppColors.text(context),
        ),
      ),
    );
  }
}

// ── Data ─────────────────────────────────────────────────────────────────────

class _TourSlide {
  final IconData icon;
  final Color color;
  final int tabIndex;
  final String title;
  final String sub;

  const _TourSlide({
    required this.icon,
    required this.color,
    required this.tabIndex,
    required this.title,
    required this.sub,
  });
}
