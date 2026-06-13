import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';

import '../../models/user.dart';
import '../../services/api.dart';
import '../../services/auth_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_brand_mark.dart';
import '../../widgets/m_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _len = 6;
  static const _resendSecs = 59;

  final _controllers = List.generate(_len, (_) => TextEditingController());
  final _nodes = List.generate(_len, (_) => FocusNode());

  bool _loading = false;
  String _error = '';
  int _countdown = _resendSecs;
  Timer? _timer;

  String _t(String uz, String ru) =>
      context.locale.languageCode == 'ru' ? ru : uz;

  String get _code => _controllers.map((c) => c.text).join();
  bool get _filled => _code.length == _len;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _nodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _nodes) { f.dispose(); }
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = _resendSecs);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  void _onInput(int index, String value) {
    final digit = value.replaceAll(RegExp(r'\D'), '');
    // Empty → user deleted the digit (Android soft keyboard backspace)
    if (digit.isEmpty) {
      _onBackspace(index);
      return;
    }
    final ch = digit[digit.length - 1];
    _controllers[index].text = ch;
    _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    setState(() {});
    if (index < _len - 1) {
      _nodes[index + 1].requestFocus();
    } else {
      _nodes[index].unfocus();
      Future.delayed(const Duration(milliseconds: 300), _submit);
    }
  }

  void _onBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
    } else {
      _controllers[index].clear();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_filled || _loading) return;
    setState(() { _loading = true; _error = ''; });
    try {
      final result = await AuthService().verifyOtp(
        phone: widget.phone,
        code: _code,
      );
      await ApiClient.instance.saveTokens(
        access: result.access,
        refresh: result.refresh,
      );
      ref.read(authProvider.notifier).setAuthenticated(result.user);
      if (!mounted) return;
      if (result.user.role == UserRole.none) {
        context.go('/role-select');
      } else {
        context.go(result.user.role == UserRole.service ? '/service' : '/owner');
      }
    } catch (e) {
      String msg;
      if (e is DioException &&
          (e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout)) {
        msg = 'auth.network_error'.tr();
      } else {
        msg = 'auth.otp_wrong'.tr();
      }
      setState(() {
        _error = msg;
        _loading = false;
      });
      for (final c in _controllers) {
        c.clear();
      }
      if (mounted) _nodes[0].requestFocus();
    }
  }

  Future<void> _resend() async {
    try { await AuthService().sendOtp(widget.phone); } catch (_) {}
    _startCountdown();
  }

  String _maskedPhone() {
    final p = widget.phone;
    if (p.length >= 12) {
      return '${p.substring(0, 6)} ${p.substring(6, 8)} *****${p.substring(p.length - 2)}';
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottom > 100;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      // keyboard overlays — content doesn't resize, just scrolls
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          // add bottom padding = keyboard height so content is reachable
          padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── top bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 0, top: 4),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/phone'),
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppColors.text(context), size: 20),
                      ),
                    ],
                  ),
                ),
              ),

              // ── brand mark (hide when keyboard open to save space) ──
              if (!keyboardOpen) ...[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.inverseBg(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: BrandMark(size: 28, color: AppColors.inverseText(context)),
                  ),
                ),
                const SizedBox(height: 22),
              ] else
                const SizedBox(height: 8),

              // ── title ────────────────────────────────────────────────
              Text(
                _t('Tasdiqlash kodi', 'Код подтверждения'),
                style: AppTypography.soraSize(keyboardOpen ? 22 : 26,
                        weight: FontWeight.w700)
                    .copyWith(color: AppColors.text(context), height: 1.1),
              ),
              const SizedBox(height: 8),

              // ── subtitle ─────────────────────────────────────────────
              RichText(
                text: TextSpan(
                  style: AppTypography.body.copyWith(color: AppColors.text2(context)),
                  children: [
                    TextSpan(text: _t('Kod yuborildi: ', 'Код отправлен: ')),
                    TextSpan(
                      text: _maskedPhone(),
                      style: AppTypography.body.copyWith(
                        color: AppColors.text(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: keyboardOpen ? 20 : 32),

              // ── OTP boxes ────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  _len,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _nodes[i],
                    onInput: (v) => _onInput(i, v),
                  ),
                ),
              ),

              // ── error ────────────────────────────────────────────────
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_error,
                    style: AppTypography.body.copyWith(color: AppColors.danger)),
              ],

              SizedBox(height: keyboardOpen ? 16 : 24),

              // ── resend ───────────────────────────────────────────────
              Center(
                child: _countdown > 0
                    ? Text(
                        '${_t('Qayta yuborish', 'Повторная отправка')} '
                        '0:${_countdown.toString().padLeft(2, '0')}',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.text3(context)),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: Text(
                          _t('Qayta yuborish', 'Отправить снова'),
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.text(context),
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.text(context),
                          ),
                        ),
                      ),
              ),

              SizedBox(height: keyboardOpen ? 20 : 32),

              // ── submit button ────────────────────────────────────────
              MButton(
                label: _t('Tasdiqlash', 'Подтвердить'),
                onTap: _filled ? _submit : null,
                enabled: _filled,
                loading: _loading,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── OTP box ────────────────────────────────────────────────────────────────

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onInput,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onInput;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final boxWidth = ((screenWidth - 48 - 40) / 6).clamp(40.0, 54.0);
    final boxHeight = boxWidth * 1.18;
    final filled = controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_sm),
        border: Border.all(
          color: focusNode.hasFocus
              ? AppColors.inverseBg(context)
              : filled
                  ? AppColors.hairline2(context)
                  : AppColors.hairline(context),
          width: focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppTypography.mono.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.text(context),
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: onInput,
      ),
    );
  }
}
