import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:deup/common/index.dart';
import 'package:deup/models/index.dart';
import 'package:deup/helper/index.dart';
import 'package:deup/services/index.dart';
import 'package:deup/database/entity/index.dart';
import 'package:deup/pages/plugin/components/add_server_component.dart';
import 'package:deup/pages/homepage/homepage_controller.dart';

class PluginController extends GetxController {
  final serverList = <ServerEntity>[].obs;
  final isFirstLoading = true.obs;
  final keyword = ''.obs;

  final PluginEntity plugin =
      Get.arguments != null ? Get.arguments['plugin'] ?? '' : '';

  Map<String, PluginInputModel> inputs = {};
  PluginConfigModel config = PluginConfigModel();
  final ScrollController scrollController = ScrollController();
  final pluginDao = DatabaseService.to.database.pluginDao;
  final serverDao = DatabaseService.to.database.serverDao;

  @override
  void onInit() async {
    try {
      config = PluginConfigModel.fromJson(json.decode(plugin.config));
      inputs = (json.decode(plugin.inputs) as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, PluginInputModel.fromJson(value)));
    } catch (e) {
      CommonUtils.logger.e(e);
    }

    await getServerList();
    isFirstLoading.value = false;
    super.onInit();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  Future<void> getServerList() async {
    final _serverList = await serverDao.findServerByPluginId(plugin.id);

    List<ServerEntity> _searchList = [];
    if (keyword.isNotEmpty) {
      _searchList = _serverList.where((server) {
        return server.name.toLowerCase().contains(keyword.toLowerCase());
      }).toList();
    }

    serverList.value = _searchList.isEmpty ? _serverList : _searchList;
    serverList.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void addServerBottomSheet() async {
    await BottomSheetHelper.showBottomSheet(
        AddServerComponent(plugin: plugin, config: config, inputs: inputs));

    await Future.delayed(Duration(milliseconds: 500), () => getServerList());
  }

  void moreActionSheet(String serverId) async {
    final server = await serverDao.findServerById(serverId);
    final value = await showModalActionSheet(
      context: Get.overlayContext!,
      title: server?.name,
      actions: [
        SheetAction(label: '编辑', key: 'edit'),
        SheetAction(label: '添加到主屏幕', key: 'addShortcut'),
        SheetAction(label: '清空历史记录', key: 'clear', isDestructiveAction: true),
        SheetAction(label: '删除', key: 'delete', isDestructiveAction: true),
      ],
      cancelLabel: '取消',
    );
    if (value == null) return;

    switch (value) {
      case 'edit':
        BottomSheetHelper.showBottomSheet(
          AddServerComponent(
            plugin: plugin,
            config: config,
            inputs: inputs,
            server: await serverDao.findServerById(serverId),
          ),
        ).then((value) => getServerList());
        break;
      case 'addShortcut':
        final _server = await serverDao.findServerById(serverId);
        if (_server != null) {
          await Get.find<HomepageController>()
              .addShortcut(plugin: plugin, server: _server);
          SmartDialog.showToast('已添加到主屏幕');
        }
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
        final _database = DatabaseService.to.database;
        await _database.progressDao.deleteProgressByServerId(serverId);
        await _database.historyDao.deleteHistoryByServerId(serverId);
        SmartDialog.showToast('清空成功');
        break;
      case 'delete':
        await deleteServer(serverId);
        break;
    }
  }

  Future<void> viewServerPopup(String serverId) async {
    final server = await serverDao.findServerById(serverId);
    final _inputs = json.decode(
            await ServerStorage(serverId).get('__DEUP_INPUTS__') ?? '{}')
        as Map<String, dynamic>;

    await showOkAlertDialog(
      context: Get.overlayContext!,
      title: server?.name,
      message: _inputs
          .map((key, value) => MapEntry(key, '$key: $value'))
          .values
          .join('\n'),
    );
  }

  Future<void> deleteServer(String serverId) async {
    final ok = await showOkCancelAlertDialog(
      context: Get.overlayContext!,
      title: '提示',
      message: '确定要删除该服务吗？',
      okLabel: '删除',
      cancelLabel: '取消',
    );
    if (ok != OkCancelResult.ok) return;
    await serverDao.deleteServerById(serverId);
    await ShortcutService.to.removeByServerId(serverId);
    final _database = DatabaseService.to.database;
    await _database.progressDao.deleteProgressByServerId(serverId);
    await _database.historyDao.deleteHistoryByServerId(serverId);
    await getServerList();
  }
}
