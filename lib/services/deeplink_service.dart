import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:deup/common/index.dart';
import 'package:deup/routes/app_pages.dart';
import 'package:deup/services/index.dart';
import 'package:deup/database/entity/index.dart';
import 'package:deup/pages/homepage/homepage_controller.dart';
import 'package:deup/pages/detail/detail_view.dart';

class DeeplinkService extends GetxService {
  static DeeplinkService get to => Get.find();

  // Init - App running
  Future<DeeplinkService> init() async {
    try {
      uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          Timer(
            const Duration(milliseconds: 200),
            () async => _handleUri(uri),
          );
        }
      });
    } on PlatformException {
    } on FormatException {}

    return this;
  }

  /// App wake
  Future<void> getAppWakeLink() async {
    try {
      final String? initialLink = await getInitialLink();
      if (initialLink != null) {
        await _handleUri(Uri.parse(initialLink));
      }
    } on PlatformException {
    } on FormatException {}
  }

  /// Route incoming URI to the right handler
  Future<void> _handleUri(Uri uri) async {
    // https://deup.io/plugins/add?url=...
    if (uri.host == 'deup.io' && uri.path == '/plugins/add') {
      final String? url = uri.queryParameters['url'];
      if (url != null) addPlugin(url);
      return;
    }

    // Deup://addScript?url=...
    if (uri.scheme == 'Deup' && uri.path == '/addScript') {
      final String? url = uri.queryParameters['url'];
      if (url != null) addPlugin(url);
      return;
    }

    // Deup://run/{pluginId}  or  Deup://run/{pluginId}/{serverId}
    if (uri.scheme == 'Deup' && uri.path.startsWith('/run/')) {
      final segments = uri.pathSegments;
      if (segments.length >= 2) {
        final pluginId = segments[1];
        final serverId = segments.length >= 3 ? segments[2] : null;
        _runPlugin(pluginId, serverId);
      }
      return;
    }
  }

  /// Execute plugin directly
  Future<void> _runPlugin(String pluginId, String? serverId) async {
    final plugin = await DatabaseService.to.database.pluginDao
        .findPluginById(pluginId);
    if (plugin == null) {
      SmartDialog.showToast('插件不存在');
      return;
    }

    try {
      ServerEntity? server;
      if (serverId != null) {
        server = await DatabaseService.to.database.serverDao
            .findServerById(serverId);
      }

      if (server == null) {
        final servers = await DatabaseService.to.database.serverDao
            .findServerByPluginId(pluginId);
        if (servers.isNotEmpty) server = servers.first;
      }

      SmartDialog.showLoading(msg: '初始化中...');
      await PluginRuntimeService.to.initialize(plugin.script, server: server);
      SmartDialog.dismiss();
      Get.to(() => DetailPage(), routeName: '${Routes.DETAIL}');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('启动失败');
    }
  }

  /// Add plugin
  ///
  /// [url] - Plugin url
  Future<void> addPlugin(String url) async {
    final ok = await showOkCancelAlertDialog(
      context: Get.context!,
      title: '提示',
      message: '您有新的插件, 确认添加吗？',
      okLabel: '确认',
      cancelLabel: '取消',
    );
    if (ok != OkCancelResult.ok) return;

    // 获取当前插件信息
    final _server = PluginRuntimeService.to.server;
    final _plugin = PluginRuntimeService.to.plugin;

    // 获取插件信息
    try {
      SmartDialog.showLoading(msg: '加载中...');
      final response = await DioService.to.dio.get(url);
      await PluginRuntimeService.to.initialize(response.data);
      final config = await PluginRuntimeService.to.config;
      final inputs = await PluginRuntimeService.to.inputs;

      // 提示用户是否添加插件
      SmartDialog.dismiss();
      final ok = await showOkCancelAlertDialog(
        context: Get.context!,
        title: '提示',
        message: '确定要添加 <${config.name}> 插件吗？',
        okLabel: '确认',
        cancelLabel: '取消',
      );
      if (ok != OkCancelResult.ok) return;

      final _now = DateTime.now().millisecondsSinceEpoch;
      final pluginId = CommonUtils.generateUuid();
      await DatabaseService.to.database.pluginDao.insertPlugin(
        PluginEntity(
          id: pluginId,
          createdAt: _now,
          updatedAt: _now,
          config: json.encode(config),
          inputs: json.encode(inputs),
          link: url,
          script: response.data,
        ),
      );

      // 更新插件列表
      Get.find<HomepageController>().getPluginList();
      SmartDialog.showToast('添加成功');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast('添加失败');
    }

    // 重置插件
    if (_plugin != null && _server != null) {
      await PluginRuntimeService.to.initialize(_plugin.script, server: _server);
    }
  }
}
