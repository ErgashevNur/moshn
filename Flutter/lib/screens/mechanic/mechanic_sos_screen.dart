import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/sos_request.dart';
import '../../services/sos_service.dart';
import '../../services/ws_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/m_button.dart';
import '../../widgets/m_plate.dart';

final _activeSosProvider = FutureProvider.autoDispose<SosRequest?>((ref) {
  return SosService().getActiveForMaster();
});

final _incomingSosProvider = FutureProvider.autoDispose<List<SosIncomingRequest>>((ref) {
  return SosService().listForMaster();
});

class MechanicSosScreen extends ConsumerStatefulWidget {
  const MechanicSosScreen({super.key});

  @override
  ConsumerState<MechanicSosScreen> createState() => _MechanicSosScreenState();
}

class _MechanicSosScreenState extends ConsumerState<MechanicSosScreen> {
  StreamSubscription<WsEvent>? _wsSub;
  String? _acceptingId;

  @override
  void initState() {
    super.initState();
    _wsSub = WsService.instance.events.listen(_onWsEvent);
  }

  void _onWsEvent(WsEvent event) {
    if (event.type == 'sos_dispatch') {
      ref.invalidate(_incomingSosProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('sos.new_request_arrived'.tr(), style: AppTypography.body.copyWith(color: Colors.white)),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    } else if (event.type == 'sos_taken') {
      ref.invalidate(_incomingSosProvider);
    }
  }

  Future<void> _accept(SosIncomingRequest item) async {
    setState(() => _acceptingId = item.sosRequestId);
    try {
      await SosService().accept(item.sosRequestId);
      if (!mounted) return;
      ref.invalidate(_activeSosProvider);
      ref.invalidate(_incomingSosProvider);
      context.push('/mechanic/sos/${item.sosRequestId}');
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
      ref.invalidate(_incomingSosProvider);
    } finally {
      if (mounted) setState(() => _acceptingId = null);
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeAsync = ref.watch(_activeSosProvider);
    final incomingAsync = ref.watch(_incomingSosProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Text('SOS', style: AppTypography.appbarTitle.copyWith(color: AppColors.danger)),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(_activeSosProvider);
                  ref.invalidate(_incomingSosProvider);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  children: [
                    activeAsync.when(
                      data: (active) => active == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                              child: _ActiveJobCard(
                                request: active,
                                onTap: () => context.push('/mechanic/sos/${active.id}'),
                              ),
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    incomingAsync.when(
                      data: (items) => items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: EmptyState(
                                icon: Icons.shield_outlined,
                                title: 'sos.no_incoming_title'.tr(),
                                subtitle: 'sos.no_incoming_body'.tr(),
                              ),
                            )
                          : Column(
                              children: items
                                  .map((item) => Padding(
                                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                        child: _IncomingCard(
                                          item: item,
                                          accepting: _acceptingId == item.sosRequestId,
                                          onAccept: () => _accept(item),
                                        ),
                                      ))
                                  .toList(),
                            ),
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (_, _) => Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: Center(
                          child: Text('common.error'.tr(), style: AppTypography.body.copyWith(color: AppColors.text3(context))),
                        ),
                      ),
                    ),
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

class _ActiveJobCard extends StatelessWidget {
  final SosRequest request;
  final VoidCallback onTap;
  const _ActiveJobCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerDim,
        borderRadius: BorderRadius.circular(AppSpacing.r_md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.danger, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('sos.active_job_title'.tr(),
                    style: AppTypography.labelLarge.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.customerName.isNotEmpty ? request.customerName : 'sos.customer'.tr(),
            style: AppTypography.body.copyWith(color: AppColors.text2(context)),
          ),
          const SizedBox(height: AppSpacing.md),
          MButton(label: 'sos.continue_button'.tr(), variant: MButtonVariant.danger, small: true, onTap: onTap),
        ],
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  final SosIncomingRequest item;
  final bool accepting;
  final VoidCallback onAccept;
  const _IncomingCard({required this.item, required this.accepting, required this.onAccept});

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
                  item.serviceType?.nameFor(locale) ?? 'sos.title'.tr(),
                  style: AppTypography.labelMedium.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.dangerDim, borderRadius: BorderRadius.circular(AppSpacing.r_full)),
                child: Text(
                  '${(item.distanceMeters / 1000).toStringAsFixed(1)} km',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.danger, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (item.vehicle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MPlate(plate: item.vehicle!.plate),
            ),
          if (item.customerName.isNotEmpty)
            Row(
              children: [
                Icon(Icons.person_rounded, size: 14, color: AppColors.text3(context)),
                const SizedBox(width: 4),
                Text(item.customerName, style: AppTypography.body.copyWith(color: AppColors.text2(context), fontSize: 13)),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          MButton(
            label: 'sos.accept_button'.tr(),
            variant: MButtonVariant.danger,
            small: true,
            loading: accepting,
            onTap: accepting ? null : onAccept,
          ),
        ],
      ),
    );
  }
}
