import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';

import '../../theme/colors.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_screen.dart';
import 'add_service_screen.dart';
import 'clients_screen.dart';
import 'mechanic_home_screen.dart';

class MechanicRoot extends StatelessWidget {
  const MechanicRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        activeColor: AppColors.primaryOf(context),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.house),
            activeIcon: const Icon(CupertinoIcons.house_fill),
            label: 'tabs.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.add_circled),
            activeIcon: const Icon(CupertinoIcons.add_circled_solid),
            label: 'tabs.add'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.person_2),
            activeIcon: const Icon(CupertinoIcons.person_2_fill),
            label: 'tabs.clients'.tr(),
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
            return const MechanicHomeScreen();
          case 1:
            return const AddServiceScreen();
          case 2:
            return const ClientsScreen();
          case 3:
            return const NotificationsScreen();
          case 4:
            return const ProfileScreen();
        }
        return const MechanicHomeScreen();
      },
    );
  }
}
