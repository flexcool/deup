import 'dart:io';

import 'package:get/get.dart';
import 'package:floor/floor.dart';

import 'package:deup/database/database.dart';
import 'package:deup/database/dao/index.dart';

// Database used floor
class DatabaseService extends GetxService {
  static DatabaseService get to => Get.find();

  // AppDatabase
  late DeupDatabase _database;
  DeupDatabase get database => _database;

  // ShortcutDao (raw SQL, no Floor codegen)
  late ShortcutDao _shortcutDao;
  ShortcutDao get shortcutDao => _shortcutDao;

  // Database name
  String name = 'deup_database.db';

  // Database migration1to2
  final migration1to2 = Migration(1, 2, (database) async {
    await database.execute(
        'CREATE TABLE IF NOT EXISTS `history` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `server_id` TEXT NOT NULL, `updated_at` INTEGER NOT NULL, `object_id` TEXT NOT NULL, `data` TEXT NOT NULL)');
    await database.execute(
        'CREATE UNIQUE INDEX `index_history_server_id_object_id` ON `history` (`server_id`, `object_id`)');
    await database.execute(
        'CREATE INDEX `index_history_updated_at` ON `history` (`updated_at`)');
  });

  // Init
  Future<DatabaseService> init() async {
    _database = await $FloorDeupDatabase
        .databaseBuilder(name)
        .addMigrations([migration1to2]).build();

    // Ensure shortcut table exists
    await _database.database.execute(
      'CREATE TABLE IF NOT EXISTS `shortcut` ('
      '`id` TEXT NOT NULL,'
      '`plugin_id` TEXT NOT NULL,'
      '`server_id` TEXT,'
      '`label` TEXT NOT NULL,'
      '`icon` TEXT,'
      '`color` TEXT,'
      '`background` TEXT,'
      '`sort_order` INTEGER NOT NULL DEFAULT 0,'
      '`created_at` INTEGER NOT NULL,'
      'PRIMARY KEY (`id`)'
      ')',
    );

    _shortcutDao = ShortcutDao();

    return this;
  }

  // 获取大小
  Future<int> getSize() async {
    return File(await sqfliteDatabaseFactory.getDatabasePath(name)).length();
  }
}
