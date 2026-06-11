import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../utils/validators.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/responsive.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _emailError;
  String? _passError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ee = Validators.email(_email.text);
    final pwe = Validators.password(_password.text);
    setState(() {
      _emailError = ee == null ? null : 'auth.$ee'.tr();
      _passError = pwe == null ? null : 'auth.$pwe'.tr();
    });
    if (ee != null || pwe != null) return;

    final ok = await ref.read(authProvider.notifier).login(
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    if (!ok) {
      final err = ref.read(authProvider).error;
      _showError(err ?? 'auth.invalid_credentials'.tr());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface(ctx),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        title: Text('common.error'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
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
                      Text('auth.login'.tr(),
                          style: AppTypography.displayLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'auth.welcome_subtitle'.tr(),
                        style: AppTypography.body
                            .copyWith(color: AppColors.text3(context)),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      AppTextField(
                        controller: _email,
                        placeholder: 'auth.email_hint'.tr(),
                        icon: CupertinoIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        onChanged: (v) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _password,
                        placeholder: 'auth.password'.tr(),
                        icon: CupertinoIcons.lock,
                        obscureText: true,
                        errorText: _passError,
                        onChanged: (v) {
                          if (_passError != null) {
                            setState(() => _passError = null);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      PrimaryButton(
                        label: 'auth.login'.tr(),
                        onPressed: _submit,
                        loading: auth.loading,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: TextButton(
                          onPressed: () => context.push('/role'),
                          child: Text(
                            'auth.no_account'.tr(),
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.inverseBg(context),
                            ),
                          ),
                        ),
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
