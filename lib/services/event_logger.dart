import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:kaeru/kaeru.dart';

class LogEntry {
  final DateTime time;
  final String event;
  final String status;
  final String? detail;

  LogEntry({
    required this.time,
    required this.event,
    required this.status,
    this.detail,
  });

  Map<String, dynamic> toJson() => {
        'time': time.toIso8601String(),
        'event': event,
        'status': status,
        'detail': detail,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
        time: DateTime.parse(json['time']),
        event: json['event'],
        status: json['status'],
        detail: json['detail'],
      );
}

class EventLogger {
  final Ref<List<LogEntry>> entries = Ref([]);
  File? _logFile;
  final int _maxEntries = 1000;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/event_logs.jsonl');
    await _loadExisting();
  }

  Future<void> _loadExisting() async {
    if (_logFile == null || !await _logFile!.exists()) return;
    final lines = await _logFile!.readAsLines();
    for (final line in lines.reversed.take(_maxEntries)) {
      if (line.trim().isEmpty) continue;
      try {
        final entry =
            LogEntry.fromJson(json.decode(line) as Map<String, dynamic>);
        final list = List<LogEntry>.from(entries.value);
        list.add(entry);
        entries.value = list;
      } catch (_) {}
    }
  }

  void log(LogEntry entry) {
    final list = List<LogEntry>.from(entries.value);
    list.add(entry);
    if (list.length > _maxEntries) {
      list.removeAt(0);
    }
    entries.value = list;
    _appendToFile(entry);
  }

  Future<void> _appendToFile(LogEntry entry) async {
    if (_logFile == null) return;
    await _logFile!.writeAsString(
      '${json.encode(entry.toJson())}\n',
      mode: FileMode.append,
    );
  }
}
