import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/sos_request.dart';
import '../services/sos_service.dart';
import '../services/ws_service.dart';

class SosState {
  final SosRequest? request;
  final bool loading;
  final String? error;

  const SosState({this.request, this.loading = false, this.error});

  SosState copyWith({SosRequest? request, bool? loading, String? error}) {
    return SosState(
      request: request ?? this.request,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Mijozning joriy SOS so'rovini boshqaradi: yaratish → jonli kuzatuv
/// (WebSocket + zaxira poll) → bekor qilish/yordam so'rash.
/// Faqat mijoz tomonida ishlatiladi — usta tomonida ekranlar WS'ni
/// to'g'ridan-to'g'ri tinglaydi (service_home_screen.dart andozasi).
class SosNotifier extends StateNotifier<SosState> {
  SosNotifier() : super(const SosState());

  final SosService _service = SosService();
  Timer? _pollTimer;
  StreamSubscription<WsEvent>? _wsSub;

  Future<bool> create({
    required String vehicleId,
    required String serviceTypeId,
    required double lat,
    required double lng,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final request = await _service.create(
        vehicleId: vehicleId,
        serviceTypeId: serviceTypeId,
        lat: lat,
        lng: lng,
      );
      state = SosState(request: request, loading: false);
      _goLive();
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: sosErrorMessage(e));
      return false;
    }
  }

  Future<void> loadExisting(String id) async {
    if (state.request?.id == id) {
      _goLive();
      return;
    }
    state = state.copyWith(loading: true, error: null);
    try {
      final request = await _service.getStatus(id);
      state = SosState(request: request, loading: false);
      _goLive();
    } catch (e) {
      state = state.copyWith(loading: false, error: sosErrorMessage(e));
    }
  }

  Future<void> refresh() async {
    final id = state.request?.id;
    if (id == null) return;
    try {
      final request = await _service.getStatus(id);
      state = state.copyWith(request: request);
      if (!request.needsLiveUpdates) _stopLive();
    } catch (_) {
      // Vaqtinchalik tarmoq xatosi — keyingi poll/WS hodisasi qayta urinadi.
    }
  }

  Future<bool> cancel() async {
    final id = state.request?.id;
    if (id == null) return false;
    try {
      final request = await _service.cancel(id);
      state = state.copyWith(request: request);
      _stopLive();
      return true;
    } catch (e) {
      state = state.copyWith(error: sosErrorMessage(e));
      return false;
    }
  }

  Future<bool> requestEvacuator() async {
    final id = state.request?.id;
    if (id == null) return false;
    try {
      final request = await _service.requestEvacuator(id);
      state = state.copyWith(request: request);
      _goLive();
      return true;
    } catch (e) {
      state = state.copyWith(error: sosErrorMessage(e));
      return false;
    }
  }

  Future<bool> confirmPayment({String method = 'card_qr'}) async {
    final id = state.request?.id;
    if (id == null) return false;
    try {
      final request = await _service.confirmPayment(id, method: method);
      state = state.copyWith(request: request);
      if (!request.needsLiveUpdates) _stopLive();
      return true;
    } catch (e) {
      state = state.copyWith(error: sosErrorMessage(e));
      return false;
    }
  }

  Future<bool> addTip(int amount) async {
    final id = state.request?.id;
    if (id == null) return false;
    try {
      await _service.addTip(id, amount);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestSupport() async {
    final id = state.request?.id;
    if (id == null) return false;
    try {
      await _service.requestSupport(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  void reset() {
    _stopLive();
    state = const SosState();
  }

  void _goLive() {
    final request = state.request;
    if (request == null || !request.needsLiveUpdates) return;

    WsService.instance.connect();
    _wsSub ??= WsService.instance.events.listen(_onWsEvent);
    _pollTimer ??= Timer.periodic(const Duration(seconds: 6), (_) => refresh());
  }

  void _stopLive() {
    _wsSub?.cancel();
    _wsSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    WsService.instance.disconnect();
  }

  void _onWsEvent(WsEvent event) {
    if (!event.type.startsWith('sos_')) return;
    if (event.data['sosRequestId'] != state.request?.id) return;
    refresh();
  }

  @override
  void dispose() {
    _stopLive();
    super.dispose();
  }
}

final sosProvider = StateNotifierProvider<SosNotifier, SosState>((ref) => SosNotifier());

/// Faqat qabul qilingandan keyin ochiladigan chat tarixi.
final sosMessagesProvider =
    FutureProvider.autoDispose.family<List<SosMessage>, String>((ref, sosRequestId) {
  return SosService().getMessages(sosRequestId);
});
