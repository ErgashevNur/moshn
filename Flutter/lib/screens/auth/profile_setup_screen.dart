import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user.dart';
import '../../services/api.dart';
import '../../services/vehicle_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/m_button.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const ProfileSetupScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _fullNameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  String? _fullNameError;
  String? _plateError;
  String? _makeError;
  bool _loading = false;

  bool get _isOwner => widget.role == UserRole.owner;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  // ─── Validatsiya ──────────────────────────────────────────
  bool _validate() {
    final name = _fullNameCtrl.text.trim();
    final plate = _plateCtrl.text.trim();
    final make = _makeCtrl.text.trim();

    String? nameErr;
    String? plateErr;
    String? makeErr;

    // Ism Familiya
    if (name.isEmpty) {
      nameErr = 'Ism Familiyani kiriting';
    } else if (name.length < 5) {
      nameErr = 'Kamida 5 ta harf kiriting';
    } else if (!name.contains(' ')) {
      nameErr = 'Ism va Familiya alohida kiriting';
    } else {
      final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length < 2 || parts.any((p) => p.length < 2)) {
        nameErr = 'Ism va Familiya kamida 2 ta harfdan iborat bo\'lsin';
      }
    }

    // Owner uchun mashina
    if (_isOwner) {
      if (plate.isEmpty) {
        plateErr = 'Davlat raqamini kiriting';
      } else if (plate.length < 4) {
        plateErr = 'Noto\'g\'ri format (masalan: 01A123BC)';
      }

      if (make.isNotEmpty && make.length < 2) {
        makeErr = 'Kamida 2 ta harf kiriting';
      }
    }

    setState(() {
      _fullNameError = nameErr;
      _plateError = plateErr;
      _makeError = makeErr;
    });

    return nameErr == null && plateErr == null && makeErr == null;
  }

  Future<void> _submit() async {
    if (!_validate() || _loading) return;

    setState(() => _loading = true);

    try {
      // 1. Rol va ismni saqlash
      final resp = await ApiClient.instance.dio.put('/profile/role', data: {
        'role': _isOwner ? 'owner' : 'service',
        'full_name': _fullNameCtrl.text.trim(),
      });

      final userData = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
      final updatedUser = User.fromJson(userData);
      ref.read(authProvider.notifier).setAuthenticated(updatedUser);

      // 2. Owner bo'lsa mashina saqlash
      if (_isOwner) {
        try {
          await VehicleService().createVehicle(
            plate: _plateCtrl.text.trim().toUpperCase(),
            make: _makeCtrl.text.trim(),
            model: _modelCtrl.text.trim(),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_vehicleErrMsg(e)),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }

      // Router authProvider o'zgarishidan /owner yoki /service ga redirect qiladi
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Xatolik yuz berdi. Qayta urinib ko\'ring.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _vehicleErrMsg(Object e) {
    if (e is DioException) {
      if (e.response?.statusCode == 409) {
        return 'Bu davlat raqami allaqachon ro\'yxatda';
      }
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      }
    }
    return 'Mashina saqlanmadi — garajdan qo\'shib oling';
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _isOwner;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 17, color: AppColors.text(context)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOwner ? 'Ma\'lumotlaringizni kiriting' : 'Ismingizni kiriting',
                      style: AppTypography.displaySmall.copyWith(
                        color: AppColors.text(context),
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isOwner
                          ? 'Profil va mashina ma\'lumotlari'
                          : 'Servis profili uchun ismingiz',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.text2(context),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Shaxsiy ma'lumotlar ──────────────────
                    _SectionLabel(
                      icon: CupertinoIcons.person_fill,
                      label: 'Shaxsiy ma\'lumotlar',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _fullNameCtrl,
                      placeholder: 'Ism Familiya  (Ali Valiyev)',
                      icon: CupertinoIcons.person,
                      errorText: _fullNameError,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) {
                        if (_fullNameError != null) {
                          setState(() => _fullNameError = null);
                        }
                      },
                    ),

                    // ── Owner: mashina ma'lumotlari ──────────
                    if (isOwner) ...[
                      const SizedBox(height: 28),
                      _SectionLabel(
                        icon: CupertinoIcons.car_detailed,
                        label: 'Mashina ma\'lumotlari',
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _plateCtrl,
                        placeholder: 'Davlat raqami  (01A123BC)',
                        icon: CupertinoIcons.creditcard,
                        errorText: _plateError,
                        textCapitalization: TextCapitalization.characters,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9]')),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onChanged: (_) {
                          if (_plateError != null) {
                            setState(() => _plateError = null);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _makeCtrl,
                              placeholder: 'Marka  (Chevrolet)',
                              icon: CupertinoIcons.car,
                              errorText: _makeError,
                              textCapitalization: TextCapitalization.words,
                              onChanged: (_) {
                                if (_makeError != null) {
                                  setState(() => _makeError = null);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _modelCtrl,
                              placeholder: 'Model  (Cobalt)',
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '* Davlat raqami majburiy, marka va model ixtiyoriy',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.text3(context),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Tasdiqlash tugmasi
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: MButton(
                label: 'Tasdiqlash',
                onTap: _submit,
                enabled: true,
                loading: _loading,
                trailing: const Icon(Icons.check_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.text3(context)),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.text3(context),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Divider(
            color: AppColors.text3(context).withValues(alpha: 0.25),
            height: 1,
          ),
        ),
      ],
    );
  }
}
