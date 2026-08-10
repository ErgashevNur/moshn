import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/master.dart';
import '../../services/shop_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../../widgets/m_workshop_card.dart';

/// Bosh ekrandagi qidiruv paneli — ism bo'yicha servis va usta aralash
/// natija (CLAUDE.md §4).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  int _requestId = 0;

  SearchResult _result = const SearchResult();
  bool _loading = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _result = const SearchResult();
        _loading = false;
        _searched = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(value));
  }

  Future<void> _runSearch(String value) async {
    final id = ++_requestId;
    try {
      final result = await ShopService().search(value);
      if (!mounted || id != _requestId) return;
      setState(() {
        _result = result;
        _loading = false;
        _searched = true;
      });
    } catch (_) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _loading = false;
        _searched = true;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(AppSpacing.r_xs),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text(context), size: 17),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(AppSpacing.r_md),
                        border: Border.all(color: AppColors.hairline(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, size: 18, color: AppColors.text3(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CupertinoTextField(
                              controller: _ctrl,
                              focusNode: _focusNode,
                              onChanged: _onChanged,
                              placeholder: 'home.search_hint'.tr(),
                              padding: EdgeInsets.zero,
                              decoration: const BoxDecoration(),
                              style: AppTypography.body.copyWith(color: AppColors.text(context)),
                              placeholderStyle: AppTypography.body.copyWith(color: AppColors.text3(context)),
                            ),
                          ),
                          if (_ctrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _ctrl.clear();
                                _onChanged('');
                              },
                              child: Icon(Icons.close_rounded, size: 18, color: AppColors.text3(context)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (!_searched) {
      return _hint(context, Icons.search_rounded, 'search.prompt'.tr());
    }
    if (_result.isEmpty) {
      return _hint(context, Icons.search_off_rounded, 'search.empty'.tr());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      children: [
        if (_result.masters.isNotEmpty) ...[
          _sectionTitle(context, 'search.masters'.tr()),
          const SizedBox(height: AppSpacing.sm),
          ..._result.masters.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _MasterResultTile(
                  master: m,
                  onTap: () => context.push('/owner/shops/${m.shopId}'),
                ),
              )),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_result.shops.isNotEmpty) ...[
          _sectionTitle(context, 'search.shops'.tr()),
          const SizedBox(height: AppSpacing.sm),
          ..._result.shops.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: WorkshopCard(
                  name: s.shopName,
                  rating: s.ratingAvg,
                  reviewCount: s.ratingCount,
                  address: s.address,
                  isOpen: true,
                  onTap: () => context.push('/owner/shops/${s.id}'),
                ),
              )),
        ],
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Text(
        text,
        style: AppTypography.eyebrow.copyWith(color: AppColors.text3(context)),
      );

  Widget _hint(BuildContext context, IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.text3(context)),
            const SizedBox(height: AppSpacing.md),
            Text(text, style: AppTypography.body.copyWith(color: AppColors.text3(context)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MasterResultTile extends StatelessWidget {
  final Master master;
  final VoidCallback onTap;
  const _MasterResultTile({required this.master, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.goldDim,
                borderRadius: BorderRadius.circular(AppSpacing.r_xs),
              ),
              alignment: Alignment.center,
              child: Text(
                master.fullName.isNotEmpty ? master.fullName[0].toUpperCase() : '?',
                style: AppTypography.titleSmall.copyWith(color: AppColors.gold),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    master.fullName,
                    style: AppTypography.labelMedium.copyWith(color: AppColors.text(context), fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    master.shopName.isNotEmpty ? master.shopName : (master.position),
                    style: AppTypography.body.copyWith(color: AppColors.text3(context), fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (master.ratingCount > 0) ...[
              const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 2),
              Text(master.ratingAvg.toStringAsFixed(1),
                  style: AppTypography.labelSmall.copyWith(color: AppColors.text2(context))),
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(Icons.chevron_right_rounded, color: AppColors.text3(context)),
          ],
        ),
      ),
    );
  }
}
