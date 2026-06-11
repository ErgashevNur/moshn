import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/m_moshn_icon.dart';
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
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: _onTabTap,
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

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
            MoshnIcon(name: icon, size: 22, color: color),
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
