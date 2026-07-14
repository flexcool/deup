import 'package:get/get.dart';

class ConsoleEntry {
  final String level;
  final String message;
  final DateTime timestamp;

  ConsoleEntry({
    required this.level,
    required this.message,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ConsoleCapture {
  static final entries = <ConsoleEntry>[].obs;

  static void add(String level, String message) {
    entries.add(ConsoleEntry(level: level, message: message));
  }

  static void clear() {
    entries.clear();
  }
}
