import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../services/api.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/m_button.dart';

class RoleSelectScreen extends ConsumerStatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  ConsumerState<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends ConsumerState<RoleSelectScreen> {
  UserRole? _selected;
  bool _loading = false;
  String _error = '';
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selected == null || _loading) return;
    setState(() { _loading = true; _error = ''; });

    try {
      final body = <String, dynamic>{
        'role': _selected == UserRole.service ? 'service' : 'owner',
      };
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty) body['full_name'] = name;

      final resp = await ApiClient.instance.dio.put('/profile/role', data: body);
      final userData = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
      final updatedUser = User.fromJson(userData);
      ref.read(authProvider.notifier).setAuthenticated(updatedUser);
      if (!mounted) return;
      context.go(_selected == UserRole.service ? '/service' : '/owner');
    } catch (e) {
      setState(() {
        _error = 'common.error_retry'.tr();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'auth.role_select_title'.tr(),
                style: AppTypography.displaySmall.copyWith(
                  color: AppColors.text(context),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'auth.role_select_subtitle'.tr(),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.text2(context),
                ),
              ),
              const SizedBox(height: 28),

              // Ism maydoni
              AppTextField(
                controller: _nameCtrl,
                placeholder: 'auth.name_hint'.tr(),
                icon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),

              // Owner card
              _RoleCard(
                role: UserRole.owner,
                selected: _selected == UserRole.owner,
                icon: Icons.directions_car_rounded,
                title: 'auth.role_owner'.tr(),
                subtitle: 'auth.role_owner_sub'.tr(),
                onTap: () => setState(() => _selected = UserRole.owner),
              ),
              const SizedBox(height: 12),

              // Service card
              _RoleCard(
                role: UserRole.service,
                selected: _selected == UserRole.service,
                icon: Icons.tire_repair_rounded,
                title: 'auth.role_service'.tr(),
                subtitle: 'auth.role_service_sub'.tr(),
                onTap: () => setState(() => _selected = UserRole.service),
              ),

              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(_error,
                    style: AppTypography.body.copyWith(color: AppColors.danger)),
              ],

              const Spacer(),

              MButton(
                label: 'auth.continue_btn'.tr(),
                onTap: _selected != null ? _confirm : null,
                enabled: _selected != null,
                loading: _loading,
                trailing: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.inverseBg(context) : AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
          border: Border.all(
            color: selected ? AppColors.inverseBg(context) : AppColors.hairline(context),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.inverseText(context).withValues(alpha: 0.15)
                    : AppColors.surface2(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_md),
              ),
              child: Icon(
                icon,
                size: 26,
                color: selected
                    ? AppColors.inverseText(context)
                    : AppColors.text(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.soraSize(16, weight: FontWeight.w700)
                        .copyWith(
                      color: selected
                          ? AppColors.inverseText(context)
                          : AppColors.text(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.body.copyWith(
                      color: selected
                          ? AppColors.inverseText(context).withValues(alpha: 0.7)
                          : AppColors.text2(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.inverseText(context) : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.inverseText(context)
                      : AppColors.hairline2(context),
                  width: 2,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded,
                      size: 14, color: AppColors.inverseBg(context))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
