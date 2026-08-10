import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/sos_request.dart';
import '../../store/auth_store.dart';
import '../../store/sos_store.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_button.dart';
import '../../widgets/sos_chat.dart';

class SosTrackingScreen extends ConsumerStatefulWidget {
  final String sosId;
  const SosTrackingScreen({super.key, required this.sosId});

  @override
  ConsumerState<SosTrackingScreen> createState() => _SosTrackingScreenState();
}

class _SosTrackingScreenState extends ConsumerState<SosTrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sosProvider.notifier).loadExisting(widget.sosId);
    });
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialogLike(
        title: 'sos.cancel_confirm_title'.tr(),
        message: 'sos.cancel_confirm_body'.tr(),
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true) return;
    await ref.read(sosProvider.notifier).cancel();
  }

  Future<void> _callEvacuator() async {
    final ok = await ref.read(sosProvider.notifier).requestEvacuator();
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ref.read(sosProvider).error ?? 'common.error'.tr(),
          style: AppTypography.body.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  Future<void> _confirmPayment() async {
    final ok = await ref.read(sosProvider.notifier).confirmPayment();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'sos.payment_paid'.tr() : (ref.read(sosProvider).error ?? 'common.error'.tr()),
          style: AppTypography.body.copyWith(color: Colors.white),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  Future<bool> _addTip(int amount) async {
    final ok = await ref.read(sosProvider.notifier).addTip(amount);
    if (!mounted) return ok;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'payment.tip_sent'.tr() : 'common.error'.tr(),
          style: AppTypography.body.copyWith(color: Colors.white),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
    return ok;
  }

  Future<void> _requestSupport() async {
    final ok = await ref.read(sosProvider.notifier).requestSupport();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'sos.support_sent'.tr() : 'common.error'.tr(),
          style: AppTypography.body.copyWith(color: Colors.white),
        ),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _closeAndReset() {
    ref.read(sosProvider.notifier).reset();
    context.go('/owner');
  }

  @override
  Widget build(BuildContext context) {
    final sosState = ref.watch(sosProvider);
    final request = sosState.request;
    final userId = ref.watch(authProvider).user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: request == null
            ? Center(
                child: sosState.loading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : _ErrorRetry(
                        message: sosState.error ?? 'common.error'.tr(),
                        onRetry: () => ref.read(sosProvider.notifier).loadExisting(widget.sosId),
                      ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (request.isWaiting) _WaitingCard(request: request),
                    if (request.isNoMasterFound)
                      _NoMasterCard(onCallEvacuator: _callEvacuator, onGiveUp: _closeAndReset),
                    if (request.isNoEvacuatorFound)
                      _SimpleStatusCard(
                        icon: Icons.report_gmailerrorred_rounded,
                        color: AppColors.text3(context),
                        title: 'sos.no_evacuator_title'.tr(),
                        subtitle: 'sos.no_evacuator_body'.tr(),
                      ),
                    if (request.isCancelled) _SimpleStatusCard(
                      icon: Icons.block_rounded,
                      color: AppColors.text3(context),
                      title: 'sos.status_cancelled'.tr(),
                    ),
                    if (request.hasMaster || request.hasEvacuator) ...[
                      request.hasMaster
                          ? _MasterCard(request: request)
                          : _EvacuatorCard(request: request),
                      const SizedBox(height: AppSpacing.lg),
                      _StatusSteps(status: request.status),
                    ],
                    if (request.isCompleted) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _SimpleStatusCard(
                        icon: Icons.check_circle_rounded,
                        color: AppColors.success,
                        title: 'sos.status_completed'.tr(),
                      ),
                    ],
                    if (request.payment != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _PaymentCard(
                        payment: request.payment!,
                        onConfirm: _confirmPayment,
                        onTip: _addTip,
                      ),
                    ],
                    if (request.chatOpen) ...[
                      const SizedBox(height: AppSpacing.xl),
                      SosChat(sosRequestId: request.id, currentUserId: userId),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    if (request.isWaiting) ...[
                      MButton(
                        label: 'sos.cancel_button'.tr(),
                        variant: MButtonVariant.outline,
                        onTap: _cancel,
                      ),
                    ] else if (request.canCancel && request.hasAcceptedActor) ...[
                      MButton(
                        label: 'sos.cancel_button'.tr(),
                        variant: MButtonVariant.outline,
                        onTap: _cancel,
                      ),
                    ] else if (!request.isActive &&
                        !request.isNoMasterFound &&
                        (request.payment == null || request.payment!.isPaid)) ...[
                      MButton(
                        label: 'common.done'.tr(),
                        variant: MButtonVariant.primary,
                        onTap: _closeAndReset,
                      ),
                    ],
                    if (!request.isCompleted && !request.isCancelled) ...[
                      const SizedBox(height: AppSpacing.md),
                      Center(
                        child: GestureDetector(
                          onTap: _requestSupport,
                          child: Text(
                            'sos.dont_know_button'.tr(),
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.text2(context),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

Future<void> _callPhone(String phone) async {
  if (phone.isEmpty) return;
  final uri = Uri.parse('tel:$phone');
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

class _WaitingCard extends StatelessWidget {
  final SosRequest request;
  const _WaitingCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final count = request.dispatchedTargetCount;
    final titleKey = request.isEvacuatorMode ? 'sos.searching_evacuator_title' : 'sos.searching_title';
    final bodyKey = request.isEvacuatorMode ? 'sos.searching_evacuator_body' : 'sos.searching_body';
    final bodyZeroKey =
        request.isEvacuatorMode ? 'sos.searching_evacuator_body_zero' : 'sos.searching_body_zero';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.dangerDim,
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.danger),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            titleKey.tr(),
            style: AppTypography.titleMedium.copyWith(color: AppColors.text(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            count > 0 ? bodyKey.tr(namedArgs: {'count': '$count'}) : bodyZeroKey.tr(),
            style: AppTypography.body.copyWith(color: AppColors.text2(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoMasterCard extends StatelessWidget {
  final VoidCallback onCallEvacuator;
  final VoidCallback onGiveUp;
  const _NoMasterCard({required this.onCallEvacuator, required this.onGiveUp});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_lg),
            border: Border.all(color: AppColors.hairline(context)),
          ),
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 40, color: AppColors.text3(context)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'sos.no_master_title'.tr(),
                style: AppTypography.titleMedium.copyWith(color: AppColors.text(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'sos.no_master_body'.tr(),
                style: AppTypography.body.copyWith(color: AppColors.text2(context)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        MButton(
          label: 'sos.call_evacuator_button'.tr(),
          variant: MButtonVariant.primary,
          onTap: onCallEvacuator,
        ),
        const SizedBox(height: AppSpacing.sm),
        MButton(
          label: 'sos.give_up_button'.tr(),
          variant: MButtonVariant.outline,
          onTap: onGiveUp,
        ),
      ],
    );
  }
}

class _SimpleStatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  const _SimpleStatusCard({required this.icon, required this.color, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.titleMedium.copyWith(color: AppColors.text(context)), textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle!, style: AppTypography.body.copyWith(color: AppColors.text2(context)), textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

class _MasterCard extends StatelessWidget {
  final SosRequest request;
  const _MasterCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final master = request.acceptedMaster;
    if (master == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.surface3(context),
            child: Text(
              master.fullName.isNotEmpty ? master.fullName[0].toUpperCase() : '?',
              style: AppTypography.titleMedium.copyWith(color: AppColors.text(context)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(master.fullName,
                    style: AppTypography.labelLarge.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(master.shopName,
                    style: AppTypography.body.copyWith(color: AppColors.text2(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (master.ratingAvg > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 2),
                      Text(master.ratingAvg.toStringAsFixed(1),
                          style: AppTypography.labelSmall.copyWith(color: AppColors.text2(context))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (master.shopPhone.isNotEmpty)
            GestureDetector(
              onTap: () => _callPhone(master.shopPhone),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class _EvacuatorCard extends StatelessWidget {
  final SosRequest request;
  const _EvacuatorCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final evacuator = request.acceptedEvacuator;
    if (evacuator == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.surface3(context),
            child: const Icon(Icons.local_shipping_rounded, color: AppColors.danger, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evacuator.fullName,
                    style: AppTypography.labelLarge.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                if (evacuator.vehiclePlate.isNotEmpty)
                  Text(evacuator.vehiclePlate,
                      style: AppTypography.body.copyWith(color: AppColors.text2(context)), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (evacuator.ratingAvg > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 2),
                      Text(evacuator.ratingAvg.toStringAsFixed(1),
                          style: AppTypography.labelSmall.copyWith(color: AppColors.text2(context))),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (evacuator.phone.isNotEmpty)
            GestureDetector(
              onTap: () => _callPhone(evacuator.phone),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                child: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatefulWidget {
  final SosPayment payment;
  final Future<void> Function() onConfirm;
  final Future<bool> Function(int amount) onTip;
  const _PaymentCard({required this.payment, required this.onConfirm, required this.onTip});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _confirming = false;
  bool _tipSent = false;
  int? _tippingAmount;

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    await widget.onConfirm();
    if (mounted) setState(() => _confirming = false);
  }

  Future<void> _tip(int amount) async {
    setState(() => _tippingAmount = amount);
    final ok = await widget.onTip(amount);
    if (!mounted) return;
    setState(() {
      _tippingAmount = null;
      if (ok) _tipSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final paid = widget.payment.isPaid;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.r_lg),
        border: Border.all(color: AppColors.hairline(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(paid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                  color: paid ? AppColors.success : AppColors.text(context), size: 22),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('sos.payment_title'.tr(),
                    style: AppTypography.labelLarge.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w700)),
              ),
              Text('${_fmtPrice(widget.payment.amount)} ${'common.sum'.tr()}',
                  style: AppTypography.titleSmall.copyWith(color: AppColors.text(context))),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(paid ? 'sos.payment_paid_body'.tr() : 'sos.payment_pending_body'.tr(),
              style: AppTypography.body.copyWith(color: AppColors.text2(context), fontSize: 13)),
          if (!paid) ...[
            const SizedBox(height: AppSpacing.md),
            MButton(
              label: 'sos.pay_button'.tr(),
              variant: MButtonVariant.primary,
              small: true,
              loading: _confirming,
              onTap: _confirming ? null : _confirm,
            ),
          ],
          if (!_tipSent) ...[
            const SizedBox(height: AppSpacing.lg),
            Divider(height: 1, color: AppColors.hairline(context)),
            const SizedBox(height: AppSpacing.md),
            Text('payment.tip_title'.tr(),
                style: AppTypography.labelMedium.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('payment.tip_sub'.tr(), style: AppTypography.body.copyWith(color: AppColors.text3(context), fontSize: 12)),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [10000, 20000, 50000].map((amount) {
                final busy = _tippingAmount == amount;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: _tippingAmount != null ? null : () => _tip(amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface2(context),
                        borderRadius: BorderRadius.circular(AppSpacing.r_full),
                        border: Border.all(color: AppColors.hairline(context)),
                      ),
                      child: busy
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text2(context)),
                            )
                          : Text('${amount ~/ 1000}k', style: AppTypography.labelSmall.copyWith(color: AppColors.text2(context))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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

class _StatusSteps extends StatelessWidget {
  final String status;
  const _StatusSteps({required this.status});

  static const _order = ['accepted', 'on_the_way', 'arrived', 'completed'];
  static const _labelKeys = ['sos.step_accepted', 'sos.step_on_the_way', 'sos.step_arrived', 'sos.step_completed'];

  @override
  Widget build(BuildContext context) {
    final currentIdx = _order.indexOf(status).clamp(0, _order.length - 1);
    return Row(
      children: List.generate(_order.length, (i) {
        final done = i <= currentIdx;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i <= currentIdx ? AppColors.danger : AppColors.hairline(context),
                      ),
                    ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.danger : AppColors.hairline2(context),
                    ),
                  ),
                  if (i < _order.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i < currentIdx ? AppColors.danger : AppColors.hairline(context),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _labelKeys[i].tr(),
                style: AppTypography.labelSmall.copyWith(
                  color: done ? AppColors.text(context) : AppColors.text3(context),
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: AppTypography.body.copyWith(color: AppColors.text2(context)), textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          MButton(label: 'common.retry'.tr(), variant: MButtonVariant.secondary, small: true, onTap: onRetry),
        ],
      ),
    );
  }
}

/// Kichik, kutubxonasiz tasdiqlash oynasi (Cupertino/Material'ga bog'lanmasdan).
class CupertinoAlertDialogLike extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const CupertinoAlertDialogLike({
    super.key,
    required this.title,
    required this.message,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgElevated(context),
      title: Text(title, style: AppTypography.titleMedium.copyWith(color: AppColors.text(context))),
      content: Text(message, style: AppTypography.body.copyWith(color: AppColors.text2(context))),
      actions: [
        TextButton(onPressed: onCancel, child: Text('common.no'.tr())),
        TextButton(onPressed: onConfirm, child: Text('common.yes'.tr(), style: const TextStyle(color: AppColors.danger))),
      ],
    );
  }
}
