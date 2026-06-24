import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/ws_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'service_home_screen.dart';
import 'queue_screen.dart';
import 'crm_screen.dart';
import 'terminal_screen.dart';
import 'service_coach_mark.dart';
import '../shared/profile_screen.dart';

class ServiceRoot extends ConsumerStatefulWidget {
  const ServiceRoot({super.key});

  @override
  ConsumerState<ServiceRoot> createState() => _ServiceRootState();
}

class _ServiceRootState extends ConsumerState<ServiceRoot> {
  int _index = 0;
  bool _showCoach = false;

  // Keys for spotlight coach mark
  final _navKeys = List.generate(5, (_) => GlobalKey());
  final _burgerKey = GlobalKey();

  static const _onboardKey = 'service_onboard_done';

  @override
  void initState() {
    super.initState();
    WsService.instance.connect();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkOnboard());
  }

  Future<void> _checkOnboard() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(_onboardKey) != true) {
      setState(() => _showCoach = true);
    }
  }

  Future<void> _doneCoach() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardKey, true);
    if (mounted) setState(() => _showCoach = false);
  }

  @override
  void dispose() {
    WsService.instance.disconnect();
    super.dispose();
  }

  late final _pages = <Widget>[
    ServiceHomeScreen(burgerKey: _burgerKey),
    const QueueScreen(),
    const CrmScreen(),
    const TerminalScreen(),
    const ProfileScreen(),
  ];

  void _onTabTap(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.bg(context),
          body: IndexedStack(index: _index, children: _pages),
          bottomNavigationBar: _BottomBar(
            index: _index,
            onTap: _onTabTap,
            navKeys: _navKeys,
          ),
        ),
        if (_showCoach)
          ServiceCoachMark(
            navKeys: _navKeys,
            burgerKey: _burgerKey,
            onDone: _doneCoach,
          ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final List<GlobalKey> navKeys;

  const _BottomBar({
    required this.index,
    required this.onTap,
    required this.navKeys,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.calendar_today_rounded, label: 'Сегодня', index: 0),
      _NavItem(icon: Icons.format_list_bulleted_rounded, label: 'Очередь', index: 1),
      _NavItem(icon: Icons.people_rounded, label: 'Клиенты', index: 2),
      _NavItem(icon: Icons.credit_card_rounded, label: 'Терминал', index: 3),
      _NavItem(icon: Icons.person_rounded, label: 'Профиль', index: 4),
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
                        key: navKeys[item.index],
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    super.key,
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        active ? AppColors.text(context) : AppColors.text3(context);

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
            style: AppTypography.soraSize(9, weight: FontWeight.w500)
                .copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
