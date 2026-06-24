import 'dart:io';
import 'package:kaeru/kaeru.dart';
import '../services/event_logger.dart';

enum ServerConnectionState { off, waiting, connected }

class ServerState {
  final Ref<ServerConnectionState> connectionState = Ref(
    ServerConnectionState.off,
  );
  final Ref<String> deviceName = Ref('');
  final Ref<String> serverAddress = Ref('');
  final Ref<String> serverPort = Ref('9090');
  final Ref<int> totalForwardEvents = Ref(0);
  final Ref<int> totalBackwardEvents = Ref(0);
  final Ref<double> avgSpeed = Ref(0.0);
  final Ref<List<SpeedDataPoint>> speedHistory = Ref([]);
  final Ref<bool> serverRunning = Ref(false);
  final Ref<HttpServer?> httpServer = Ref(null);
  final Ref<List<WebSocket>> clients = Ref([]);

  int _startTime = 0;
  int _forwardCount = 0;

  final EventLogger logger = EventLogger();

  void recordEvent(String type) {
    final now = DateTime.now();
    if (type == 'forward') {
      totalForwardEvents.value++;
      _forwardCount++;
    } else if (type == 'backward') {
      totalBackwardEvents.value++;
    }

    if (_startTime == 0) _startTime = now.millisecondsSinceEpoch;
    final elapsed = (now.millisecondsSinceEpoch - _startTime) / 1000 / 60;
    if (elapsed > 0) {
      avgSpeed.value = _forwardCount / elapsed;
    }

    final history = List<SpeedDataPoint>.from(speedHistory.value);
    history.add(
      SpeedDataPoint(
        time: now,
        forward: totalForwardEvents.value,
        backward: totalBackwardEvents.value,
      ),
    );
    if (history.length > 100) history.removeAt(0);
    speedHistory.value = history;

    logger.log(LogEntry(time: now, event: type, status: 'sent'));
  }

  void replayLogs() {
    for (final entry in logger.entries.value) {
      if (entry.event == 'forward' || entry.event == 'next_page') {
        totalForwardEvents.value++;
        _forwardCount++;
      } else if (entry.event == 'backward' || entry.event == 'prev_page') {
        totalBackwardEvents.value++;
      }
    }
    final now = DateTime.now();
    final firstEntry = logger.entries.value.isNotEmpty
        ? logger.entries.value.first
        : null;
    if (firstEntry != null) {
      _startTime = firstEntry.time.millisecondsSinceEpoch;
      final elapsed = (now.millisecondsSinceEpoch - _startTime) / 1000 / 60;
      if (elapsed > 0) {
        avgSpeed.value = _forwardCount / elapsed;
      }
    }
  }

  void resetStats() {
    totalForwardEvents.value = 0;
    totalBackwardEvents.value = 0;
    avgSpeed.value = 0.0;
    speedHistory.value = [];
    _startTime = 0;
    _forwardCount = 0;
  }
}

class SpeedDataPoint {
  final DateTime time;
  final int forward;
  final int backward;

  SpeedDataPoint({
    required this.time,
    required this.forward,
    required this.backward,
  });
}
