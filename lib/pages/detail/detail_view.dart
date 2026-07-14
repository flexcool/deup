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
      height: 340.h,
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
                const Spacer(),
                GestureDetector(
                  onTap: () => ConsoleCapture.clear(),
                  child: Icon(Icons.delete_outline,
                      color: Colors.white54, size: 40.sp),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(8.w),
              itemCount: ConsoleCapture.entries.isEmpty
                  ? 1
                  : ConsoleCapture.entries.length,
              itemBuilder: (context, index) {
                if (ConsoleCapture.entries.isEmpty) {
                  return SizedBox(
                    height: 280.h,
                    child: Center(
                      child: Text('无输出',
                          style: TextStyle(
                              color: Colors.white24, fontSize: 28.sp)),
                    ),
                  );
                }
                final entry = ConsoleCapture.entries[index];
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
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Text(
                    entry.message,
                    style: TextStyle(
                      color: color,
                      fontSize: 24.sp,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
