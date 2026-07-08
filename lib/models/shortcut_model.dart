import 'package:get_storage/get_storage.dart';

class ShortcutModel {
  final String id;
  final String pluginId;
  final String? serverId;
  final String label;
  final String? icon;
  final String? color;
  final String? background;
  final int sortOrder;
  final int createdAt;

  ShortcutModel({
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'plugin_id': pluginId,
        'server_id': serverId,
        'label': label,
        'icon': icon,
        'color': color,
        'background': background,
        'sort_order': sortOrder,
        'created_at': createdAt,
      };

  factory ShortcutModel.fromJson(Map<String, dynamic> json) => ShortcutModel(
        id: json['id'] as String,
        pluginId: json['plugin_id'] as String,
        serverId: json['server_id'] as String?,
        label: json['label'] as String,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
        background: json['background'] as String?,
        sortOrder: json['sort_order'] as int,
        createdAt: json['created_at'] as int,
      );
}

class ShortcutService {
  static final ShortcutService _instance = ShortcutService._();
  static ShortcutService get to => _instance;
  ShortcutService._();

  static const _key = '__DEUP_SHORTCUTS__';
  final _box = GetStorage();

  List<ShortcutModel> getAll() {
    final data = _box.read<List>(_key) ?? [];
    return data
        .map((e) => ShortcutModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _save(List<ShortcutModel> list) async {
    await _box.write(_key, list.map((e) => e.toJson()).toList());
  }

  Future<void> add(ShortcutModel shortcut) async {
    final list = getAll();
    list.add(shortcut);
    await _save(list);
  }

  Future<void> remove(String id) async {
    final list = getAll()..removeWhere((s) => s.id == id);
    await _save(list);
  }

  Future<void> removeByPluginId(String pluginId) async {
    final list = getAll()..removeWhere((s) => s.pluginId == pluginId);
    await _save(list);
  }

  Future<void> removeByServerId(String serverId) async {
    final list = getAll()..removeWhere((s) => s.serverId == serverId);
    await _save(list);
  }

  int getNextSortOrder() {
    final list = getAll();
    if (list.isEmpty) return 0;
    return list.map((s) => s.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }
}
