import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sos_request.dart';
import '../services/sos_service.dart';
import '../services/ws_service.dart';
import '../store/sos_store.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// SOS so'rovi qabul qilingandan keyin mijoz ↔ usta chati.
/// Mavjud WebSocket ustiga quriladi — o'zi alohida ulanish ochmaydi,
/// [WsService] allaqachon ulangan bo'lishi kerak (ekran uni ta'minlaydi).
class SosChat extends ConsumerStatefulWidget {
  final String sosRequestId;
  final String currentUserId;

  const SosChat({super.key, required this.sosRequestId, required this.currentUserId});

  @override
  ConsumerState<SosChat> createState() => _SosChatState();
}

class _SosChatState extends ConsumerState<SosChat> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  StreamSubscription<WsEvent>? _wsSub;

  @override
  void initState() {
    super.initState();
    _wsSub = WsService.instance.events.listen(_onWsEvent);
  }

  void _onWsEvent(WsEvent event) {
    if (event.type != 'sos_message') return;
    if (event.data['sosRequestId'] != widget.sosRequestId) return;
    ref.invalidate(sosMessagesProvider(widget.sosRequestId));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await SosService().sendMessage(widget.sosRequestId, text);
      _controller.clear();
      ref.invalidate(sosMessagesProvider(widget.sosRequestId));
    } catch (_) {
      // Yuborilmadi — foydalanuvchi matnni ko'radi va qayta bosishi mumkin.
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sosMessagesProvider(widget.sosRequestId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'sos.chat_title'.tr(),
          style: AppTypography.labelLarge.copyWith(color: AppColors.text(context)),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.r_md),
            border: Border.all(color: AppColors.hairline(context)),
          ),
          child: async.when(
            data: (messages) {
              if (messages.isEmpty) {
                return Center(
                  child: Text(
                    'sos.chat_empty'.tr(),
                    style: AppTypography.body.copyWith(color: AppColors.text3(context)),
                  ),
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollCtrl.hasClients) {
                  _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                }
              });
              return ListView.separated(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) => _MessageBubble(
                  message: messages[i],
                  mine: messages[i].senderUserId == widget.currentUserId,
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => Center(
              child: Text(
                'common.error'.tr(),
                style: AppTypography.body.copyWith(color: AppColors.text3(context)),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _controller,
                placeholder: 'sos.chat_hint'.tr(),
                onSubmitted: (_) => _send(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                style: AppTypography.body,
                placeholderStyle: AppTypography.body.copyWith(color: AppColors.text3(context)),
                decoration: BoxDecoration(
                  color: AppColors.surface2(context),
                  borderRadius: BorderRadius.circular(AppSpacing.r_full),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _sending ? null : _send,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.inverseBg(context),
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.inverseText(context)),
                        ),
                      )
                    : Icon(Icons.arrow_upward_rounded, color: AppColors.inverseText(context), size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final SosMessage message;
  final bool mine;
  const _MessageBubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: mine ? AppColors.inverseBg(context) : AppColors.surface2(context),
              borderRadius: BorderRadius.circular(AppSpacing.r_lg),
            ),
            child: Text(
              message.body,
              style: AppTypography.body.copyWith(
                color: mine ? AppColors.inverseText(context) : AppColors.text(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
