import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user.dart';
import '../models/vehicle.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/phone_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/owner/add_vehicle_scan_screen.dart';
import '../screens/owner/add_vehicle_screen.dart';
import '../screens/owner/booking_detail_screen.dart';
import '../screens/owner/create_booking_screen.dart';
import '../screens/owner/map_screen.dart';
import '../screens/owner/owner_root.dart';
import '../screens/owner/payment_screen.dart';
import '../screens/owner/search_screen.dart';
import '../screens/owner/book_service_screen.dart';
import '../screens/owner/service_group_screen.dart';
import '../screens/owner/shop_detail_screen.dart';
import '../screens/owner/sos_request_screen.dart';
import '../screens/owner/sos_tracking_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/wrong_app_screen.dart';
import '../store/auth_store.dart';
import 'router_refresh.dart';

/// PitGo (mijoz) ilovasining routeri — faqat `owner` roli qo'llab-quvvatlanadi.
/// Servis/usta/evakuator ekranlari bu build'da umuman import qilinmaydi
/// (PitGo Pro'da, `router_pro.dart`da).
final routerCustomerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: RouterRefresh(ref),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute = loc == '/' ||
          loc == '/onboarding' ||
          loc == '/phone' ||
          loc == '/otp' ||
          loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc == '/profile-setup' ||
          loc == '/wrong-app';

      if (auth.status == AuthStatus.initial) return null;

      if (auth.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/onboarding';
      }

      if (auth.status == AuthStatus.authenticated && isAuthRoute) {
        final role = auth.user?.role;
        if (role == UserRole.none || role == null) {
          // Rol tanlash ekrani yo'q (PitGo'da faqat "Mijoz" bor) — to'g'ridan
          // to'g'ri profil to'ldirishga o'tadi.
          if (loc == '/profile-setup') return null;
          return '/profile-setup';
        }
        if (role != UserRole.owner) {
          // Servis/usta/evakuator hisobi PitGo (mijoz) ilovasiga kirgan.
          if (loc == '/wrong-app') return null;
          return '/wrong-app';
        }
        return '/owner';
      }

      return null;
    },
    routes: [
      // Auth / Onboarding
      GoRoute(path: '/', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/phone', builder: (_, _) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (ctx, st) => OtpScreen(
          phone: st.uri.queryParameters['phone'] ?? '',
          initialDevCode: st.uri.queryParameters['dev_code'],
        ),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (_, st) {
          final role = (st.extra as UserRole?) ?? UserRole.owner;
          return ProfileSetupScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, st) => const RegisterScreen(role: UserRole.owner),
      ),
      GoRoute(path: '/wrong-app', builder: (_, _) => const WrongAppScreen()),

      // Owner shell
      GoRoute(
        path: '/owner',
        builder: (_, st) => OwnerRoot(
          initialTab: (st.extra as int?) ?? 0,
        ),
        routes: [
          GoRoute(path: 'map', builder: (_, _) => const MapScreen()),
          GoRoute(path: 'search', builder: (_, _) => const SearchScreen()),
          GoRoute(
            path: 'category/:id',
            builder: (ctx, st) => ServiceGroupScreen(categoryId: st.pathParameters['id']!),
          ),
          GoRoute(
            path: 'services/:slug',
            builder: (ctx, st) => BookServiceScreen(serviceSlug: st.pathParameters['slug']!),
          ),
          // Maket bo'yicha birinchi qadam — texpasport surati + asosiy
          // maydonlar. To'liq forma (rang, probeg, TO) "qo'lda kiritish"
          // havolasi ortida qoladi.
          GoRoute(path: 'vehicles/new', builder: (_, _) => const AddVehicleScanScreen()),
          GoRoute(path: 'vehicles/manual', builder: (_, _) => const AddVehicleScreen()),
          GoRoute(
            path: 'vehicles/edit',
            builder: (_, st) => AddVehicleScreen(vehicle: st.extra as Vehicle),
          ),
          GoRoute(
            path: 'shops/:id',
            builder: (ctx, st) => ShopDetailScreen(shopId: st.pathParameters['id']!),
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
            builder: (ctx, st) => BookingDetailScreen(bookingId: st.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'pay',
                builder: (ctx, st) {
                  final amount = int.tryParse(st.uri.queryParameters['amount'] ?? '0') ?? 0;
                  return PaymentScreen(bookingId: st.pathParameters['id']!, amount: amount);
                },
              ),
            ],
          ),
          GoRoute(path: 'sos', builder: (_, _) => const SosRequestScreen()),
          GoRoute(
            path: 'sos/:id',
            builder: (ctx, st) => SosTrackingScreen(sosId: st.pathParameters['id']!),
          ),
        ],
      ),

      // Shared
      GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
    errorBuilder: (context, _) => const Scaffold(
      body: Center(child: Text('Sahifa topilmadi')),
    ),
  );
});
