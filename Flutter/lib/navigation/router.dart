import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_select_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/mechanic/mechanic_root.dart';
import '../screens/owner/add_vehicle_screen.dart';
import '../screens/owner/find_mechanic_screen.dart';
import '../screens/owner/mechanic_profile_screen.dart';
import '../screens/owner/owner_root.dart';
import '../screens/owner/pending_services_screen.dart';
import '../screens/owner/service_detail_screen.dart';
import '../screens/owner/sos_screen.dart';
import '../screens/owner/vehicle_detail_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../store/auth_store.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/' ||
          loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/role');

      if (auth.status == AuthStatus.initial) {
        return null;
      }

      if (auth.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/';
      }

      if (auth.status == AuthStatus.authenticated) {
        if (isAuthRoute) {
          return auth.user?.role == UserRole.mechanic ? '/mechanic' : '/owner';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/role',
        builder: (_, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, st) {
          final role = st.uri.queryParameters['role'] == 'mechanic'
              ? UserRole.mechanic
              : UserRole.owner;
          return RegisterScreen(role: role);
        },
      ),
      // Owner shell
      GoRoute(
        path: '/owner',
        builder: (_, _) => const OwnerRoot(),
        routes: [
          GoRoute(
            path: 'vehicles/new',
            builder: (_, _) => const AddVehicleScreen(),
          ),
          GoRoute(
            path: 'vehicles/:id',
            builder: (ctx, st) => VehicleDetailScreen(
              vehicleId: st.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'services/pending',
            builder: (_, _) => const PendingServicesScreen(),
          ),
          GoRoute(
            path: 'services/:id',
            builder: (ctx, st) => ServiceDetailScreen(
              serviceId: st.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'find-mechanic',
            builder: (_, _) => const FindMechanicScreen(),
          ),
          GoRoute(
            path: 'sos',
            builder: (_, _) => const SosScreen(),
          ),
          GoRoute(
            path: 'mechanics/:id',
            builder: (ctx, st) => MechanicProfileScreen(
              mechanicId: st.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Mechanic shell
      GoRoute(
        path: '/mechanic',
        builder: (_, _) => const MechanicRoot(),
      ),

      // Shared
      GoRoute(
        path: '/services/:id',
        builder: (ctx, st) => ServiceDetailScreen(
          serviceId: st.pathParameters['id']!,
          showActions: false,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (_, _) => const CupertinoPageScaffold(
      child: Center(child: Text('Sahifa topilmadi')),
    ),
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}
