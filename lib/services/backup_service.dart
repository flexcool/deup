import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:get_storage/get_storage.dart';

import 'package:deup/database/entity/index.dart';
import 'package:deup/services/index.dart';
import 'package:deup/models/index.dart';
import 'package:deup/common/index.dart';

class BackupService {
  static final BackupService _instance = BackupService._();
  static BackupService get to => _instance;
  BackupService._();

  static const int _version = 1;

  Future<void> exportBackup({bool excludeStorage = false}) async {
    try {
      SmartDialog.showLoading(msg: '导出中...');

      final plugins =
          await DatabaseService.to.database.pluginDao.findAllPlugin();
      final servers = <ServerEntity>[];
      for (final plugin in plugins) {
        final s = await DatabaseService.to.database.serverDao
            .findServerByPluginId(plugin.id);
        servers.addAll(s);
      }
      final customFunctions = CustomFunctionService.to.getAll();
      final shortcuts = ShortcutService.to.getAll();

      final data = <String, dynamic>{
        'plugins': plugins.map(_pluginToMap).toList(),
        'servers': servers.map(_serverToMap).toList(),
        'customFunctions': customFunctions.map((e) => e.toJson()).toList(),
        'shortcuts': shortcuts.map((e) => e.toJson()).toList(),
      };

      // 默认导出完整 Storage（含参数值）；开启"不导出内部Storage"后跳过
      if (!excludeStorage) {
        final storageList = <Map<String, dynamic>>[];
        for (final server in servers) {
          final storage = await DatabaseService.to.database.storageDao
              .findStorageByServerId(server.id);
          if (storage != null) {
            storageList.add(_encryptStorage(storage));
          }
        }
        data['storage'] = storageList;
      }

      final backup = {
        'version': _version,
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/deup_backup.json');
      await file.writeAsString(json.encode(backup));

      SmartDialog.dismiss();
      await Share.shareXFiles([XFile(file.path)], text: 'Deup 备份');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('导出失败: $e');
    }
  }

  Future<void> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;

      SmartDialog.showLoading(msg: '导入中...');

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final backup = json.decode(content) as Map<String, dynamic>;

      final version = backup['version'] as int?;
      if (version == null || version != _version) {
        SmartDialog.dismiss();
        SmartDialog.showToast('不支持的备份文件版本');
        return;
      }

      final data = backup['data'] as Map<String, dynamic>;
      final pluginCount = (data['plugins'] as List?)?.length ?? 0;
      final serverCount = (data['servers'] as List?)?.length ?? 0;
      final funcCount = (data['customFunctions'] as List?)?.length ?? 0;
      final shortcutCount = (data['shortcuts'] as List?)?.length ?? 0;
      final storageCount = (data['storage'] as List?)?.length ?? 0;
      final inputCount = (data['inputs'] as List?)?.length ?? 0;

      SmartDialog.dismiss();

      final ok = await showOkCancelAlertDialog(
        context: Get.overlayContext!,
        title: '导入备份',
        message: '即将导入:\n'
            '• $pluginCount 个插件\n'
            '• $serverCount 个服务器\n'
            '• $funcCount 个自定义函数\n'
            '• $shortcutCount 个快捷方式\n'
            '${inputCount > 0 ? '• $inputCount 个参数值\n' : ''}'
            '${storageCount > 0 ? '• $storageCount 个Storage记录\n' : ''}'
            '\n已有数据将被覆盖，是否继续？',
        okLabel: '导入',
        cancelLabel: '取消',
      );
      if (ok != OkCancelResult.ok) return;

      SmartDialog.showLoading(msg: '导入中...');

      await _importPlugins(data['plugins'] as List? ?? []);
      await _importServers(data['servers'] as List? ?? []);
      await _importCustomFunctions(data['customFunctions'] as List? ?? []);
      await _importShortcuts(data['shortcuts'] as List? ?? []);
      if (data.containsKey('inputs')) {
        await _importInputs(data['inputs'] as List? ?? []);
      }
      if (data.containsKey('storage')) {
        await _importStorage(data['storage'] as List? ?? []);
      }

      SmartDialog.dismiss();
      SmartDialog.showToast('导入成功，建议重启应用');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('导入失败: $e');
    }
  }

  Map<String, dynamic> _pluginToMap(PluginEntity e) => {
        'id': e.id,
        'created_at': e.createdAt,
        'updated_at': e.updatedAt,
        'config': e.config,
        'inputs': e.inputs,
        'script': e.script,
        'link': e.link,
      };

  Map<String, dynamic> _serverToMap(ServerEntity e) => {
        'id': e.id,
        'created_at': e.createdAt,
        'updated_at': e.updatedAt,
        'name': e.name,
        'plugin_id': e.pluginId,
      };

  Map<String, dynamic> _encryptStorage(StorageEntity e) => {
        'id': e.id,
        'server_id': e.serverId,
        'data': base64.encode(utf8.encode(e.data)),
      };

  Future<void> _importPlugins(List<dynamic> list) async {
    for (final item in list) {
      final m = Map<String, dynamic>.from(item);
      final id = m['id'] as String;
      final existing =
          await DatabaseService.to.database.pluginDao.findPluginById(id);
      if (existing != null) {
        await DatabaseService.to.database.pluginDao.deletePluginById(id);
      }
      await DatabaseService.to.database.pluginDao.insertPlugin(PluginEntity(
        id: id,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
        config: m['config'] as String,
        inputs: m['inputs'] as String,
        script: m['script'] as String,
        link: m['link'] as String?,
      ));
    }
  }

  Future<void> _importServers(List<dynamic> list) async {
    for (final item in list) {
      final m = Map<String, dynamic>.from(item);
      final id = m['id'] as String;
      final existing =
          await DatabaseService.to.database.serverDao.findServerById(id);
      if (existing != null) {
        await DatabaseService.to.database.serverDao.deleteServerById(id);
      }
      await DatabaseService.to.database.serverDao.insertServer(ServerEntity(
        id: id,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
        name: m['name'] as String,
        pluginId: m['plugin_id'] as String,
      ));
    }
  }

  Future<void> _importCustomFunctions(List<dynamic> list) async {
    CustomFunctionService.to.clear();
    for (final item in list) {
      await CustomFunctionService.to.add(
        CustomFunctionModel.fromJson(Map<String, dynamic>.from(item)),
      );
    }
  }

  Future<void> _importShortcuts(List<dynamic> list) async {
    final box = GetStorage();
    box.remove('__DEUP_SHORTCUTS__');
    for (final item in list) {
      await ShortcutService.to.add(
        ShortcutModel.fromJson(Map<String, dynamic>.from(item)),
      );
    }
  }

  Future<void> _importInputs(List<dynamic> list) async {
    for (final item in list) {
      final m = Map<String, dynamic>.from(item);
      final serverId = m['server_id'] as String;
      final data = m['data'];
      if (data == null) continue;
      await ServerStorage(serverId).set('__DEUP_INPUTS__', data);
    }
  }

  Future<void> _importStorage(List<dynamic> list) async {
    for (final item in list) {
      final m = Map<String, dynamic>.from(item);
      final serverId = m['server_id'] as String;
      final existing = await DatabaseService.to.database.storageDao
          .findStorageByServerId(serverId);
      if (existing != null) {
        await DatabaseService.to.database.storageDao
            .deleteStorageByServerId(serverId);
      }
      final data = utf8.decode(base64.decode(m['data'] as String));
      await DatabaseService.to.database.storageDao.insertStorage(
        StorageEntity(
          id: m['id'] as String,
          serverId: serverId,
          data: data,
          createdAt: m['created_at'] as int? ??
              DateTime.now().millisecondsSinceEpoch,
          updatedAt: m['updated_at'] as int? ??
              DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }
}
