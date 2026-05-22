import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../models/vehicle.dart';
import '../../services/service_record_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

enum _RecState { idle, recording, processing }

class AddServiceScreen extends ConsumerStatefulWidget {
  const AddServiceScreen({super.key});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  final _recorder = AudioRecorder();
  _RecState _rec = _RecState.idle;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  final _vinOrPlate = TextEditingController();
  final _serviceType = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _mileage = TextEditingController();
  final _notes = TextEditingController();

  Vehicle? _vehicle;
  bool _looking = false;
  bool _saving = false;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _vinOrPlate.dispose();
    _serviceType.dispose();
    _description.dispose();
    _price.dispose();
    _mileage.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _lookupVehicle() async {
    final q = _vinOrPlate.text.trim();
    if (q.isEmpty) return;
    setState(() => _looking = true);
    try {
      final results = await VehicleService().searchByVinOrPlate(q);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _vehicle = null);
        _showError('mechanic.vehicle_not_found'.tr());
        return;
      }
      setState(() => _vehicle = results.first);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _looking = false);
    }
  }

  Future<void> _toggleRecord() async {
    if (_rec == _RecState.recording) {
      await _stopRecord();
      return;
    }
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      _showError('mechanic.mic_permission'.tr());
      return;
    }
    final dir = await path_provider.getTemporaryDirectory();
    final filePath =
        '${dir.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );
    setState(() {
      _rec = _RecState.recording;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stopRecord() async {
    _timer?.cancel();
    final path = await _recorder.stop();
    if (path == null) {
      setState(() => _rec = _RecState.idle);
      return;
    }
    setState(() => _rec = _RecState.processing);
    try {
      final parsed = await ServiceRecordService().parseVoice(path);
      setState(() {
        _description.text =
            (parsed['description'] ?? _description.text).toString();
        _serviceType.text =
            (parsed['service_type'] ?? _serviceType.text).toString();
        final price = parsed['price_uzs'] ?? parsed['price'];
        if (price != null) _price.text = price.toString();
        final km = parsed['mileage_km'] ?? parsed['mileage'];
        if (km != null) _mileage.text = km.toString();
        _rec = _RecState.idle;
      });
    } catch (e) {
      setState(() => _rec = _RecState.idle);
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _save() async {
    if (_vehicle == null) {
      _showError('mechanic.select_vehicle_first'.tr());
      return;
    }
    if (_serviceType.text.trim().isEmpty || _description.text.trim().isEmpty) {
      _showError('mechanic.fill_required'.tr());
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await ServiceRecordService().create({
        'vehicle_id': _vehicle!.id,
        'service_date':
            '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
        'service_type': _serviceType.text.trim(),
        'description': _description.text.trim(),
        if (_mileage.text.trim().isNotEmpty)
          'mileage_km': int.tryParse(_mileage.text.trim()),
        if (_price.text.trim().isNotEmpty)
          'price_uzs': int.tryParse(_price.text.trim()),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      });
      if (!mounted) return;
      _clear();
      _showInfo('common.success'.tr());
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _clear() {
    _vinOrPlate.clear();
    _serviceType.clear();
    _description.clear();
    _price.clear();
    _mileage.clear();
    _notes.clear();
    setState(() => _vehicle = null);
  }

  void _showError(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text('common.error'.tr()),
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showInfo(String msg) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(msg),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.ok'.tr()),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              border: null,
              largeTitle: Text('mechanic.add_service'.tr()),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _VoiceCard(
                    state: _rec,
                    elapsed: _formatDuration(_elapsed),
                    onTap: _toggleRecord,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _label('mechanic.find_vehicle'.tr()),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _vinOrPlate,
                          placeholder: 'mechanic.vin_or_plate'.tr(),
                          icon: CupertinoIcons.car_detailed,
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _lookupVehicle(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        height: AppSpacing.inputHeight,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          color: AppColors.primaryOf(context),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          onPressed: _looking ? null : _lookupVehicle,
                          child: _looking
                              ? CupertinoActivityIndicator(
                                  color: AppColors.onPrimaryOf(context))
                              : Icon(CupertinoIcons.search,
                                  color: AppColors.onPrimaryOf(context),
                                  size: 20),
                        ),
                      ),
                    ],
                  ),
                  if (_vehicle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _VehicleChip(vehicle: _vehicle!),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _label('mechanic.service_type'.tr()),
                  AppTextField(
                    controller: _serviceType,
                    placeholder: 'mechanic.service_type_hint'.tr(),
                    icon: CupertinoIcons.wrench,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _label('mechanic.service_description'.tr()),
                  AppTextField(
                    controller: _description,
                    placeholder: 'mechanic.service_description'.tr(),
                    maxLines: 4,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('mechanic.price'.tr()),
                            AppTextField(
                              controller: _price,
                              placeholder: '0',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('owner.mileage'.tr()),
                            AppTextField(
                              controller: _mileage,
                              placeholder: '0',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _label('mechanic.notes'.tr()),
                  AppTextField(
                    controller: _notes,
                    placeholder: 'mechanic.notes_hint'.tr(),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  PrimaryButton(
                    label: 'common.save'.tr(),
                    onPressed: _save,
                    loading: _saving,
                  ),
                  const SizedBox(height: AppSpacing.huge),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 4),
        child: Text(
          text,
          style:
              AppTypography.footnote.copyWith(color: AppColors.labelTertiary),
        ),
      );
}

class _VehicleChip extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleChip({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(CupertinoIcons.checkmark_seal_fill,
              color: AppColors.statusConfirmed, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.fullName, style: AppTypography.headline),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.plate} • ${vehicle.year}',
                  style: AppTypography.footnote
                      .copyWith(color: AppColors.labelTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceCard extends StatelessWidget {
  final _RecState state;
  final String elapsed;
  final VoidCallback onTap;

  const _VoiceCard({
    required this.state,
    required this.elapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRecording = state == _RecState.recording;
    final isProcessing = state == _RecState.processing;
    return SectionCard(
      onTap: isProcessing ? null : onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isRecording
                  ? AppColors.destructive.withValues(alpha: 0.15)
                  : AppColors.primaryOf(context).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: isProcessing
                ? const CupertinoActivityIndicator(radius: 20)
                : Icon(
                    isRecording
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.mic_fill,
                    size: 40,
                    color: isRecording
                        ? AppColors.destructive
                        : AppColors.primaryOf(context),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            isRecording
                ? 'mechanic.voice_recording'.tr()
                : isProcessing
                    ? 'mechanic.voice_processing'.tr()
                    : 'mechanic.voice_record'.tr(),
            style: AppTypography.headline,
          ),
          if (isRecording) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              elapsed,
              style: AppTypography.title3.copyWith(
                color: AppColors.destructive,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
