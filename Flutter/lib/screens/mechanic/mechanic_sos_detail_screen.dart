import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sos_request.dart';
import '../../services/sos_service.dart';
import '../../services/ws_service.dart';
import '../../store/auth_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_button.dart';
import '../../widgets/m_plate.dart';
import '../../widgets/sos_chat.dart';

final _sosDetailProvider = FutureProvider.autoDispose.family<SosRequest, String>((ref, id) {
  return SosService().getStatus(id);
});

const _nextStatus = {
  'accepted': 'on_the_way',
  'on_the_way': 'arrived',
  'arrived': 'completed',
};

class MechanicSosDetailScreen extends ConsumerStatefulWidget {
  final String sosId;
  const MechanicSosDetailScreen({super.key, required this.sosId});

  @override
  ConsumerState<MechanicSosDetailScreen> createState() => _MechanicSosDetailScreenState();
}

class _MechanicSosDetailScreenState extends ConsumerState<MechanicSosDetailScreen> {
  StreamSubscription<WsEvent>? _wsSub;
  bool _advancing = false;
  final _priceCtrl = TextEditingController();
  bool _settingPrice = false;

  @override
  void initState() {
    super.initState();
    WsService.instance.connect();
    _wsSub = WsService.instance.events.listen(_onWsEvent);
  }

  Future<void> _submitPrice() async {
    final amount = int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('sos.price_invalid'.tr(), style: AppTypography.body.copyWith(color: Colors.white)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
      return;
    }
    setState(() => _settingPrice = true);
    try {
      await SosService().setPrice(widget.sosId, amount);
      ref.invalidate(_sosDetailProvider(widget.sosId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sosErrorMessage(e), style: AppTypography.body.copyWith(color: Colors.white)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    } finally {
      if (mounted) setState(() => _settingPrice = false);
    }
  }

  void _onWsEvent(WsEvent event) {
    if (!event.type.startsWith('sos_')) return;
    if (event.data['sosRequestId'] != widget.sosId) return;
    ref.invalidate(_sosDetailProvider(widget.sosId));
  }

  Future<void> _advance(String next) async {
    setState(() => _advancing = true);
    try {
      await SosService().updateStatus(widget.sosId, next);
      ref.invalidate(_sosDetailProvider(widget.sosId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sosErrorMessage(e), style: AppTypography.body.copyWith(color: Colors.white)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_sosDetailProvider(widget.sosId));
    final userId = ref.watch(authProvider).user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _appBar(context),
            Expanded(
              child: async.when(
                data: (request) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _CustomerCard(request: request),
                      const SizedBox(height: AppSpacing.xl),
                      if (request.status == 'completed') ...[
                        const _DoneBanner(),
                        const SizedBox(height: AppSpacing.lg),
                        _PaymentBox(
                          payment: request.payment,
                          controller: _priceCtrl,
                          submitting: _settingPrice,
                          onSubmit: _submitPrice,
                        ),
                      ] else if (request.status == 'cancelled')
                        const _CancelledBanner()
                      else ...[
                        MButton(
                          label: _labelForNext(_nextStatus[request.status]),
                          variant: MButtonVariant.danger,
                          loading: _advancing,
                          onTap: _nextStatus.containsKey(request.status) && !_advancing
                              ? () => _advance(_nextStatus[request.status]!)
                              : null,
                        ),
                      ],
                      if (request.status != 'cancelled') ...[
                        const SizedBox(height: AppSpacing.xl),
                        SosChat(sosRequestId: request.id, currentUserId: userId),
                      ],
                    ],
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => Center(
                  child: Text('common.error'.tr(), style: AppTypography.body.copyWith(color: AppColors.text3(context))),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _labelForNext(String? next) {
    switch (next) {
      case 'on_the_way':
        return 'sos.mark_on_the_way'.tr();
      case 'arrived':
        return 'sos.mark_arrived'.tr();
      case 'completed':
        return 'sos.mark_completed'.tr();
      default:
        return 'common.done'.tr();
    }
  }

  Widget _appBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppColors.surface(context), borderRadius: BorderRadius.circular(AppSpacing.r_xs)),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 17),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('SOS', style: AppTypography.appbarTitle.copyWith(color: AppColors.danger)),
        ],
      ),
    );
  }
}

Future<void> _callPhone(String phone) async {
  if (phone.isEmpty) return;
  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

class _CustomerCard extends StatelessWidget {
  final SosRequest request;
  const _CustomerCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.serviceType?.nameFor(locale) ?? 'sos.title'.tr(),
                  style: AppTypography.labelLarge.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w700),
                ),
              ),
              if (request.customerPhone.isNotEmpty)
                GestureDetector(
                  onTap: () => _callPhone(request.customerPhone),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    child: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (request.customerName.isNotEmpty)
            Row(
              children: [
                Icon(Icons.person_rounded, size: 14, color: AppColors.text3(context)),
                const SizedBox(width: 4),
                Text(request.customerName, style: AppTypography.body.copyWith(color: AppColors.text2(context), fontSize: 13)),
              ],
            ),
          if (request.vehiclePlate.isNotEmpty) ...[
            const SizedBox(height: 8),
            MPlate(plate: request.vehiclePlate),
          ],
        ],
      ),
    );
  }
}

