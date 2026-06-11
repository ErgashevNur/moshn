import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_card.dart';

final _customerCardProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>(
  (ref, customerId) => ShopService().getCustomerCard(customerId),
);

class CustomerCardScreen extends ConsumerWidget {
  final String customerId;
  const CustomerCardScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(_customerCardProvider(customerId));

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text('service.customer_card'.tr(),
                        style: AppTypography.titleLarge),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: cardAsync.when(
              data: (card) => _Body(
                card: card,
                customerId: customerId,
                onRefresh: () => ref.invalidate(_customerCardProvider),
              ),
              loading: () => const Center(
                  child: CircularProgressIndicator.adaptive()),
              error: (e, _) => Center(
                child: Text('${'common.error'.tr()}: $e',
                    style:
                        AppTypography.body.copyWith(color: AppColors.danger)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final Map<String, dynamic> card;
  final String customerId;
  final VoidCallback onRefresh;

  const _Body({
    required this.card,
    required this.customerId,
    required this.onRefresh,
  });

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late bool _isVip;
  late TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isVip = (widget.card['is_vip'] ?? false) as bool;
    _notesCtrl = TextEditingController(
        text: (widget.card['notes'] ?? '') as String);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleVip() async {
    setState(() => _saving = true);
    try {
      await ShopService().setVip(widget.customerId, !_isVip);
      if (!mounted) return;
      setState(() => _isVip = !_isVip);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveNotes() async {
    setState(() => _saving = true);
    try {
      await ShopService().updateCustomerCard(
          widget.customerId, {'notes': _notesCtrl.text.trim()});
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.card['customer_name'] ?? '—') as String;
    final phone = (widget.card['customer_phone'] ?? '') as String;
    final visits = (widget.card['visit_count'] ?? 0) as int;
    final lastVisit = widget.card['last_visit_at'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(name: name, phone: phone, isVip: _isVip),
          const SizedBox(height: AppSpacing.xl),
          SectionCard(
            child: Column(
              children: [
                _InfoRow(label: 'crm.visits_count'.tr(), value: '$visits'),
                if (lastVisit != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(height: 0.5, color: AppColors.hairline(context)),
                  const SizedBox(height: AppSpacing.sm),
                  _InfoRow(
                    label: 'crm.last_visit'.tr(),
                    value: _fmtDate(lastVisit),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'service.vip'.tr(),
                  style: AppTypography.titleSmall,
                ),
              ),
              Switch.adaptive(
                value: _isVip,
                onChanged: _saving ? null : (_) => _toggleVip(),
                activeTrackColor: CupertinoColors.systemYellow,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('service.notes'.tr(), style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _notesCtrl,
            minLines: 3,
            maxLines: 6,
            style: AppTypography.body.copyWith(color: AppColors.text(context)),
            decoration: InputDecoration(
              hintText: 'crm.notes_hint'.tr(),
              hintStyle:
                  AppTypography.body.copyWith(color: AppColors.text3(context)),
              filled: true,
              fillColor: AppColors.surface2(context),
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide:
                    BorderSide(color: AppColors.inverseBg(context), width: 1),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'common.save'.tr(),
            onPressed: _saving ? null : _saveNotes,
            loading: _saving,
          ),
          const SizedBox(height: AppSpacing.huge),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String phone;
  final bool isVip;

  const _Header(
      {required this.name, required this.phone, required this.isVip});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: isVip
                ? CupertinoColors.systemYellow.withValues(alpha: 0.2)
                : AppColors.inverseBg(context).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              isVip ? '⭐' : _initials(name),
              style: AppTypography.titleLarge,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: AppTypography.titleLarge,
                  overflow: TextOverflow.ellipsis),
              if (phone.isNotEmpty)
                Text(phone,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.text3(context))),
              if (isVip)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: 2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemYellow.withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    'VIP',
                    style: AppTypography.labelMedium.copyWith(
                      color: CupertinoColors.systemYellow,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: AppTypography.body
                  .copyWith(color: AppColors.text3(context))),
        ),
        Text(value,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
