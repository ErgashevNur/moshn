import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user.dart';
import '../../services/vehicle_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController(text: '+998');
  final _email = TextEditingController();
  final _password = TextEditingController();
  // Необязательные данные автомобиля для владельца
  final _plate = TextEditingController();
  final _vehicleMake = TextEditingController();
  final _vehicleModel = TextEditingController();

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passError;

  bool get _isOwner => widget.role == UserRole.owner;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _plate.dispose();
    _vehicleMake.dispose();
    _vehicleModel.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ne = Validators.notEmpty(_name.text);
    final pe = Validators.phone(_phone.text);
    final ee = Validators.email(_email.text);
    final pwe = Validators.password(_password.text);
    setState(() {
      _nameError = ne == null ? null : 'auth.name_required'.tr();
      _phoneError = pe == null ? null : 'auth.$pe'.tr();
      _emailError = ee == null ? null : 'auth.$ee'.tr();
      _passError = pwe == null ? null : 'auth.$pwe'.tr();
    });
    if (ne != null || pe != null || ee != null || pwe != null) return;

    final ok = await ref.read(authProvider.notifier).register(
          phone: _phone.text.replaceAll(RegExp(r'\s'), ''),
          email: _email.text.trim(),
          password: _password.text,
          name: _name.text.trim(),
          role: widget.role,
        );
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(authProvider).error;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          title: Text('common.error'.tr()),
          content: Text(err ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('common.ok'.tr()),
            ),
          ],
        ),
      );
      return;
    }

    // Регистрация успешна — если это владелец и указан госномер, сохраняем автомобиль
    if (_isOwner && _plate.text.trim().isNotEmpty) {
      try {
        await VehicleService().createVehicle(
          plate: _plate.text.trim().toUpperCase(),
          make: _vehicleMake.text.trim(),
          model: _vehicleModel.text.trim(),
        );
      } catch (e) {
        // Ошибка сохранения авто не должна блокировать пользователя — можно добавить позже в гараже
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_vehicleErrMsg(e)),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
    // Router redirect handles navigation to /owner or /service on success.
  }

  String _vehicleErrMsg(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Ошибка подключения к серверу';
      }
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      }
      if (e.response?.statusCode == 409) {
        return 'Этот номер уже зарегистрирован';
      }
    }
    return 'Авто не сохранено — добавьте из гаража';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final roleLabel = widget.role == UserRole.service
        ? 'auth.role_service'.tr()
        : 'auth.role_owner'.tr();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ResponsiveContent(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.text(context), size: 17),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),
                      Text('auth.register'.tr(),
                          style: AppTypography.displayLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        roleLabel,
                        style: AppTypography.body
                            .copyWith(color: AppColors.inverseBg(context)),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      AppTextField(
                        controller: _name,
                        placeholder: 'auth.name_hint'.tr(),
                        icon: CupertinoIcons.person,
                        errorText: _nameError,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) => _nameError != null
                            ? setState(() => _nameError = null)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _phone,
                        placeholder: 'auth.phone_hint'.tr(),
                        icon: CupertinoIcons.phone,
                        keyboardType: TextInputType.phone,
                        errorText: _phoneError,
                        onChanged: (_) => _phoneError != null
                            ? setState(() => _phoneError = null)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _email,
                        placeholder: 'auth.email_hint'.tr(),
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (_) => _emailError != null
                            ? setState(() => _emailError = null)
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _password,
                        placeholder: 'auth.password'.tr(),
                        icon: CupertinoIcons.lock,
                        obscureText: true,
                        errorText: _passError,
                        onChanged: (_) => _passError != null
                            ? setState(() => _passError = null)
                            : null,
                      ),

                      // Раздел автомобиля для роли владельца
                      if (_isOwner) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        _SectionDivider(
                          label: 'Данные автомобиля (необязательно)',
                          icon: CupertinoIcons.car_detailed,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _plate,
                          placeholder: 'vehicle.plate_hint'.tr(),
                          icon: CupertinoIcons.creditcard,
                          textCapitalization: TextCapitalization.characters,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: _vehicleMake,
                                placeholder: 'vehicle.make_hint'.tr(),
                                icon: CupertinoIcons.car,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: AppTextField(
                                controller: _vehicleModel,
                                placeholder: 'vehicle.model_hint'.tr(),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xxl),
                      PrimaryButton(
                        label: 'auth.register'.tr(),
                        onPressed: _submit,
                        loading: auth.loading,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionDivider({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.text3(context)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.text3(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: AppColors.text3(context).withValues(alpha: 0.3),
            height: 1,
          ),
        ),
      ],
    );
  }
}
