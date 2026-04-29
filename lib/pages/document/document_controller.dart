import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:highlight/languages/all.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:deup/helper/index.dart';
import 'package:deup/models/index.dart';
import 'package:deup/common/index.dart';
import 'package:deup/services/index.dart';
import 'package:deup/constants/index.dart';

class DocumentController extends GetxController {
  final object = ObjectModel().obs;
  final isLoading = true.obs; // 是否正在加载
  final progress = 0.0.obs;
  final data = ''.obs;
  final objects = <ObjectModel>[].obs;
  final currentIndex = 0.obs;
  final isFullScreen = false.obs; // WebView 全屏状态
  
  // 全屏 Overlay
  OverlayEntry? _fullscreenOverlay;
  InAppWebViewController? _webViewController;

  // 获取参数
  final String id = Get.arguments['id'] ?? '';

  // 文件类型
  String get fileType =>
      p.extension(object.value.name ?? '').replaceAll('.', '').toLowerCase();

  // 是否是代码类型文件
  CodeController? codeController;

  // WebView
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings options = InAppWebViewSettings(
    transparentBackground: !Get.isDarkMode,
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    allowFileAccessFromFileURLs: true,
    allowUniversalAccessFromFileURLs: true,
    useHybridComposition: true,
    allowsInlineMediaPlayback: true,
    allowsPictureInPictureMediaPlayback: true,
  );

  @override
  void onInit() async {
    super.onInit();

    // 过滤掉非文档类型
    List<ObjectModel> _objects = Get.arguments['objects'] ?? [];
    objects.value = _objects
        .where((o) =>
            PreviewHelper.isDocument(o.name ?? '') ||
            o.type == ObjectType.WEBVIEW)
        .toList();

    // 获取对象信息
    final _object = Get.arguments['object'] ?? ObjectModel();
    await getObjectInfo(_object);
    currentIndex.value = objects.indexWhere((e) => e.id == id);

    // 加载完成
    isLoading.value = false;
    DownloadService.to.bindBackgroundIsolate((id, status, progress) {});
  }

  /// 获取对象信息
  ///
  /// [objectModel] 对象信息
  Future<void> getObjectInfo(ObjectModel objectModel) async {
    isLoading.value = true;
    progress.value = 0.0;
    data.value = '';

    try {
      final _tmp = await PluginRuntimeService.to.get(
        objectModel,
      );
      if (_tmp == null) throw '无法获取对象信息';
      object.value = _tmp;
    } catch (e) {
      SmartDialog.showToast(e.toString());
      return;
    }

    // 如果是代码类型文件
    if (PreviewHelper.isCode(object.value.name ?? '') &&
        object.value.type == ObjectType.DOCUMENT) {
      final response = await DioService.to.dio.get(
        object.value.url!,
        options: Options(headers: ObjectHelper.getHeaders(object.value)),
      );

      data.value = response.data.toString();
      codeController = CodeController(
        text: data.value,
        language: allLanguages[kCodeLanguages[fileType]] ?? javascript,
      );
    }

    // 如果能够解析出数据
    final _blob = CommonUtils.getBlobData(object.value.url ?? '');
    if (_blob != null) data.value = utf8.decode(_blob);
    isLoading.value = false;
  }

  /// 下载文件
  void download() async {
    DownloadHelper.file(object.value);
  }

  /// WebView 加载进度
  onProgressChanged(controller, p) {
    progress.value = p / 100;
  }

  /// 进入全屏
  void onEnterFullscreen(InAppWebViewController controller) async {
    _webViewController = controller;
    isFullScreen.value = true;
    
    // 获取当前的 URL 和数据
    final currentUrl = object.value.url ?? '';
    final currentData = data.value;
    final headers = ObjectHelper.getHeaders(object.value);
    
    // 创建全屏 Overlay
    _fullscreenOverlay = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black,
        child: SafeArea(
          child: InAppWebView(
            key: webViewKey,
            initialUrlRequest: currentData.isEmpty
                ? URLRequest(
                    url: WebUri(currentUrl),
                    headers: headers,
                  )
                : null,
            initialData: currentData.isNotEmpty
                ? InAppWebViewInitialData(data: currentData)
                : null,
            initialSettings: options,
            onExitFullscreen: (ctrl) => onExitFullscreen(ctrl),
            onProgressChanged: onProgressChanged,
          ),
        ),
      ),
    );
    
    Overlay.of(Get.context!).insert(_fullscreenOverlay!);
    update();
  }

  /// 退出全屏
  void onExitFullscreen(InAppWebViewController controller) {
    isFullScreen.value = false;
    _fullscreenOverlay?.remove();
    _fullscreenOverlay = null;
    update();
  }

  @override
  void onClose() {
    super.onClose();

    // 取消进度监听
    DownloadService.to.unbindBackgroundIsolate();
  }
}
