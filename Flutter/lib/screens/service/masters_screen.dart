import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/master.dart';
import '../../models/service_type.dart';
import '../../services/master_service.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

final myMastersProvider = FutureProvider.autoDispose<List<Master>>((ref) {
  return MasterService().listMyMasters();
});

final _serviceTypesProvider = FutureProvider.autoDispose<List<ServiceType>>((ref) {
  return ShopService().getServiceTypes();
});

class MastersScreen extends ConsumerWidget {
  const MastersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myMastersProvider);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.arrow_back_rounded,
                        color: AppColors.text(context)),
                  ),
                  Expanded(
                    child: Text('Мастера', style: AppTypography.displayLarge),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'Добавляйте мастеров — клиенты записываются к конкретному мастеру',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.text2(context),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: async.when(
                data: (masters) => masters.isEmpty
                    ? _empty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, 120),
                        itemCount: masters.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) => _MasterTile(
                          master: masters[i],
                          onTap: () => _openForm(context, ref, masters[i]),
                        ),
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(myMastersProvider),
                    child: const Text('Повторить'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref, null),
        backgroundColor: AppColors.inverseBg(context),
        foregroundColor: AppColors.inverseText(context),
        icon: const Icon(Icons.add_rounded),
        label: Text('Мастер',
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.inverseText(context))),
      ),
    );
  }

  Widget _empty(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.engineering_rounded,
                size: 48, color: AppColors.text3(context)),
            const SizedBox(height: AppSpacing.md),
            Text('Мастеров пока нет',
                style: AppTypography.titleSmall
                    .copyWith(color: AppColors.text2(context))),
          ],
        ),
      );

  Future<void> _openForm(BuildContext context, WidgetRef ref, Master? master) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MasterFormSheet(master: master),
    );
    if (saved == true) ref.invalidate(myMastersProvider);
  }
}

// ── Master tile ─────────────────────────────────────────────────────────────

class _MasterTile extends StatelessWidget {
  final Master master;
  final VoidCallback onTap;

  const _MasterTile({required this.master, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = master;
    final initial = m.fullName.isNotEmpty ? m.fullName[0].toUpperCase() : 'M';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_md),
          border: Border.all(color: AppColors.hairline(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: m.isActive ? AppColors.goldDim : AppColors.surface2(context),
                borderRadius: BorderRadius.circular(AppSpacing.r_xs),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: AppTypography.titleSmall.copyWith(
                  color: m.isActive ? AppColors.gold : AppColors.text3(context),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.fullName.isNotEmpty ? m.fullName : 'Мастер',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.text(context),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!m.isActive) ...[
                        const SizedBox(width: 6),
                        _tag(context, 'откл.', AppColors.text3(context)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    m.position.isNotEmpty ? m.position : 'Мастер',
                    style: AppTypography.body.copyWith(
                      color: AppColors.text3(context),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (m.ratingCount > 0) ...[
              const Text('⭐', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 3),
              Text(
                m.ratingAvg.toStringAsFixed(1),
                style: AppTypography.labelSmall
                    .copyWith(color: AppColors.text2(context)),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(Icons.chevron_right_rounded, color: AppColors.text3(context)),
          ],
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppSpacing.r_full),
        ),
        child: Text(text,
            style: AppTypography.labelSmall.copyWith(color: color, fontSize: 10)),
      );
}

// ── Add / edit form ─────────────────────────────────────────────────────────

class MasterFormSheet extends ConsumerStatefulWidget {
  final Master? master;
  const MasterFormSheet({super.key, this.master});

  @override
  ConsumerState<MasterFormSheet> createState() => MasterFormSheetState();
}

class MasterFormSheetState extends ConsumerState<MasterFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _position;
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late Set<String> _serviceIds;
  late bool _active;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.master != null;

  @override
  void initState() {
    super.initState();
    final m = widget.master;
    _name = TextEditingController(text: m?.fullName ?? '');
    _position = TextEditingController(text: m?.position ?? '');
    _serviceIds = m?.serviceTypes.map((s) => s.serviceTypeId).toSet() ?? {};
    _active = m?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _position.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final svc = MasterService();
      if (_isEdit) {
        await svc.updateMaster(
          widget.master!.id,
          fullName: _name.text.trim(),
          position: _position.text.trim(),
          isActive: _active,
          serviceTypeIds: _serviceIds.toList(),
        );
      } else {
        await svc.createMaster(
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          fullName: _name.text.trim(),
          position: _position.text.trim(),
          serviceTypeIds: _serviceIds.toList(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = _msg(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    setState(() => _saving = true);
    try {
      await MasterService().deactivateMaster(widget.master!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _error = _msg(e);
        _saving = false;
      });
    }
  }

  String _msg(Object e) {
    final s = e.toString();
    return s.contains('message') ? s : 'Ошибка. Проверьте данные';
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(_serviceTypesProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.r_xl),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_isEdit ? 'Редактировать мастера' : 'Новый мастер',
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.text(context))),
              const SizedBox(height: AppSpacing.md),
              _field(context, _name, 'Имя и фамилия'),
              const SizedBox(height: AppSpacing.sm),
              _field(context, _position, 'Должность (напр. Шиномонтажник)'),
              if (!_isEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                _field(context, _phone, 'Телефон',
                    keyboard: TextInputType.phone),
                const SizedBox(height: AppSpacing.sm),
                _field(context, _email, 'Email',
                    keyboard: TextInputType.emailAddress),
                const SizedBox(height: AppSpacing.sm),
                _field(context, _password, 'Пароль для входа', obscure: true),
              ],
              const SizedBox(height: AppSpacing.md),
              Text('Услуги мастера',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.text3(context))),
              const SizedBox(height: AppSpacing.sm),
              typesAsync.when(
                data: (types) => Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: types.map((t) {
                    final sel = _serviceIds.contains(t.id);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (sel) {
                          _serviceIds.remove(t.id);
                        } else {
                          _serviceIds.add(t.id);
                        }
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.inverseBg(context)
                              : AppColors.surface2(context),
                          borderRadius: BorderRadius.circular(AppSpacing.r_full),
                          border: Border.all(
                            color: sel
                                ? Colors.transparent
                                : AppColors.hairline(context),
                          ),
                        ),
                        child: Text(
                          t.nameFor('ru'),
                          style: AppTypography.labelSmall.copyWith(
                            color: sel
                                ? AppColors.inverseText(context)
                                : AppColors.text2(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const SizedBox(
                    height: 32,
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, _) => const SizedBox.shrink(),
              ),
              if (_isEdit) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Text('Активен',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.text(context))),
                    ),
                    Switch(
                      value: _active,
                      onChanged: (v) => setState(() => _active = v),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.danger)),
              ],
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.inverseBg(context),
                  foregroundColor: AppColors.inverseText(context),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.r_md)),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.inverseText(context)))
                    : Text(_isEdit ? 'Сохранить' : 'Добавить',
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.inverseText(context),
                            fontWeight: FontWeight.w600)),
              ),
              if (_isEdit && widget.master!.isActive) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton(
                  onPressed: _saving ? null : _deactivate,
                  child: Text('Отключить мастера',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
    bool obscure = false,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      style: AppTypography.labelMedium.copyWith(color: AppColors.text(context)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTypography.labelMedium.copyWith(color: AppColors.text3(context)),
        filled: true,
        fillColor: AppColors.surface2(context),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.r_sm),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
