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
import '../screens/evacuator/evacuator_root.dart';
import '../screens/mechanic/mechanic_root.dart';
import '../screens/mechanic/mechanic_sos_detail_screen.dart';
import '../screens/service/customer_card_screen.dart';
import '../screens/service/service_booking_detail_screen.dart';
import '../screens/service/service_root.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/profile_screen.dart';
import '../screens/shared/wrong_app_screen.dart';
import '../store/auth_store.dart';
import 'router_refresh.dart';

/// PitGo Pro ilovasining routeri — faqat `service`/`master`/`evacuator`
/// rollari qo'llab-quvvatlanadi. Mijoz (owner) ekranlari bu build'ga
/// umuman kirmaydi (PitGo'da, `router_customer.dart`da).
final routerProProvider = Provider<GoRouter>((ref) {
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
          loc.startsWith('/role') ||
          loc == '/role-select' ||
          loc == '/profile-setup' ||
          loc == '/wrong-app';

      if (auth.status == AuthStatus.initial) return null;

      if (auth.status == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/onboarding';
      }

      if (auth.status == AuthStatus.authenticated && isAuthRoute) {
        final role = auth.user?.role;
        if (role == UserRole.none || role == null) {
          if (loc == '/role-select' || loc == '/profile-setup') return null;
          return '/role-select';
        }
        // Servis egasi ustalar qo'shish qadamini davom ettirsin.
        if (role == UserRole.service && loc == '/profile-setup') return null;
        switch (role) {
          case UserRole.service:
            return '/service';
          case UserRole.master:
            return '/mechanic';
          case UserRole.evacuator:
            return '/evacuator';
          default:
            // Mijoz (owner) hisobi PitGo Pro ilovasiga kirgan.
            if (loc == '/wrong-app') return null;
            return '/wrong-app';
        }
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
      GoRoute(path: '/role', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(path: '/role-select', builder: (_, _) => const RoleSelectScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (_, st) {
          final role = (st.extra as UserRole?) ?? UserRole.service;
          return ProfileSetupScreen(role: role);
        },
      ),
      GoRoute(
        path: '/register',
        builder: (ctx, st) => const RegisterScreen(role: UserRole.service),
      ),
      GoRoute(path: '/wrong-app', builder: (_, _) => const WrongAppScreen()),

      // Service shell
      GoRoute(
        path: '/service',
        builder: (_, _) => const ServiceRoot(),
        routes: [
          GoRoute(
            path: 'bookings/:id',
            builder: (ctx, st) => ServiceBookingDetailScreen(bookingId: st.pathParameters['id']!),
          ),
          GoRoute(
            path: 'customers/:id',
            builder: (ctx, st) => CustomerCardScreen(customerId: st.pathParameters['id']!),
          ),
        ],
      ),

      // Mechanic (usta) shell
      GoRoute(
        path: '/mechanic',
        builder: (_, _) => const MechanicRoot(),
        routes: [
          GoRoute(
            path: 'sos/:id',
            builder: (ctx, st) => MechanicSosDetailScreen(sosId: st.pathParameters['id']!),
          ),
          // Usta ham bronni ochib, bosqichlarni siljitadi va qo'shimcha
          // ish taklif qiladi. Ekran servis egasinikiga o'xshash, faqat
          // tasdiqlash/yakunlash tugmalarisiz (`asMaster`).
          GoRoute(
            path: 'bookings/:id',
            builder: (ctx, st) => ServiceBookingDetailScreen(
              bookingId: st.pathParameters['id']!,
              asMaster: true,
            ),
          ),
        ],
      ),

      // Evakuator shell
      GoRoute(
        path: '/evacuator',
        builder: (_, _) => const EvacuatorRoot(),
        routes: [
          GoRoute(
            path: 'sos/:id',
            builder: (ctx, st) => MechanicSosDetailScreen(sosId: st.pathParameters['id']!),
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
