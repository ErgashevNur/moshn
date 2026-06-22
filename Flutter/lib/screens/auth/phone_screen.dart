import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_brand_mark.dart';
import '../../widgets/m_button.dart';

// ---------------------------------------------------------------------------
// Phone number formatter — (XX) XXX-XX-XX
// ---------------------------------------------------------------------------

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 9; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (i == 5) buf.write('-');
      if (i == 7) buf.write('-');
      buf.write(digits[i]);
    }
    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String _error = '';

  String _t(String uz, String ru) =>
      context.locale.languageCode == 'ru' ? ru : uz;

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');

  bool get _canSubmit => _digits.length == 9 && !_loading;

  String _friendlyError(Object e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return _t('Serverga ulanib bo\'lmadi. Internet aloqasini tekshiring.',
            'Не удалось подключиться к серверу. Проверьте интернет-соединение.');
      }
      final msg = e.response?.data?['error'] as String? ??
          e.response?.data?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return _t('Xatolik yuz berdi. Qayta urinib ko\'ring.',
        'Произошла ошибка. Попробуйте ещё раз.');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    final phone = '+998$_digits';
    try {
      await AuthService().sendOtp(phone);
      if (mounted) {
        context.go('/otp?phone=${Uri.encodeComponent(phone)}');
      }
    } catch (e) {
      setState(() {
        _error = _friendlyError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/onboarding'),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.text(context),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  _LangToggle(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Brand mark — inverseBg circle with tire icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.inverseBg(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: BrandMark(
                          size: 32,
                          color: AppColors.inverseText(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    Text(
                      _t('Telefon raqamingiz', 'Ваш номер телефона'),
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.text(context),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      _t(
                        'Kirish uchun SMS-kod yuboramiz',
                        'Отправим SMS-код для входа',
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.text2(context),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Phone input row
                    Row(
                      children: [
                        // +998 prefix box
                        Container(
                          width: 92,
                          height: AppSpacing.inputHeight,
                          decoration: BoxDecoration(
                            color: AppColors.surface(context),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.r_md),
                            border:
                                Border.all(color: AppColors.hairline(context)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+998',
                            style: AppTypography.mono.copyWith(
                              color: AppColors.text(context),
                              fontSize: 17,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Number input
                        Expanded(
                          child: SizedBox(
                            height: AppSpacing.inputHeight,
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [_PhoneFormatter()],
                              textAlignVertical: TextAlignVertical.center,
                              style: AppTypography.mono.copyWith(
                                color: AppColors.text(context),
                                fontSize: 17,
                              ),
                              decoration: InputDecoration(
                                hintText: '(__) ___-__-__',
                                hintStyle: AppTypography.mono.copyWith(
                                  color: AppColors.text3(context),
                                  fontSize: 17,
                                ),
                                filled: true,
                                fillColor: AppColors.surface(context),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.r_md),
                                  borderSide: BorderSide(
                                      color: AppColors.hairline(context)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.r_md),
                                  borderSide: BorderSide(
                                      color: AppColors.hairline(context)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.r_md),
                                  borderSide: BorderSide(
                                    color: AppColors.inverseBg(context),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Error
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error,
                        style:
                            AppTypography.body.copyWith(color: AppColors.danger),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // Submit
                    MButton(
                      label: _t('Kod yuborish', 'Отправить код'),
                      onTap: _canSubmit ? _submit : null,
                      loading: _loading,
                      enabled: _canSubmit,
                    ),

                    const SizedBox(height: 20),

                    // Fine print
                    Center(
                      child: Text(
                        _t(
                          'Davom etish orqali siz foydalanish shartlariga rozilik bildirasiz',
                          'Продолжая, вы соглашаетесь с условиями использования',
                        ),
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: AppColors.text3(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language toggle (shared with onboarding style)
// ---------------------------------------------------------------------------

class _LangToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface2(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['uz', 'ru'].map((l) {
          final active = lang == l;
          return GestureDetector(
            onTap: () => context.setLocale(Locale(l)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.bgElevated(context)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.r_full),
                boxShadow: active ? AppSpacing.shadow1 : null,
              ),
              child: Text(
                l == 'uz' ? "O'z" : 'Ру',
                style:
                    AppTypography.soraSize(12.5, weight: FontWeight.w600)
                        .copyWith(
                  color: active
                      ? AppColors.text(context)
                      : AppColors.text2(context),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
