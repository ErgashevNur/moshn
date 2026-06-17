import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api.dart';

class WsEvent {
  final String type;
  final Map<String, dynamic> data;
  const WsEvent({required this.type, required this.data});
}

/// Singleton WebSocket xizmat. Servis roli uchun real-vaqt bron bildirshnomalar.
/// connect() → ulaning. disconnect() → uzing.
/// Auto-reconnect: uzilsa 2s, 4s, 8s... max 30s kutib qayta ulanadi.
class WsService {
  WsService._();
  static final WsService instance = WsService._();

  WebSocket? _socket;
  final _controller = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get events => _controller.stream;

  bool _active = false;
  int _retryDelay = 2;

  String _buildUrl(String token) {
    final base = ApiClient.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://')
        .replaceAll(RegExp(r'/v1$'), '');
    return '$base/v1/ws?token=$token';
  }

  Future<void> connect() async {
    if (_active) return;
    _active = true;
    _retryDelay = 2;
    await _tryConnect();
  }

  Future<void> _tryConnect() async {
    if (!_active) return;
    final token = await ApiClient.instance.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      _socket = await WebSocket.connect(_buildUrl(token));
      _retryDelay = 2;

      _socket!.listen(
        (raw) {
          if (raw is! String) return;
          try {
            final json = jsonDecode(raw) as Map<String, dynamic>;
            _controller.add(WsEvent(
              type: json['type'] as String? ?? '',
              data: (json['data'] as Map<String, dynamic>?) ?? {},
            ));
          } catch (_) {}
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (!_active) return;
    Future.delayed(Duration(seconds: _retryDelay), _tryConnect);
    _retryDelay = (_retryDelay * 2).clamp(2, 30);
  }

  void disconnect() {
    _active = false;
    _socket?.close();
    _socket = null;
  }
}
