import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:deup/models/index.dart';
import 'package:deup/common/index.dart';
import 'package:deup/services/index.dart';
import 'package:deup/routes/app_pages.dart';
import 'package:deup/database/entity/index.dart';
import 'package:deup/pages/detail/detail_view.dart';

class HomepageController extends GetxController {
  final pluginList = <PluginEntity>[].obs;
  final shortcutList = <ShortcutEntity>[].obs;
  final isFirstLoading = true.obs;
  final keyword = ''.obs;

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() async {
    super.onInit();

    Timer(
      const Duration(milliseconds: 300),
      () async => await DeeplinkService.to.getAppWakeLink(),
    );

    await loadShortcuts();
    await getPluginList();
    isFirstLoading.value = false;
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  /// 获取插件列表
  Future<void> getPluginList() async {
    final _pluginList =
        await DatabaseService.to.database.pluginDao.findAllPlugin();

    List<PluginEntity> _searchList = [];
    if (keyword.isNotEmpty) {
      _searchList = _pluginList.where((plugin) {
        final _config = PluginConfigModel.fromJson(json.decode(plugin.config));
        final _name = _config.name?.toLowerCase() ?? '';
        return _name.contains(keyword.toLowerCase());
      }).toList();
    }

    pluginList.value = _searchList.isEmpty ? _pluginList : _searchList;
    pluginList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// 加载快捷入口
  Future<void> loadShortcuts() async {
    shortcutList.value =
        await DatabaseService.to.shortcutDao.findAllShortcut();
  }

  /// 添加快捷入口
  Future<void> addShortcut({
    required PluginEntity plugin,
    ServerEntity? server,
  }) async {
    final config = PluginConfigModel.fromJson(json.decode(plugin.config));
    final existing = await DatabaseService.to.shortcutDao
        .findShortcutByPluginId(plugin.id);
    if (server == null && existing.isNotEmpty) return;

    if (server != null && existing.any((s) => s.serverId == server.id)) return;

    final sortOrder = await DatabaseService.to.shortcutDao.getNextSortOrder();
    await DatabaseService.to.shortcutDao.insertShortcut(
      ShortcutEntity(
        id: CommonUtils.generateUuid(),
        pluginId: plugin.id,
        serverId: server?.id,
        label: server?.name ?? config.name ?? 'Untitled',
        icon: config.logo,
        color: config.color,
        background: config.background is List
            ? json.encode(config.background)
            : config.background as String?,
        sortOrder: sortOrder,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await loadShortcuts();
  }

  /// 删除快捷入口
  Future<void> removeShortcut(String id) async {
    await DatabaseService.to.shortcutDao.deleteShortcutById(id);
    await loadShortcuts();
  }

  /// 点击快捷入口
  void onShortcutTap(ShortcutEntity shortcut) async {
    final plugin = await DatabaseService.to.database.pluginDao
        .findPluginById(shortcut.pluginId);
    if (plugin == null) {
      SmartDialog.showToast('插件不存在');
      await removeShortcut(shortcut.id);
      return;
    }

    ServerEntity? server;
    if (shortcut.serverId != null) {
      server = await DatabaseService.to.database.serverDao
          .findServerById(shortcut.serverId!);
    }

    goDetailPage(plugin, server: server);
  }

  /// 插件点击事件
  void onPluginTap(PluginEntity plugin) async {
    final config = PluginConfigModel.fromJson(json.decode(plugin.config));

    if (config.hasInput == null || config.hasInput == true) {
      Get.toNamed(Routes.PLUGIN, arguments: {'plugin': plugin});
      return;
    }

    final _serverList = await DatabaseService.to.database.serverDao
        .findServerByPluginId(plugin.id);
    if (_serverList.isNotEmpty) {
      goDetailPage(plugin, server: _serverList.first);
      return;
    }

    final _server = ServerEntity(
      id: CommonUtils.generateUuid(),
      name: config.name ?? 'Untitled',
      pluginId: plugin.id,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    await DatabaseService.to.database.serverDao.insertServer(_server);
    goDetailPage(plugin, server: _server);
  }

  void goDetailPage(PluginEntity plugin, {ServerEntity? server}) async {
    try {
      SmartDialog.showLoading(msg: '初始化中...');
      await PluginRuntimeService.to.initialize(plugin.script, server: server);
      SmartDialog.dismiss();
      Get.to(() => DetailPage(), routeName: '${Routes.DETAIL}');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('初始化失败, 请重试');
    }
  }

  void moreActionSheet(String pluginId) async {
    final _plugin = pluginList.firstWhere((plugin) => plugin.id == pluginId);
    final _config = PluginConfigModel.fromJson(json.decode(_plugin.config));

    final value = await showModalActionSheet(
      context: Get.overlayContext!,
      title: _config.name ?? '',
      actions: [
        SheetAction(label: '编辑', key: 'edit'),
        if (_plugin.link != null && _plugin.link!.isNotEmpty)
          SheetAction(label: '更新', key: 'update'),
        SheetAction(label: '添加到主屏幕', key: 'addShortcut'),
        if (_config.hasInput != null && _config.hasInput == false)
          SheetAction(label: '清空历史记录', key: 'clear', isDestructiveAction: true),
        SheetAction(label: '删除', key: 'delete', isDestructiveAction: true),
      ],
      cancelLabel: '取消',
    );
    if (value == null) return;

    switch (value) {
      case 'edit':
        Get.toNamed(Routes.CODE_EDITOR, arguments: {
          'pluginId': pluginId,
        });
        break;
      case 'update':
        await updatePlugin(_plugin);
        break;
      case 'addShortcut':
        await addShortcut(plugin: _plugin);
        SmartDialog.showToast('已添加到主屏幕');
        break;
      case 'clear':
        final ok = await showOkCancelAlertDialog(
          context: Get.overlayContext!,
          title: '提示',
          message: '确定要清空历史记录吗？',
          okLabel: '清空',
          cancelLabel: '取消',
        );
        if (ok != OkCancelResult.ok) return;

        final _serverList = await DatabaseService.to.database.serverDao
            .findServerByPluginId(_plugin.id);
        if (_serverList.isNotEmpty) {
          final _serverId = _serverList.first.id;
          final _database = DatabaseService.to.database;
          await _database.progressDao.deleteProgressByServerId(_serverId);
          await _database.historyDao.deleteHistoryByServerId(_serverId);
          SmartDialog.showToast('清空成功');
        }
        break;
      case 'delete':
        await deletePlugin(pluginId);
        break;
    }
  }

  Future<void> updatePlugin(PluginEntity plugin) async {
    final ok = await showOkCancelAlertDialog(
      context: Get.context!,
      title: '提示',
      message: '确认要更新该插件吗？',
      okLabel: '确认',
      cancelLabel: '取消',
    );
    if (ok != OkCancelResult.ok) return;

    try {
      SmartDialog.showLoading(msg: '更新中...');
      final response = await DioService.to.dio.get(plugin.link!);
      await PluginRuntimeService.to.initialize(response.data);
      final config = await PluginRuntimeService.to.config;
      final inputs = await PluginRuntimeService.to.inputs;

      final _now = DateTime.now().millisecondsSinceEpoch;
      await DatabaseService.to.database.pluginDao.updatePlugin(PluginEntity(
        id: plugin.id,
        createdAt: plugin.createdAt,
        updatedAt: _now,
        config: json.encode(config),
        inputs: json.encode(inputs),
        link: plugin.link,
        script: response.data,
      ));

      await getPluginList();
      SmartDialog.dismiss();
      SmartDialog.showToast('更新成功');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('更新失败');
    }
  }

  Future<void> deletePlugin(String pluginId) async {
    final ok = await showOkCancelAlertDialog(
      context: Get.overlayContext!,
      title: '提示',
      message: '确定要删除该插件吗？',
      okLabel: '删除',
      cancelLabel: '取消',
    );
    if (ok != OkCancelResult.ok) return;
    await DatabaseService.to.database.pluginDao.deletePluginById(pluginId);
    await DatabaseService.to.shortcutDao.deleteShortcutByPluginId(pluginId);
    await loadShortcuts();
    await getPluginList();
  }
}