class _DoneBanner extends StatelessWidget {
  const _DoneBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.successDim, borderRadius: BorderRadius.circular(AppSpacing.r_lg)),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, size: 36, color: AppColors.success),
          const SizedBox(height: AppSpacing.sm),
          Text('sos.status_completed'.tr(), style: AppTypography.titleMedium.copyWith(color: AppColors.text(context))),
        ],
      ),
    );
  }
}

class _PaymentBox extends StatelessWidget {
  final SosPayment? payment;
  final TextEditingController controller;
  final bool submitting;
  final VoidCallback onSubmit;
  const _PaymentBox({required this.payment, required this.controller, required this.submitting, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    if (payment == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('sos.price_title'.tr(),
                style: AppTypography.labelLarge.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('sos.price_subtitle'.tr(), style: AppTypography.body.copyWith(color: AppColors.text3(context), fontSize: 12.5)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: AppTypography.titleSmall.copyWith(color: AppColors.text(context)),
              decoration: InputDecoration(
                hintText: 'sos.price_hint'.tr(),
                hintStyle: AppTypography.body.copyWith(color: AppColors.text3(context)),
                filled: true,
                fillColor: AppColors.surface2(context),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.r_xs), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            MButton(
              label: 'sos.price_submit'.tr(),
              variant: MButtonVariant.danger,
              small: true,
              loading: submitting,
              onTap: submitting ? null : onSubmit,
            ),
          ],
        ),
      );
    }

    final paid = payment!.isPaid;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: paid ? AppColors.successDim : AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: paid ? null : Border.all(color: AppColors.hairline(context)),
      ),
      child: Row(
        children: [
          Icon(paid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
              color: paid ? AppColors.success : AppColors.text3(context), size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_fmtPrice(payment!.amount)} ${'common.sum'.tr()}',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w700)),
                Text(paid ? 'sos.price_paid'.tr() : 'sos.price_pending'.tr(),
                    style: AppTypography.body.copyWith(color: AppColors.text3(context), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtPrice(int price) {
    final s = price.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _CancelledBanner extends StatelessWidget {
  const _CancelledBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(color: AppColors.surface2(context), borderRadius: BorderRadius.circular(AppSpacing.r_lg)),
      child: Column(
        children: [
          Icon(Icons.block_rounded, size: 36, color: AppColors.text3(context)),
          const SizedBox(height: AppSpacing.sm),
          Text('sos.status_cancelled'.tr(), style: AppTypography.titleMedium.copyWith(color: AppColors.text(context))),
        ],
      ),
    );
  }
}
