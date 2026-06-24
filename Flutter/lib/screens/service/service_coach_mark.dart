import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Interactive spotlight tour shown on top of the real app.
/// Highlights each nav tab + burger button with a callout explaining it.
class ServiceCoachMark extends StatefulWidget {
  final List<GlobalKey> navKeys; // 5 bottom-nav keys (Today, Queue, CRM, Terminal, Profile)
  final GlobalKey burgerKey;
  final VoidCallback onDone;

  const ServiceCoachMark({
    super.key,
    required this.navKeys,
    required this.burgerKey,
    required this.onDone,
  });

  @override
  State<ServiceCoachMark> createState() => _ServiceCoachMarkState();
}

class _ServiceCoachMarkState extends State<ServiceCoachMark>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late final AnimationController _pulseCtrl;

  bool get _isLast => _step == _totalSteps - 1;
  int get _totalSteps => 5; // 4 nav tabs + burger

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  GlobalKey _keyForStep(int step) {
    // Steps 0-3 → nav items 0-3; step 4 → burger
    if (step < 4) return widget.navKeys[step];
    return widget.burgerKey;
  }

  Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  _StepData _dataForStep(int step) {
    switch (step) {
      case 0:
        return _StepData(
          title: 'Сегодняшние записи',
          sub:
              'Здесь отображаются все записи на сегодня. Как только клиент забронирует — запись сразу появится здесь.',
          shape: _SpotShape.roundedRect,
        );
      case 1:
        return _StepData(
          title: 'Очередь',
          sub: 'Управляйте всеми записями: подтверждайте, завершайте, отменяйте.',
          shape: _SpotShape.roundedRect,
        );
      case 2:
        return _StepData(
          title: 'База клиентов',
          sub:
              'Список ваших клиентов. Отмечайте VIP, добавляйте заметки, просматривайте историю визитов.',
          shape: _SpotShape.roundedRect,
        );
      case 3:
        return _StepData(
          title: 'Терминал — Оплата',
          sub: 'Принимайте оплату от клиентов через QR-код прямо здесь.',
          shape: _SpotShape.roundedRect,
        );
      default: // step 4: burger
        return _StepData(
          title: '☰ Установите цены',
          sub:
              'Нажмите эту кнопку → выберите «Цены» и укажите стоимость услуг. Клиенты увидят эти цены!',
          shape: _SpotShape.circle,
        );
    }
  }

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final key = _keyForStep(_step);
    final rect = _rectFor(key);
    final data = _dataForStep(_step);

    if (rect == null) return const SizedBox.shrink();

    final center = rect.center;

    // Spotlight size: nav items get rect-shaped, burger gets circle
    final spotRadius = data.shape == _SpotShape.circle
        ? rect.longestSide / 2 + 14
        : 0.0;
    final spotRect = data.shape == _SpotShape.roundedRect
        ? rect.inflate(12)
        : null;

    final isBottomHalf = center.dy > size.height * 0.55;

    // Callout horizontal: center on spotlight, clamped to screen edges
    const calloutW = 272.0;
    final calloutLeft =
        (center.dx - calloutW / 2).clamp(14.0, size.width - calloutW - 14);
    // Arrow tip X relative to callout
    final arrowTipX = (center.dx - calloutLeft).clamp(24.0, calloutW - 24);

    // Callout vertical
    final calloutBottom = isBottomHalf
        ? size.height - (spotRect?.top ?? center.dy - spotRadius) + 12
        : null;
    final calloutTop = isBottomHalf
        ? null
        : (spotRect?.bottom ?? center.dy + spotRadius) + 12;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dimmed overlay with spotlight hole — tap to advance
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _next,
            child: CustomPaint(
              size: size,
              painter: _SpotlightPainter(
                spotRect: spotRect,
                spotCenter: center,
                spotRadius: spotRadius,
                shape: data.shape,
              ),
            ),
          ),

          // Pulsing ring around spotlight
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (ctx, _) {
              final pulse = _pulseCtrl.value;
              if (data.shape == _SpotShape.circle) {
                final r = spotRadius + 6 + 5 * pulse;
                return Positioned(
                  left: center.dx - r,
                  top: center.dy - r,
                  child: IgnorePointer(
                    child: Container(
                      width: r * 2,
                      height: r * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.35 + 0.45 * pulse),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                final inflated = spotRect!.inflate(6 + 5 * pulse);
                return Positioned(
                  left: inflated.left,
                  top: inflated.top,
                  child: IgnorePointer(
                    child: Container(
                      width: inflated.width,
                      height: inflated.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: 0.35 + 0.45 * pulse),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),

          // Callout bubble
          Positioned(
            left: calloutLeft,
            top: calloutTop,
            bottom: calloutBottom,
            child: _Callout(
              width: calloutW,
              arrowDown: isBottomHalf,
              arrowTipX: arrowTipX,
              title: data.title,
              sub: data.sub,
              step: _step,
              total: _totalSteps,
              isLast: _isLast,
              nextLabel: _isLast ? 'Понятно!' : 'Далее',
              skipLabel: 'Пропустить',
              onNext: _next,
              onSkip: widget.onDone,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step data ─────────────────────────────────────────────────────────────────

enum _SpotShape { circle, roundedRect }

class _StepData {
  final String title;
  final String sub;
  final _SpotShape shape;
  const _StepData({required this.title, required this.sub, required this.shape});
}

// ── Spotlight painter ─────────────────────────────────────────────────────────

class _SpotlightPainter extends CustomPainter {
  final Rect? spotRect;
  final Offset spotCenter;
  final double spotRadius;
  final _SpotShape shape;

  const _SpotlightPainter({
    required this.spotRect,
    required this.spotCenter,
    required this.spotRadius,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    // Dark overlay
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: 0.68),
    );
    // Cut spotlight hole
    final holePaint = Paint()..blendMode = BlendMode.clear;
    if (shape == _SpotShape.circle) {
      canvas.drawCircle(spotCenter, spotRadius, holePaint);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(spotRect!, const Radius.circular(14)),
        holePaint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotCenter != spotCenter ||
      old.spotRadius != spotRadius ||
      old.spotRect != spotRect;
}

// ── Callout bubble ────────────────────────────────────────────────────────────

class _Callout extends StatelessWidget {
  final double width;
  final bool arrowDown; // true → arrow at bottom pointing down (target is below)
  final double arrowTipX; // X position of arrow tip within the callout
  final String title;
  final String sub;
  final int step;
  final int total;
  final bool isLast;
  final String nextLabel;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _Callout({
    required this.width,
    required this.arrowDown,
    required this.arrowTipX,
    required this.title,
    required this.sub,
    required this.step,
    required this.total,
    required this.isLast,
    required this.nextLabel,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    const arrowH = 10.0;
    const r = 16.0;

    final card = Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dots + skip
          Row(
            children: [
              ...List.generate(total, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    margin: const EdgeInsets.only(right: 5),
                    width: i == step ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == step
                          ? AppColors.text(context)
                          : AppColors.text3(context),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                  )),
              const Spacer(),
              GestureDetector(
                onTap: onSkip,
                child: Text(
                  skipLabel,
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text3(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.text(context))),
          const SizedBox(height: 6),
          Text(
            sub,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.text2(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.inverseBg(context),
                foregroundColor: AppColors.inverseText(context),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.r_sm),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                nextLabel,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.inverseText(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Add arrow (triangle) above or below the card
    final arrow = CustomPaint(
      size: Size(width, arrowH),
      painter: _ArrowPainter(
        tipX: arrowTipX,
        pointUp: !arrowDown, // when target is below, arrow points down
        color: AppColors.surface(context),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: arrowDown
          ? [card, arrow]   // card first, then arrow below pointing down
          : [arrow, card],  // arrow on top pointing up, then card
    );
  }
}

// ── Arrow triangle painter ────────────────────────────────────────────────────

class _ArrowPainter extends CustomPainter {
  final double tipX;
  final bool pointUp;
  final Color color;

  const _ArrowPainter({
    required this.tipX,
    required this.pointUp,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    const halfW = 10.0;
    final h = size.height;
    final x = tipX.clamp(halfW + 4, size.width - halfW - 4);

    if (pointUp) {
      // Triangle pointing up
      path.moveTo(x, 0);
      path.lineTo(x - halfW, h);
      path.lineTo(x + halfW, h);
    } else {
      // Triangle pointing down
      path.moveTo(x - halfW, 0);
      path.lineTo(x + halfW, 0);
      path.lineTo(x, h);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.tipX != tipX || old.pointUp != pointUp || old.color != color;
}
