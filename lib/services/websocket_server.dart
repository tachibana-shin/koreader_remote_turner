import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/server_state.dart';
import 'event_logger.dart';
import 'password_auth.dart';
import 'platform_service.dart';

class WebSocketServer {
  final ServerState state;
  final PasswordAuth auth;
  HttpServer? _server;
  bool _running = false;
  Timer? _idleTimer;

  WebSocketServer({required this.state, required this.auth});

  bool get isRunning => _running;

  Future<void> start() async {
    if (_running) return;
    try {
      final port = int.tryParse(state.serverPort.value) ?? 9090;
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _running = true;
      state.serverRunning.value = true;
      state.connectionState.value = ServerConnectionState.waiting;
      state.serverAddress.value = _server!.address.address;
      state.serverPort.value = port.toString();
      _server!.listen(_handleRequest, onError: _handleError);
      _resetIdleTimer();
      await PlatformService.startForegroundService();
    } catch (e) {
      state.logger.log(
        LogEntry(
          time: DateTime.now(),
          event: 'server_error',
          status: 'error',
          detail: e.toString(),
        ),
      );
    }
  }

  Future<void> stop() async {
    _running = false;
    _idleTimer?.cancel();
    for (final client in state.clients.value) {
      await client.close();
    }
    state.clients.value = [];
    await _server?.close(force: true);
    _server = null;
    state.serverRunning.value = false;
    state.connectionState.value = ServerConnectionState.off;
    await PlatformService.stopForegroundService();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
  }

  void _handleRequest(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then(_handleWebSocket);
    } else {
      request.response.statusCode = 400;
      request.response.close();
    }
  }

  void _handleWebSocket(WebSocket socket) {
    final clients = List<WebSocket>.from(state.clients.value);
    clients.add(socket);
    state.clients.value = clients;
    state.connectionState.value = ServerConnectionState.connected;

    String? challenge;

    socket.listen(
      (data) {
        try {
          final msg = json.decode(data as String) as Map<String, dynamic>;
          final type = msg['type'] as String?;
          if (type == 'auth') {
            challenge = auth.generateChallenge();
            socket.add(
              json.encode({'type': 'auth_challenge', 'challenge': challenge}),
            );
          } else if (type == 'auth_response') {
            final hash = msg['hash'] as String?;
            if (auth.verify(challenge ?? '', hash ?? '')) {
              socket.add(json.encode({'type': 'auth_result', 'success': true}));
              state.deviceName.value =
                  msg['device_name'] as String? ?? 'Unknown';
              state.logger.log(
                LogEntry(
                  time: DateTime.now(),
                  event: 'auth',
                  status: 'success',
                  detail: 'Device connected',
                ),
              );
            } else {
              socket.add(
                json.encode({'type': 'auth_result', 'success': false}),
              );
              socket.close();
            }
          } else if (type == 'hello') {
            if (!auth.hasPassword) {
              state.deviceName.value =
                  msg['device_name'] as String? ?? 'Unknown';
              state.logger.log(
                LogEntry(
                  time: DateTime.now(),
                  event: 'connected',
                  status: 'success',
                  detail: 'Device connected: ${state.deviceName.value}',
                ),
              );
            }
          }
        } catch (_) {}
      },
      onDone: () {
        _removeClient(socket);
      },
      onError: (_) {
        _removeClient(socket);
      },
    );
  }

  void _removeClient(WebSocket socket) {
    final clients = List<WebSocket>.from(state.clients.value);
    clients.remove(socket);
    state.clients.value = clients;
    if (clients.isEmpty) {
      state.connectionState.value = ServerConnectionState.waiting;
      state.deviceName.value = '';
      _resetIdleTimer();
    }
  }

  void _handleError(Object error) {
    state.logger.log(
      LogEntry(
        time: DateTime.now(),
        event: 'server_error',
        status: 'error',
        detail: error.toString(),
      ),
    );
  }

  void sendAction(String action) {
    final msg = json.encode({'type': 'action', 'action': action});
    for (final client in state.clients.value) {
      try {
        client.add(msg);
      } catch (_) {}
    }
    if (action == 'next_page') {
      state.recordEvent('forward');
    } else if (action == 'prev_page') {
      state.recordEvent('backward');
    } else if (action == 'sleep') {
      state.recordEvent('sleep');
    }
  }

  void dispose() {
    stop();
  }
}
