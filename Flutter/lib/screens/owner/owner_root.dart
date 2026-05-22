import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../../theme/colors.dart';
import 'home_screen.dart';
import 'find_mechanic_screen.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';

class OwnerRoot extends StatefulWidget {
  const OwnerRoot({super.key});

  @override
  State<OwnerRoot> createState() => _OwnerRootState();
}

class _OwnerRootState extends State<OwnerRoot> {
  final _controller = CupertinoTabController(initialIndex: 0);

  // O'rtadagi (index 2) slot SOS tugmasi uchun — u tab sifatida tanlanmaydi.
  int _lastIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    if (index == 2) {
      // SOS sloti: tabni almashtirmaymiz, favqulodda ekranni ochamiz.
      _controller.index = _lastIndex;
      context.push('/owner/sos');
    } else {
      _lastIndex = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CupertinoTabScaffold(
          controller: _controller,
          tabBar: CupertinoTabBar(
            activeColor: AppColors.primaryOf(context),
            onTap: _onTap,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.house),
                activeIcon: const Icon(CupertinoIcons.house_fill),
                label: 'tabs.home'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.wrench),
                activeIcon: const Icon(CupertinoIcons.wrench_fill),
                label: 'tabs.repair'.tr(),
              ),
              // SOS tugmasi ustiga qo'yiladigan bo'sh slot.
              const BottomNavigationBarItem(
                icon: SizedBox(height: 24),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.bell),
                activeIcon: const Icon(CupertinoIcons.bell_fill),
                label: 'tabs.notifications'.tr(),
              ),
              BottomNavigationBarItem(
                icon: const Icon(CupertinoIcons.person),
                activeIcon: const Icon(CupertinoIcons.person_fill),
                label: 'tabs.profile'.tr(),
              ),
            ],
          ),
          tabBuilder: (context, index) {
            switch (index) {
              case 0:
                return const OwnerHomeScreen();
              case 1:
                return const FindMechanicScreen();
              case 2:
                return const SizedBox.shrink(); // hech qachon ko'rsatilmaydi
              case 3:
                return const NotificationsScreen();
              case 4:
                return const ProfileScreen();
            }
            return const OwnerHomeScreen();
          },
        ),
        // Bo'rtib turadigan markaziy SOS tugmasi.
        Positioned.fill(
          child: SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _SosButton(onPressed: () => context.push('/owner/sos')),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SosButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SosButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.destructive,
          shape: BoxShape.circle,
          border: Border.all(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.destructive.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            'sos.button'.tr(),
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
