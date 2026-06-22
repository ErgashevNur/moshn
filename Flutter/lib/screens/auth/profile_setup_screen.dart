import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../models/service_type.dart';
import '../../models/user.dart';
import '../../services/api.dart';
import '../../services/shop_service.dart';
import '../../services/vehicle_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/m_button.dart';
import '../../widgets/plate_input.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final UserRole role;
  const ProfileSetupScreen({super.key, required this.role});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  // ─── Shared ──────────────────────────────────────────────
  final _fullNameCtrl = TextEditingController();
  String? _fullNameError;
  bool _loading = false;

  // ─── Owner ───────────────────────────────────────────────
  final _plateCtrl    = TextEditingController();
  final _makeCtrl     = TextEditingController();
  final _modelCtrl    = TextEditingController();
  String? _plateError;
  String? _makeError;

  // ─── Service wizard ───────────────────────────────────────
  final _pageCtrl      = PageController();
  int _currentStep     = 0;
  static const _totalSteps = 4;

  final _shopNameCtrl = TextEditingController();
  final _addressCtrl  = TextEditingController();
  String? _shopNameError;
  String? _addressError;

  // ─── Map / location ──────────────────────────────────────
  final _mapCtrl = MapController();
  double _lat = 41.2995; // Toshkent default
  double _lng = 69.2401;
  bool _locating  = false;
  bool _geocoding = false;
  Timer? _geocodeTimer;

  List<ServiceType> _serviceTypes = [];
  final Set<String> _selectedSlugs = {};
  bool _typesLoading = false;

  bool get _isOwner => widget.role == UserRole.owner;

  @override
  void initState() {
    super.initState();
    _plateCtrl.addListener(() {
      if (_plateError != null) setState(() => _plateError = null);
    });
    if (!_isOwner) _loadServiceTypes();
  }

  @override
  void dispose() {
    _geocodeTimer?.cancel();
    _mapCtrl.dispose();
    _fullNameCtrl.dispose();
    _plateCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _shopNameCtrl.dispose();
    _addressCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  // ─── Location helpers ─────────────────────────────────────

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
      _mapCtrl.move(LatLng(_lat, _lng), 16);
      _reverseGeocode(_lat, _lng);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    final center = camera.center;
    setState(() { _lat = center.latitude; _lng = center.longitude; });
    _geocodeTimer?.cancel();
    _geocodeTimer = Timer(const Duration(milliseconds: 700), () {
      _reverseGeocode(_lat, _lng);
    });
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _geocoding = true);
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isNotEmpty && mounted) {
        final p = marks.first;
        final parts = [
          if (p.street?.isNotEmpty == true) p.street,
          if (p.subLocality?.isNotEmpty == true) p.subLocality,
          if (p.locality?.isNotEmpty == true) p.locality,
        ];
        final addr = parts.join(', ');
        if (addr.isNotEmpty) _addressCtrl.text = addr;
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  Future<void> _loadServiceTypes() async {
    setState(() => _typesLoading = true);
    try {
      final types = await ShopService().getServiceTypes();
      if (mounted) setState(() { _serviceTypes = types; _typesLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _typesLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // OWNER
  // ═══════════════════════════════════════════════════════════

  bool _validateOwner() {
    final name  = _fullNameCtrl.text.trim();
    final plate = _plateCtrl.text.trim();
    final make  = _makeCtrl.text.trim();

    String? nameErr;
    String? plateErr;
    String? makeErr;

    if (name.isEmpty) {
      nameErr = 'Введите имя и фамилию';
    } else if (name.length < 5 || !name.contains(' ')) {
      nameErr = 'Введите имя и фамилию раздельно';
    } else {
      final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length < 2 || parts.any((p) => p.length < 2)) {
        nameErr = 'Имя и фамилия должны содержать минимум 2 буквы';
      }
    }

    if (plate.isEmpty) {
      plateErr = 'Введите государственный номер';
    } else if (plate.length < 4) {
      plateErr = 'Неверный формат (например: 01A123BC)';
    }

    if (make.isNotEmpty && make.length < 2) {
      makeErr = 'Введите минимум 2 буквы';
    }

    setState(() {
      _fullNameError = nameErr;
      _plateError    = plateErr;
      _makeError     = makeErr;
    });

    return nameErr == null && plateErr == null && makeErr == null;
  }

  Future<void> _submitOwner() async {
    if (!_validateOwner() || _loading) return;
    setState(() => _loading = true);

    try {
      final resp = await ApiClient.instance.dio.put('/profile/role', data: {
        'role': 'owner',
        'full_name': _fullNameCtrl.text.trim(),
      });
      final userData    = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;
      final updatedUser = User.fromJson(userData);
      ref.read(authProvider.notifier).setAuthenticated(updatedUser);

      try {
        await VehicleService().createVehicle(
          plate: _plateCtrl.text.trim().toUpperCase(),
          make:  _makeCtrl.text.trim(),
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
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Произошла ошибка. Попробуйте снова.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  String _vehicleErrMsg(Object e) {
    if (e is DioException) {
      if (e.response?.statusCode == 409) return 'Этот номер уже зарегистрирован';
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
      }
    }
    return 'Автомобиль не сохранён — добавьте из гаража';
  }

  // ═══════════════════════════════════════════════════════════
  // SERVICE WIZARD
  // ═══════════════════════════════════════════════════════════

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        final name = _fullNameCtrl.text.trim();
        if (name.isEmpty || name.length < 3) {
          setState(() => _fullNameError = 'Введите ваше имя');
          return false;
        }
        setState(() => _fullNameError = null);
        return true;

      case 1:
        final shop = _shopNameCtrl.text.trim();
        if (shop.isEmpty || shop.length < 2) {
          setState(() => _shopNameError = 'Введите название сервиса');
          return false;
        }
        setState(() => _shopNameError = null);
        return true;

      case 2:
        final addr = _addressCtrl.text.trim();
        if (addr.isEmpty || addr.length < 5) {
          setState(() => _addressError = 'Введите ваш адрес');
          return false;
        }
        setState(() => _addressError = null);
        return true;

      case 3:
        if (_selectedSlugs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Выберите хотя бы один тип услуги'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ));
          return false;
        }
        return true;

      default:
        return true;
    }
  }

  void _nextStep() {
    if (!_validateStep()) return;
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitService();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageCtrl.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitService() async {
    if (_loading) return;
    setState(() => _loading = true);

    try {
      // 1. Rol va ism saqlash — javobda yangi tokenlar keladi (role o'zgardi)
      final resp = await ApiClient.instance.dio.put('/profile/role', data: {
        'role': 'service',
        'full_name': _fullNameCtrl.text.trim(),
      });
      final payload = (resp.data['data'] ?? resp.data) as Map<String, dynamic>;

      // Yangi tokenlarni saqlash — ServiceRoleGuard uchun zarur
      final accessToken  = payload['access_token']  as String?;
      final refreshToken = payload['refresh_token'] as String?;
      if (accessToken != null && refreshToken != null) {
        await ApiClient.instance.saveTokens(access: accessToken, refresh: refreshToken);
      }

      final userMap     = (payload['user'] ?? payload) as Map<String, dynamic>;
      final updatedUser = User.fromJson(userMap);
      ref.read(authProvider.notifier).setAuthenticated(updatedUser);

      // 2. Shop profili yaratish (camelCase — backend bilan mos)
      await ShopService().createProfile({
        'shopName':     _shopNameCtrl.text.trim(),
        'address':      _addressCtrl.text.trim(),
        'serviceTypes': _selectedSlugs.toList(),
        'workingHours': '09:00-18:00',
        'latitude':     _lat,
        'longitude':    _lng,
      });

      // Router authenticated → /service ga redirect qiladi
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Произошла ошибка. Попробуйте снова.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: _isOwner ? _buildOwnerForm() : _buildServiceWizard(),
      ),
    );
  }

  // ─── Owner ───────────────────────────────────────────────

  Widget _buildOwnerForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              _BackButton(onTap: () => Navigator.of(context).pop()),
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
                  'Введите ваши данные',
                  style: AppTypography.displaySmall.copyWith(
                    color: AppColors.text(context), height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Данные профиля и автомобиля',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.text2(context)),
                ),
                const SizedBox(height: 32),

                _SectionLabel(icon: CupertinoIcons.person_fill, label: 'Личные данные'),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _fullNameCtrl,
                  placeholder: 'Имя Фамилия (Иван Иванов)',
                  icon: CupertinoIcons.person,
                  errorText: _fullNameError,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) {
                    if (_fullNameError != null) setState(() => _fullNameError = null);
                  },
                ),

                const SizedBox(height: 28),
                _SectionLabel(icon: CupertinoIcons.car_detailed, label: 'Данные автомобиля'),
                const SizedBox(height: 14),
                PlateInput(controller: _plateCtrl),
                if (_plateError != null) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(_plateError!,
                        style: AppTypography.labelSmall.copyWith(color: AppColors.danger)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _makeCtrl,
                        placeholder: 'Марка (Chevrolet)',
                        icon: CupertinoIcons.car,
                        errorText: _makeError,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (_) {
                          if (_makeError != null) setState(() => _makeError = null);
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
                    '* Госномер обязателен, марка и модель необязательны',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.text3(context)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: MButton(
            label: 'Подтвердить',
            onTap: _submitOwner,
            enabled: true,
            loading: _loading,
            trailing: const Icon(Icons.check_rounded),
          ),
        ),
      ],
    );
  }

  // ─── Service wizard ───────────────────────────────────────

  Widget _buildServiceWizard() {
    final isLast = _currentStep == _totalSteps - 1;
    return Column(
      children: [
        // Top bar: back + progress
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              _BackButton(onTap: _prevStep),
              const SizedBox(width: 16),
              Expanded(
                child: _StepIndicator(current: _currentStep, total: _totalSteps),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),

        // Pages
        Expanded(
          child: PageView(
            controller: _pageCtrl,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _stepName(),
              _stepShopName(),
              _stepAddress(),
              _stepServiceTypes(),
            ],
          ),
        ),

        // Bottom button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: MButton(
            label: isLast ? 'Завершить' : 'Продолжить',
            onTap: _nextStep,
            enabled: true,
            loading: _loading && isLast,
            trailing: Icon(isLast ? Icons.check_rounded : Icons.arrow_forward_rounded),
          ),
        ),
      ],
    );
  }

  // ─── Step 0: Usta ismi ────────────────────────────────────

  Widget _stepName() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Введите ваше имя',
              style: AppTypography.displaySmall.copyWith(
                  color: AppColors.text(context), height: 1.1)),
          const SizedBox(height: 8),
          Text('Имя мастера или руководителя',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.text2(context))),
          const SizedBox(height: 32),
          AppTextField(
            controller: _fullNameCtrl,
            placeholder: 'Имя Фамилия (Иван Иванов)',
            icon: CupertinoIcons.person,
            errorText: _fullNameError,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              if (_fullNameError != null) setState(() => _fullNameError = null);
            },
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Servis nomi ──────────────────────────────────

  Widget _stepShopName() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Введите название сервиса',
              style: AppTypography.displaySmall.copyWith(
                  color: AppColors.text(context), height: 1.1)),
          const SizedBox(height: 8),
          Text('Название мастерской для клиентов',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.text2(context))),
          const SizedBox(height: 32),
          AppTextField(
            controller: _shopNameCtrl,
            placeholder: 'Например: Shina24 Юнусабад',
            icon: CupertinoIcons.briefcase,
            errorText: _shopNameError,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_shopNameError != null) setState(() => _shopNameError = null);
            },
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Manzil (xarita) ─────────────────────────────

  Widget _stepAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Укажите местоположение',
                  style: AppTypography.titleLarge.copyWith(
                      color: AppColors.text(context), height: 1.1)),
              const SizedBox(height: 4),
              Text('Двигайте карту или нажмите «Моё место»',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text2(context))),
            ],
          ),
        ),

        // Map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapCtrl,
                options: MapOptions(
                  initialCenter: LatLng(_lat, _lng),
                  initialZoom: 15,
                  onPositionChanged: _onMapMoved,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'uz.moshn.moshn',
                  ),
                ],
              ),

              // Fixed center pin
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_pin,
                        size: 42, color: Color(0xFFE5382B)),
                    SizedBox(height: 21), // pin balandligi
                  ],
                ),
              ),

              // Geocoding indicator
              if (_geocoding)
                Positioned(
                  top: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: AppSpacing.shadow1,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text('Определяется адрес…',
                              style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.text2(context))),
                        ],
                      ),
                    ),
                  ),
                ),

              // My location button
              Positioned(
                bottom: 12,
                right: 14,
                child: GestureDetector(
                  onTap: _locating ? null : _goToMyLocation,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      shape: BoxShape.circle,
                      boxShadow: AppSpacing.shadow2,
                    ),
                    child: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2),
                          )
                        : Icon(Icons.my_location_rounded,
                            size: 22,
                            color: AppColors.text(context)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Address input
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: AppTextField(
            controller: _addressCtrl,
            placeholder: 'Улица, район, город',
            icon: CupertinoIcons.map_pin_ellipse,
            errorText: _addressError,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_addressError != null) setState(() => _addressError = null);
            },
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Xizmat turlari ───────────────────────────────

  Widget _stepServiceTypes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Выберите виды услуг',
              style: AppTypography.displaySmall.copyWith(
                  color: AppColors.text(context), height: 1.1)),
          const SizedBox(height: 8),
          Text('Отметьте услуги которые вы оказываете',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.text2(context))),
          const SizedBox(height: 24),

          if (_typesLoading)
            const Center(child: CircularProgressIndicator.adaptive())
          else if (_serviceTypes.isEmpty)
            Center(
              child: Column(
                children: [
                  Text('Виды услуг не загружены',
                      style: AppTypography.body.copyWith(color: AppColors.text2(context))),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadServiceTypes,
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _serviceTypes.map((type) {
                final selected = _selectedSlugs.contains(type.slug);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedSlugs.remove(type.slug);
                      } else {
                        _selectedSlugs.add(type.slug);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.inverseBg(context)
                          : AppColors.surface(context),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: selected
                            ? AppColors.inverseBg(context)
                            : AppColors.hairline(context),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (type.icon.isNotEmpty) ...[
                          Text(type.icon, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          type.nameUz,
                          style: AppTypography.labelMedium.copyWith(
                            color: selected
                                ? AppColors.inverseText(context)
                                : AppColors.text(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Icon(Icons.arrow_back_ios_new_rounded,
            size: 17, color: AppColors.text(context)),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < total - 1 ? 6 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.inverseBg(context)
                  : AppColors.hairline(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
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
