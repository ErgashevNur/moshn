import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../widgets/m_moshn_icon.dart';
import 'service_home_screen.dart';
import 'crm_screen.dart';
import '../shared/profile_screen.dart';

class ServiceRoot extends StatefulWidget {
  const ServiceRoot({super.key});
  @override
  State<ServiceRoot> createState() => _ServiceRootState();
}

class _ServiceRootState extends State<ServiceRoot> {
  int _index = 0;

  static const _pages = <Widget>[
    ServiceHomeScreen(),
    CrmScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
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
              _NavItem(icon: 'calendar', label: 'service.home_title'.tr(),  active: index == 0, onTap: () => onTap(0)),
              _NavItem(icon: 'users',    label: 'tabs.customers'.tr(),      active: index == 1, onTap: () => onTap(1)),
              _NavItem(icon: 'user',     label: 'tabs.profile'.tr(),        active: index == 2, onTap: () => onTap(2)),
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
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

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
            Text(label,
                style: AppTypography.soraSize(10, weight: FontWeight.w500)
                    .copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
