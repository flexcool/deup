import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'package:deup/database/entity/index.dart';
import 'package:deup/services/index.dart';

class ShortcutDao {
  Database get _db => DatabaseService.to.database.database;

  Future<List<ShortcutEntity>> findAllShortcut() async {
    final rows = await _db.query('shortcut', orderBy: 'sort_order ASC');
    return rows.map(_toEntity).toList();
  }

  Future<ShortcutEntity?> findShortcutById(String id) async {
    final rows = await _db.query('shortcut', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : _toEntity(rows.first);
  }

  Future<List<ShortcutEntity>> findShortcutByPluginId(String pluginId) async {
    final rows = await _db.query('shortcut',
        where: 'plugin_id = ?', whereArgs: [pluginId]);
    return rows.map(_toEntity).toList();
  }

  Future<void> insertShortcut(ShortcutEntity shortcut) async {
    await _db.insert('shortcut', _toRow(shortcut));
  }

  Future<void> updateShortcut(ShortcutEntity shortcut) async {
    await _db.update('shortcut', _toRow(shortcut),
        where: 'id = ?', whereArgs: [shortcut.id]);
  }

  Future<void> deleteShortcutById(String id) async {
    await _db.delete('shortcut', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteShortcutByPluginId(String pluginId) async {
    await _db.delete('shortcut',
        where: 'plugin_id = ?', whereArgs: [pluginId]);
  }

  Future<void> deleteShortcutByServerId(String serverId) async {
    await _db.delete('shortcut',
        where: 'server_id = ?', whereArgs: [serverId]);
  }

  Future<int> getNextSortOrder() async {
    final result =
        await _db.rawQuery('SELECT COALESCE(MAX(sort_order), -1) + 1 AS next FROM shortcut');
    return result.first['next'] as int;
  }

  ShortcutEntity _toEntity(Map<String, Object?> row) => ShortcutEntity(
        id: row['id'] as String,
        pluginId: row['plugin_id'] as String,
        serverId: row['server_id'] as String?,
        label: row['label'] as String,
        icon: row['icon'] as String?,
        color: row['color'] as String?,
        background: row['background'] as String?,
        sortOrder: row['sort_order'] as int,
        createdAt: row['created_at'] as int,
      );

  Map<String, dynamic> _toRow(ShortcutEntity e) => {
        'id': e.id,
        'plugin_id': e.pluginId,
        'server_id': e.serverId,
        'label': e.label,
        'icon': e.icon,
        'color': e.color,
        'background': e.background,
        'sort_order': e.sortOrder,
        'created_at': e.createdAt,
      };
}
