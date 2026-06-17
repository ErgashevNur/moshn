import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/phone_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_select_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/owner/add_vehicle_screen.dart';
import '../screens/owner/booking_detail_screen.dart';
import '../screens/owner/create_booking_screen.dart';
import '../screens/owner/map_screen.dart';
import '../screens/owner/owner_root.dart';
import '../screens/owner/payment_screen.dart';
import '../screens/owner/service_category_screen.dart';
import '../screens/owner/shop_detail_screen.dart';
import '../screens/service/customer_card_screen.dart';
import '../screens/service/service_booking_detail_screen.dart';
import '../screens/service/service_root.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../store/auth_store.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/' ||
          loc == '/onboarding' ||
          loc == '/phone' ||
          loc == '/otp' ||
          loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/role') ||
          loc == '/role-select' ||
          loc == '/profile-setup';

      if (auth.status == AuthStatus.initial) return null;

      if (auth.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/onboarding';
      }

      if (auth.status == AuthStatus.authenticated && isAuthRoute) {
        final role = auth.user?.role;
        if (role == UserRole.none || role == null) {
          // role-select va profile-setup ekranlarida qolsin — redirect qilma
          if (loc == '/role-select' || loc == '/profile-setup') return null;
          return '/role-select';
        }
        return role == UserRole.service ? '/service' : '/owner';
      }

      return null;
    },
    routes: [
      // Auth / Onboarding
      GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/phone', builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (ctx, st) =>
            OtpScreen(phone: st.uri.queryParameters['phone'] ?? ''),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/role', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(path: '/role-select', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (_, st) {
          final role = (st.extra as UserRole?) ?? UserRole.owner;
          return ProfileSetupScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, st) {
          final role = st.uri.queryParameters['role'] == 'service'
              ? UserRole.service
              : UserRole.owner;
          return RegisterScreen(role: role);
        },
      ),

      // Owner shell
      GoRoute(
        path: '/owner',
        builder: (_, st) => OwnerRoot(
          initialTab: (st.extra as int?) ?? 0,
        ),
        routes: [
          GoRoute(
            path: 'map',
            builder: (_, _) => const MapScreen(),
          ),
          GoRoute(
            path: 'services/:slug',
            builder: (ctx, st) => ServiceCategoryScreen(
              slug: st.pathParameters['slug']!,
            ),
          ),
          GoRoute(
            path: 'vehicles/new',
            builder: (_, _) => const AddVehicleScreen(),
          ),
          GoRoute(
            path: 'shops/:id',
            builder: (ctx, st) => ShopDetailScreen(
              shopId: st.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'book',
                builder: (ctx, st) {
                  final shopId = st.pathParameters['id']!;
                  final extra = st.extra as Map<String, dynamic>? ?? {};
                  return CreateBookingScreen(
                    shopId: shopId,
                    shopName: extra['name'] as String? ?? '',
                    shopAddress: extra['address'] as String? ?? '',
                    isVerified: extra['isVerified'] as bool? ?? false,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'bookings/:id',
            builder: (ctx, st) => BookingDetailScreen(
              bookingId: st.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'pay',
                builder: (ctx, st) {
                  final amount = int.tryParse(
                          st.uri.queryParameters['amount'] ?? '0') ??
                      0;
                  return PaymentScreen(
                    bookingId: st.pathParameters['id']!,
                    amount: amount,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      // Service shell
      GoRoute(
        path: '/service',
        builder: (_, _) => const ServiceRoot(),
        routes: [
          GoRoute(
            path: 'bookings/:id',
            builder: (ctx, st) => ServiceBookingDetailScreen(
              bookingId: st.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'customers/:id',
            builder: (ctx, st) => CustomerCardScreen(
              customerId: st.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Shared
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, _) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, _) => Scaffold(
      body: Center(child: Text('common.page_not_found'.tr())),
    ),
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this.ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}
