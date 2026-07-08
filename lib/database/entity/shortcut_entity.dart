class ShortcutEntity {
  final String id;
  final String pluginId;
  final String? serverId;
  final String label;
  final String? icon;
  final String? color;
  final String? background;
  final int sortOrder;
  final int createdAt;

  ShortcutEntity({
    required this.id,
    required this.pluginId,
    this.serverId,
    required this.label,
    this.icon,
    this.color,
    this.background,
    required this.sortOrder,
    required this.createdAt,
  });
}
