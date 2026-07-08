import 'package:get/get.dart';
import 'package:keframe/keframe.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

import 'package:deup/common/index.dart';
import 'package:deup/helper/index.dart';
import 'package:deup/routes/app_pages.dart';
import 'package:deup/database/entity/index.dart';
import 'package:deup/pages/homepage/homepage_controller.dart';
import 'package:deup/pages/homepage/components/plugin_item_component.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:deup/components/cache_network_svg_image.dart';
import 'package:path/path.dart' as p;

class Homepage extends GetView<HomepageController> {
  const Homepage({Key? key}) : super(key: key);

  Widget _buildSliverNavigationBar() {
    return CupertinoSliverNavigationBar(
      backgroundColor:
          Get.isDarkMode ? Color.fromARGB(255, 18, 18, 18) : Colors.white,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        child: Icon(CupertinoIcons.settings, size: CommonUtils.navIconSize),
        onPressed: () => Get.toNamed(Routes.SETTING),
      ),
      largeTitle: Text(
        'Deup',
        style: TextStyle(color: Get.theme.textTheme.bodyLarge?.color),
      ),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerRight,
        child: Icon(CupertinoIcons.plus_circled, size: CommonUtils.navIconSize),
        onPressed: () => Get.toNamed(Routes.CODE_EDITOR),
      ),
    );
  }

  Widget _buildEmptyPlugin() {
    return Column(
      children: [
        SizedBox(height: 500.h),
        CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: CommonUtils.isPad ? 20 : 50.sp,
              ),
              SizedBox(width: 5.w),
              Text('了解更多'),
            ],
          ),
          onPressed: () => Get.toNamed(Routes.WEBVIEW, arguments: {
            'url': 'https://docs.deup.io/guide/quick-start',
            'title': 'Deup!',
          }),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 100.r),
          child: ButtonHelper.createElevatedButton(
            '新建',
            onPressed: () => Get.toNamed(Routes.CODE_EDITOR),
          ),
        ),
      ],
    );
  }

  Widget _buildShortcutIcon(ShortcutEntity shortcut) {
    final iconExt = shortcut.icon != null
        ? p.extension(shortcut.icon!).replaceAll('.', '').toLowerCase()
        : '';
    final iconColor = shortcut.color != null
        ? CommonUtils.getHexColor(shortcut.color!)
        : Get.theme.primaryColor;

    return GestureDetector(
      onTap: () => controller.onShortcutTap(shortcut),
      onLongPress: () async {
        final ok = await showOkCancelAlertDialog(
          context: Get.overlayContext!,
          title: '提示',
          message: '确定要移除「${shortcut.label}」吗？',
          okLabel: '移除',
          cancelLabel: '取消',
          isDestructiveAction: true,
        );
        if (ok == OkCancelResult.ok) {
          await controller.removeShortcut(shortcut.id);
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: CommonUtils.isPad ? 70 : 120.r,
              height: CommonUtils.isPad ? 70 : 120.r,
              decoration: BoxDecoration(
                color: shortcut.color != null
                    ? CommonUtils.getHexColor(shortcut.color!)
                    : Get.theme.primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(CommonUtils.isPad ? 16 : 28.r),
              ),
              child: shortcut.icon != null && shortcut.icon!.isNotEmpty
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(CommonUtils.isPad ? 16 : 28.r),
                      child: iconExt == 'svg'
                          ? CachedNetworkSvgImage(
                              imageUrl: shortcut.icon!,
                              width: CommonUtils.isPad ? 48 : 68.r,
                              height: CommonUtils.isPad ? 48 : 68.r,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: shortcut.icon!,
                              width: CommonUtils.isPad ? 48 : 68.r,
                              height: CommonUtils.isPad ? 48 : 68.r,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  SizedBox.shrink(),
                            ),
                    )
                  : Icon(
                      CupertinoIcons.rocket,
                      size: CommonUtils.isPad ? 28 : 48.r,
                      color: iconColor,
                    ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: CommonUtils.isPad ? 80 : 140.w,
              child: Text(
                shortcut.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: CommonUtils.isPad ? 11 : 22.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutSection() {
    return Obx(() {
      final shortcuts = controller.shortcutList;
      if (shortcuts.isEmpty) return SizedBox.shrink();
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(
            top: 20.h,
            bottom: 10.h,
            left: CommonUtils.isPad ? 25 : 50.w,
          ),
          child: SizedBox(
            height: CommonUtils.isPad ? 120 : 210.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: shortcuts.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (context, index) =>
                  _buildShortcutIcon(shortcuts[index]),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSliverList() {
    if (controller.isFirstLoading.isTrue) {
      return SliverToBoxAdapter(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (controller.pluginList.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyPlugin());
    }

    return SizeCacheWidget(
      child: SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int index) => FrameSeparateWidget(
            index: index,
            child: GestureDetector(
              onTap: () => controller.onPluginTap(controller.pluginList[index]),
              child: PluginItemComponent(
                index: index,
                plugin: controller.pluginList[index],
              ),
            ),
          ),
          childCount: controller.pluginList.length,
        ),
      ),
    );
  }

  Widget _buildCustomScrollView() {
    return CustomScrollView(
      shrinkWrap: false,
      controller: controller.scrollController,
      physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: <Widget>[
        _buildSliverNavigationBar(),
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await controller.loadShortcuts();
            await controller.getPluginList();
            await Future.delayed(Duration(seconds: 1));
          },
        ),
        _buildShortcutSection(),
        SliverPadding(
          padding:
              EdgeInsets.symmetric(horizontal: CommonUtils.isPad ? 25 : 50.w)
                  .copyWith(bottom: 30.h),
          sliver: SliverToBoxAdapter(
            child: CupertinoSearchTextField(
              placeholder: '搜索',
              placeholderStyle: TextStyle(
                fontSize: 15,
                color: Get.isDarkMode ? Colors.grey[500] : Colors.grey[600],
              ),
              style: TextStyle(fontSize: 18),
              onChanged: (String value) {
                controller.keyword.value = value;
                controller.getPluginList();
              },
            ),
          ),
        ),
        SliverPadding(
          padding:
              EdgeInsets.symmetric(horizontal: CommonUtils.isPad ? 25 : 50.w)
                  .copyWith(bottom: 30.h),
          sliver: Obx(() => _buildSliverList()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: CupertinoPageScaffold(
        child: _buildCustomScrollView(),
      ),
    );
  }
}
