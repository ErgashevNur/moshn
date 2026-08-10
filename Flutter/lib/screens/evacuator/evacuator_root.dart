import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/ws_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../shared/profile_screen.dart';
import 'evacuator_sos_screen.dart';

class EvacuatorRoot extends ConsumerStatefulWidget {
  const EvacuatorRoot({super.key});

  @override
  ConsumerState<EvacuatorRoot> createState() => _EvacuatorRootState();
}

class _EvacuatorRootState extends ConsumerState<EvacuatorRoot> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WsService.instance.connect();
  }

  @override
  void dispose() {
    WsService.instance.disconnect();
    super.dispose();
  }

  static const _pages = <Widget>[
    EvacuatorSosScreen(),
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
    final items = <_NavItem>[
      const _NavItem(icon: Icons.local_shipping_rounded, label: 'SOS', index: 0),
      const _NavItem(icon: Icons.person_rounded, label: 'Профиль', index: 1),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        border: Border(
          top: BorderSide(color: AppColors.hairline(context), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: items
                .map((item) => Expanded(
                      child: _NavButton(
                        item: item,
                        active: index == item.index,
                        onTap: () => onTap(item.index),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int index;

  const _NavItem({required this.icon, required this.label, required this.index});
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.text(context) : AppColors.text3(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (active)
            Container(
              width: 32,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.text(context),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
            ),
          Icon(item.icon, size: 20, color: color),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: AppTypography.soraSize(9, weight: FontWeight.w500).copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
