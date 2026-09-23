// lib/core/network/reverb_socket.dart
import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:khmer_cat_app/core/config/app_config.dart';
import 'package:khmer_cat_app/core/utils/app_log.dart';

enum SocketConnectionState { connecting, connected, reconnecting, failed }

class PusherMessage {
  final String channel;
  final String event;
  final dynamic data;
  PusherMessage({required this.channel, required this.event, this.data});
}

/// One shared connection to Laravel Reverb, speaking the Pusher wire
/// protocol directly (no native SDK) so it can target this app's own dev
/// host/port instead of a Pusher.com "cluster" (see [AppConfig.reverbHost]).
/// Public channels only — no `pusher:subscribe` auth is needed for those,
/// which is all this app currently uses (comments on public video content).
///
/// Connection lifecycle is independent of channel subscriptions: call
/// [connect] once when the app starts (see `main.dart`) and it stays up —
/// reconnecting with backoff through drops — for the life of the app.
/// Features subscribe/unsubscribe to their own channels freely; the last
/// channel closing does NOT tear down the socket. Call [disconnect]
/// explicitly if the app ever needs to fully stop (e.g. on logout).
class ReverbSocket {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;
  bool _manuallyClosed = true;

  final _connectionController =
      StreamController<SocketConnectionState>.broadcast();
  Stream<SocketConnectionState> get connectionState =>
      _connectionController.stream;
  SocketConnectionState _state = SocketConnectionState.failed;
  SocketConnectionState get state => _state;

  /// channel name -> stream controller for messages on that channel.
  final Map<String, StreamController<PusherMessage>> _channelControllers = {};

  Uri get _uri => Uri(
    scheme: AppConfig.reverbUseTls ? 'wss' : 'ws',
    host: AppConfig.reverbHost,
    port: AppConfig.reverbPort,
    path: '/app/${AppConfig.reverbAppKey}',
    queryParameters: const {
      'protocol': '7',
      'client': 'flutter',
      'version': '1.0',
    },
  );

  /// Opens the socket. Safe to call more than once — a no-op while already
  /// connecting/connected. Called once at app startup; [subscribe] also
  /// calls this as a fallback so a feature works even if it somehow
  /// subscribes before app startup has run this.
  void connect() {
    if (_state == SocketConnectionState.connecting ||
        _state == SocketConnectionState.connected) {
      return;
    }
    _manuallyClosed = false;
    _reconnectTimer?.cancel();
    _connect();
  }

  /// Fully closes the socket and stops reconnecting. Not called anywhere
  /// automatically today — available for a future "log out" flow.
  void disconnect() {
    _manuallyClosed = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _sub = null;
    _reconnectAttempt = 0;
    _setState(SocketConnectionState.failed);
  }

  /// Subscribes to a public Reverb channel. Returns a stream of events on
  /// that channel; call [unsubscribe] with the same channel name when done.
  /// Does NOT affect the socket's own connect/disconnect lifecycle.
  Stream<PusherMessage> subscribe(String channelName) {
    final controller = _channelControllers.putIfAbsent(
      channelName,
      () => StreamController<PusherMessage>.broadcast(),
    );
    connect();
    _sendSubscribe(channelName);
    return controller.stream;
  }

  void unsubscribe(String channelName) {
    final controller = _channelControllers.remove(channelName);
    controller?.close();
    _send({
      'event': 'pusher:unsubscribe',
      'data': {'channel': channelName},
    });
  }

  void _connect() {
    _setState(SocketConnectionState.connecting);
    try {
      _channel = WebSocketChannel.connect(_uri);
      _sub = _channel!.stream.listen(
        _handleMessage,
        onError: (_) => _handleDisconnect(),
        onDone: _handleDisconnect,
        cancelOnError: true,
      );
    } catch (e) {
      AppLog.info('ReverbSocket connect failed: $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = msg['event'] as String?;
    if (event == null) return;

    if (event == 'pusher:connection_established') {
      _reconnectAttempt = 0;
      _setState(SocketConnectionState.connected);
      // Re-subscribe to every channel a caller is still holding a stream
      // for — matters after a reconnect, not on the first connect.
      for (final channelName in _channelControllers.keys) {
        _sendSubscribe(channelName);
      }
      return;
    }

    if (event == 'pusher:ping') {
      _send({'event': 'pusher:pong', 'data': {}});
      return;
    }

    if (event == 'pusher:error') {
      AppLog.info('ReverbSocket error: ${msg['data']}');
      return;
    }

    if (event.startsWith('pusher_internal:') || event.startsWith('pusher:')) {
      return;
    }

    final channelName = msg['channel'] as String?;
    if (channelName == null) return;
    final controller = _channelControllers[channelName];
    if (controller == null || controller.isClosed) return;

    var data = msg['data'];
    // Reverb sends `data` as a JSON-encoded string (Pusher protocol
    // convention) — decode it so listeners get a real Map, not a string.
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        // leave as-is — not JSON, pass the raw string through
      }
    }

    controller.add(PusherMessage(channel: channelName, event: event, data: data));
  }

  void _handleDisconnect() {
    _sub?.cancel();
    _channel = null;
    _sub = null;

    if (_manuallyClosed) {
      _setState(SocketConnectionState.failed);
      return;
    }

    // Keeps retrying even with zero active channel subscriptions — the
    // connection is app-lifetime, not tied to whatever screen is open.
    _setState(SocketConnectionState.reconnecting);
    _reconnectAttempt++;
    final delaySeconds = [2, 4, 8, 15, 30][
        (_reconnectAttempt - 1).clamp(0, 4)];
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_manuallyClosed) _connect();
    });
  }

  void _sendSubscribe(String channelName) {
    if (_state != SocketConnectionState.connected) return;
    _send({
      'event': 'pusher:subscribe',
      'data': {'channel': channelName},
    });
  }

  void _send(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (_) {
      // socket already gone — the reconnect/backoff loop will recover it
    }
  }

  void _setState(SocketConnectionState next) {
    _state = next;
    _connectionController.add(next);
  }
}
