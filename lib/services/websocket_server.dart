import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/server_state.dart';
import 'event_logger.dart';
import 'password_auth.dart';

class WebSocketServer {
  final ServerState state;
  final PasswordAuth auth;
  HttpServer? _server;
  RawDatagramSocket? _udpSocket;
  bool _running = false;
  Timer? _idleTimer;

  WebSocketServer({required this.state, required this.auth});

  static Future<String> _getLanIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              (addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.16.') ||
                  addr.address.startsWith('172.17.') ||
                  addr.address.startsWith('172.18.') ||
                  addr.address.startsWith('172.19.') ||
                  addr.address.startsWith('172.20.') ||
                  addr.address.startsWith('172.21.') ||
                  addr.address.startsWith('172.22.') ||
                  addr.address.startsWith('172.23.') ||
                  addr.address.startsWith('172.24.') ||
                  addr.address.startsWith('172.25.') ||
                  addr.address.startsWith('172.26.') ||
                  addr.address.startsWith('172.27.') ||
                  addr.address.startsWith('172.28.') ||
                  addr.address.startsWith('172.29.') ||
                  addr.address.startsWith('172.30.') ||
                  addr.address.startsWith('172.31.'))) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  bool get isRunning => _running;

  void _startUdpDiscovery(int port) {
    RawDatagramSocket.bind(InternetAddress.anyIPv4, port)
        .then((socket) {
          _udpSocket = socket;
          socket.broadcastEnabled = true;
          socket.listen((event) {
            if (event != RawSocketEvent.read) return;
            final datagram = socket.receive();
            if (datagram == null) return;
            final msg = String.fromCharCodes(datagram.data);
            if (msg == 'remote_turner_discover') {
              final ip = state.serverAddress.value;
              final response = 'remote_turner:$ip:$port';
              socket.send(response.codeUnits, datagram.address, datagram.port);
            }
          });
        })
        .catchError((_) {});
  }

  Future<void> start() async {
    if (_running) return;
    try {
      final port = int.tryParse(state.serverPort.value) ?? 9090;
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        port,
      );
      _running = true;
      state.serverRunning.value = true;
      state.connectionState.value = ServerConnectionState.waiting;
      state.serverAddress.value = await _getLanIp();
      state.serverPort.value = port.toString();
      _server!.listen(_handleRequest, onError: _handleError);
      _startUdpDiscovery(port);
      _resetIdleTimer();
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
    _udpSocket?.close();
    _udpSocket = null;
    for (final client in state.clients.value) {
      await client.close();
    }
    state.clients.value = [];
    await _server?.close(force: true);
    _server = null;
    state.serverRunning.value = false;
    state.connectionState.value = ServerConnectionState.off;
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
