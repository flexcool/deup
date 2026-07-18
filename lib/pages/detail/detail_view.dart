import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:deup/pages/plugin/plugin_controller.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:deup/common/index.dart';
import 'package:deup/constants/index.dart';
import 'package:deup/routes/app_pages.dart';
import 'package:deup/models/index.dart';
import 'package:deup/pages/detail/layouts/index.dart';
import 'package:deup/pages/detail/detail_controller.dart';

class DetailPage extends StatelessWidget {
  final String? tag;
  DetailController get controller => Get.find<DetailController>(tag: tag);

  /// 构造函数
  DetailPage({Key? key, this.tag}) : super(key: key) {
    Get.put<DetailController>(DetailController(), tag: tag);
  }

  // NavigationBar
  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CommonUtils.backButton,
      middle: Text(
        controller.history
            ? '历史记录'
            : controller.object?.name == null ||
                    controller.object!.name!.isEmpty
                ? (controller.server?.name ?? '测试')
                : controller.object!.name!,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Get.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: Container(
        width: 300.w,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (controller.fromEditor)
              CupertinoButton(
                onPressed: () => controller.toggleConsole(),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerRight,
                child: Obx(() => Icon(
                  controller.showConsole.value
                      ? Icons.keyboard_arrow_down
                      : Icons.terminal,
                  size: CommonUtils.isPad ? 22 : 65.sp,
                )),
              ),
            CupertinoButton(
              onPressed: () => controller.switchLayoutType(),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.rectangle_grid_1x2,
                  size: CommonUtils.isPad ? 22 : 65.sp),
            ),
            CupertinoButton(
              onPressed: () => Get.until(
                (route) => Get.currentRoute.startsWith(
                  Get.isRegistered<PluginController>()
                      ? Routes.PLUGIN
                      : Routes.HOMEPAGE,
                ),
              ),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.xmark_circle_fill,
                  size: CommonUtils.navIconSize),
            )
          ],
        ),
      ),
    );
  }

  /// Layout
  Widget _buildLayout() {
    // 网格视图 - 全类型加载
    if (controller.layoutType.value == LayoutType.GRID)
      return GridLayout(
        id: controller.id,
        object: controller.object,
        history: controller.history,
        detailController: controller,
        keyword: controller.keyword.value,
      );

    // 图片视图 - 仅加载图片类型, 瀑布流
    if (controller.layoutType.value == LayoutType.IMAGE)
      return ImageLayout(
        id: controller.id,
        object: controller.object,
        history: controller.history,
        detailController: controller,
        keyword: controller.keyword.value,
      );

    // 封面视图 - 仅加载封面字段不为空的类型
    if (controller.layoutType.value == LayoutType.COVER)
      return CoverLayout(
        id: controller.id,
        object: controller.object,
        history: controller.history,
        detailController: controller,
        keyword: controller.keyword.value,
      );

    // 海报视图 - 仅加载海报字段不为空的类型
    if (controller.layoutType.value == LayoutType.POSTER)
      return PosterLayout(
        id: controller.id,
        object: controller.object,
        history: controller.history,
        detailController: controller,
        keyword: controller.keyword.value,
      );

    // 列表视图 - 默认
    return ListLayout(
      id: controller.id,
      object: controller.object,
      history: controller.history,
      detailController: controller,
      keyword: controller.keyword.value,
    );
  }

  Widget _buildConsoleOverlay() {
    return Container(
      height: 680.h,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.white12)),
            ),
            child: Row(
              children: [
                Text('控制台',
                    style: TextStyle(color: Colors.white70, fontSize: 28.sp)),
                SizedBox(width: 16.w),
                Expanded(
                  child: CupertinoTextField(
                    placeholder: '过滤...',
                    placeholderStyle: TextStyle(
                        color: Colors.white24, fontSize: 24.sp),
                    style: TextStyle(
                        color: Colors.white, fontSize: 24.sp),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    onChanged: controller.onFilterChanged,
                  ),
                ),
                Obx(() {
                  final filter = controller.consoleFilter.value;
                  if (filter.isEmpty) return const SizedBox();
                  final total = ConsoleCapture.entries
                      .where((e) => e.message
                          .toLowerCase()
                          .contains(filter.toLowerCase()))
                      .length;
                  if (total == 0) return const SizedBox();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: controller.prevMatch,
                        child: Icon(Icons.keyboard_arrow_up,
                            color: Colors.white54, size: 32.sp),
                      ),
                      GestureDetector(
                        onTap: controller.nextMatch,
                        child: Icon(Icons.keyboard_arrow_down,
                            color: Colors.white54, size: 32.sp),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${controller.consoleMatchIndex.value + 1}/$total',
                        style: TextStyle(color: Colors.white38, fontSize: 22.sp),
                      ),
                    ],
                  );
                }),
                SizedBox(width: 12.w),
                GestureDetector(
                  onTap: () => ConsoleCapture.clear(),
                  child: Icon(Icons.delete_outline,
                      color: Colors.white54, size: 40.sp),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final filter = controller.consoleFilter.value;
              final filtered = filter.isEmpty
                  ? ConsoleCapture.entries
                  : ConsoleCapture.entries
                      .where((e) => e.message
                          .toLowerCase()
                          .contains(filter.toLowerCase()))
                      .toList();
              if (filtered.isEmpty) {
                return Center(
                  child: SelectableText(
                      ConsoleCapture.entries.isEmpty ? '无输出' : '无匹配结果',
                      style: TextStyle(
                          color: Colors.white24, fontSize: 28.sp)),
                );
              }
              return ListView.builder(
                controller: controller.consoleScrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(8.w),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final entry = filtered[index];
                  Color color;
                  switch (entry.level) {
                    case 'error':
                      color = const Color(0xFFFF5555);
                      break;
                    case 'warn':
                      color = const Color(0xFFFFAA00);
                      break;
                    case 'result':
                      color = const Color(0xFF55FF55);
                      break;
                    default:
                      color = Colors.white70;
                  }
                  final isMatch = index == controller.consoleMatchIndex.value;
                  return Container(
                    color: isMatch
                        ? Colors.white.withOpacity(0.08)
                        : null,
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: SelectableText.rich(
                      _buildHighlightedTextSpan(
                          entry.message, filter, color),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
              },
            );
          }),
        ),
      ],
    ),
  );
  }

  TextSpan _buildHighlightedTextSpan(
      String text, String filter, Color color) {
    if (filter.isEmpty) {
      return TextSpan(text: text, style: TextStyle(color: color));
    }
    final lower = text.toLowerCase();
    final filterLower = filter.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int idx;
    while ((idx = lower.indexOf(filterLower, start)) != -1) {
      if (idx > start) {
        spans.add(TextSpan(
            text: text.substring(start, idx),
            style: TextStyle(color: color)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + filter.length),
        style: TextStyle(
            color: Colors.black,
            backgroundColor: const Color(0xFFFFEB3B)),
      ));
      start = idx + filter.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(color: color)));
    }
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: Scaffold(
        appBar: _buildNavigationBar(),
        body: Column(
          children: [
            Expanded(child: Obx(() => _buildLayout())),
            if (controller.fromEditor)
              Obx(() {
                if (!controller.showConsole.value) return SizedBox.shrink();
                return _buildConsoleOverlay();
              }),
          ],
        ),
        floatingActionButton: !controller.history && tag == null
            ? FloatingActionButton(
                onPressed: () => Get.to(
                  () => DetailPage(tag: '/history-identifier'),
                  routeName: '${Routes.DETAIL}/history-identifier',
                  arguments: {
                    'id': controller.id,
                    'history': true,
                    'object': controller.object
                  },
                ),
                mini: true,
                backgroundColor: Get.theme.primaryColor,
                child: Icon(Icons.history_rounded),
              )
            : null,
      ),
    );
  }
}
