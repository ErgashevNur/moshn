import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/ws_service.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/m_pitgo_icon.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'my_vehicles_screen.dart';
import '../shared/profile_screen.dart';

class OwnerRoot extends ConsumerStatefulWidget {
  final int initialTab;
  const OwnerRoot({super.key, this.initialTab = 0});

  @override
  ConsumerState<OwnerRoot> createState() => _OwnerRootState();
}

class _OwnerRootState extends ConsumerState<OwnerRoot> {
  late int _index = widget.initialTab;

  @override
  void initState() {
    super.initState();
    // Mijoz ilovasi WS'ga ulanmasdi — servis/usta/evakuator ekranlarida
    // `connect()` bor edi, mijozda esa faqat SOS oqimida. Shu sababli
    // bron tafsilotlaridagi jonli yangilanish (bosqich, fotohisobot,
    // qo'shimcha ish) hech qachon ishlamagan: tinglovchi bor, soket yo'q.
    WsService.instance.connect();
  }

  static const _pages = <Widget>[
    OwnerHomeScreen(),
    MyBookingsScreen(),
    MyVehiclesScreen(),
    ProfileScreen(),
  ];

  void _onTabTap(int i) {
    if (i == 1) ref.invalidate(allBookingsProvider);
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: IndexedStack(index: _index, children: _pages),
      // SOS — pastki bar markazida, yarmi bardan yuqorida turadi (centerDocked).
      floatingActionButton: _SosFab(onTap: () => context.push('/owner/sos')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: OwnerBottomBar(
        index: _index,
        onTap: _onTabTap,
      ),
    );
  }
}

class _SosFab extends StatelessWidget {
  final VoidCallback onTap;
  const _SosFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.danger,
          border: Border.all(color: AppColors.bg(context), width: 4),
          boxShadow: [
            BoxShadow(
              color: AppColors.danger.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'SOS',
            style: AppTypography.soraSize(15, weight: FontWeight.w800)
                .copyWith(color: Colors.white, letterSpacing: -0.2),
          ),
        ),
      ),
    );
  }
}

/// Mijoz ilovasining pastki navigatsiyasi.
///
/// `OwnerRoot`dan tashqarida ham ishlatiladi (masalan bron tafsilotlari
/// ekranida — maketda u yerda ham nav ko'rinadi). U yerda markazdagi SOS
/// tugmasi bo'lmaydi: yopishgan to'lov paneli bilan ustma-ust tushardi,
/// shuning uchun `showSosSlot` bilan bo'shliq olib tashlanadi.
class OwnerBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final bool showSosSlot;

  const OwnerBottomBar({
    super.key,
    required this.index,
    required this.onTap,
    this.showSosSlot = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        border: Border(
          top: BorderSide(color: AppColors.hairline(context), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(icon: 'home',     label: 'tabs.home'.tr(),     active: index == 0, onTap: () => onTap(0)),
              _NavItem(icon: 'calendar', label: 'tabs.bookings'.tr(), active: index == 1, onTap: () => onTap(1)),
              // Markazdagi SOS tugmasi uchun joy
              if (showSosSlot) const SizedBox(width: 70),
              _NavItem(icon: 'car',      label: 'tabs.garage'.tr(),   active: index == 2, onTap: () => onTap(2)),
              _NavItem(icon: 'user',     label: 'tabs.profile'.tr(),  active: index == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.text(context) : AppColors.text3(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PitGoIcon(name: icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.soraSize(10, weight: FontWeight.w500)
                  .copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
