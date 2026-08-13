import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../store/auth_store.dart';

/// `GoRouter`ning `refreshListenable`i — auth holati o'zgarsa (login/logout,
/// rol o'zgarishi) routerning `redirect` funksiyasini qayta ishga tushiradi.
/// Ikkala flavor (customer/pro) uchun bir xil, shuning uchun umumiy fayl.
class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this.ref) {
    ref.listen<AuthState>(authProvider, (_, _) => notifyListeners());
  }
  final Ref ref;
}
