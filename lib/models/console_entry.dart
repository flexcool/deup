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
