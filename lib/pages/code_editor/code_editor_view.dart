import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';

import 'package:deup/common/index.dart';
import 'package:deup/routes/app_pages.dart';
import 'package:deup/pages/code_editor/code_editor_controller.dart';

class CodeEditorPage extends GetView<CodeEditorController> {
  const CodeEditorPage({Key? key}) : super(key: key);

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: Get.theme.scaffoldBackgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CupertinoButton(
        onPressed: () => Get.back(),
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        child: Icon(FontAwesomeIcons.xmark, size: CommonUtils.navIconSize),
      ),
      trailing: Container(
        width: 620.w,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CupertinoButton(
              onPressed: () => Get.toNamed(Routes.WEBVIEW, arguments: {
                'url': 'https://docs.deup.io/guide/quick-start',
                'title': 'Deup!',
              }),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.doc_text,
                  size: CommonUtils.isPad ? 20 : 60.sp),
            ),
            CupertinoButton(
              onPressed: () => controller.updateLink(),
              padding: EdgeInsets.zero,
              minSize: 33,
              alignment: Alignment.centerRight,
              child: Icon(CupertinoIcons.link_circle,
                  size: CommonUtils.isPad ? 22 : 65.sp),
            ),
            CupertinoButton(
              onPressed: () => controller.runScript(),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Obx(() => Icon(
                    controller.isRunning.value
                        ? CupertinoIcons.stop_circle
                        : FontAwesomeIcons.play,
                    size: CommonUtils.isPad ? 22 : 65.sp,
                    color: controller.isRunning.value
                        ? Get.theme.primaryColor
                        : null,
                  )),
            ),
            CupertinoButton(
              onPressed: () => controller.save(),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerRight,
              child: Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeField() {
    if (controller.isLoading.isTrue) {
      return Center(child: CupertinoActivityIndicator());
    }

    return CodeTheme(
      data: CodeThemeData(
        styles: Get.isDarkMode ? atomOneDarkTheme : atomOneLightTheme,
      ),
      child: Container(
        height: Get.height,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: CodeField(
            controller: controller.codeController,
            focusNode: controller.focusNode,
            background: Get.theme.scaffoldBackgroundColor,
            minLines: 30,
            wrap: true,
            lineNumbers: false,
            smartQuotesType: SmartQuotesType.disabled,
          ),
        ),
      ),
    );
  }

  Widget _buildConsolePanel() {
    return Container(
      height: 340.h,
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Text('控制台',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w600)),
                Spacer(),
                GestureDetector(
                  onTap: () => controller.clearConsole(),
                  child: Icon(CupertinoIcons.trash,
                      color: Colors.grey[400], size: 38.sp),
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: () => controller.toggleConsole(),
                  child: Icon(CupertinoIcons.chevron_down,
                      color: Colors.grey[400], size: 38.sp),
                ),
              ],
            ),
          ),
          // Log entries
          Expanded(
            child: Obx(() {
              if (controller.consoleOutput.isEmpty) {
                return Center(
                  child: Text('运行脚本后控制台将显示输出',
                      style: TextStyle(color: Colors.grey[500], fontSize: 26.sp)),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.all(10.w),
                itemCount: controller.consoleOutput.length,
                itemBuilder: (_, index) {
                  final entry = controller.consoleOutput[index];
                  return _buildLogEntry(entry.level, entry.message);
                },
              );
            }),
          ),
          // Expression input
          Container(
            padding: EdgeInsets.fromLTRB(12.w, 6.h, 12.w, 12.h),
            decoration: BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.r),
                bottomRight: Radius.circular(12.r),
              ),
            ),
            child: Row(
              children: [
                Text('> ',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 28.sp,
                        fontFamily: 'monospace')),
                Expanded(
                  child: CupertinoTextField(
                    controller: controller.expressionController,
                    focusNode: controller.expressionFocusNode,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontFamily: 'monospace'),
                    placeholder: '输入表达式...',
                    placeholderStyle: TextStyle(
                        color: Colors.grey[600], fontSize: 28.sp),
                    decoration: BoxDecoration(),
                    onSubmitted: (_) => controller.onExpressionSubmitted(),
                  ),
                ),
                SizedBox(width: 10.w),
                GestureDetector(
                  onTap: () => controller.onExpressionSubmitted(),
                  child: Icon(CupertinoIcons.return_ios,
                      color: Colors.greenAccent, size: 40.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogEntry(String level, String message) {
    Color color;
    String prefix;
    switch (level) {
      case 'result':
        color = Colors.greenAccent;
        prefix = '›';
        break;
      case 'warn':
        color = Colors.orangeAccent;
        prefix = '⚠';
        break;
      case 'error':
        color = Colors.redAccent;
        prefix = '✗';
        break;
      default:
        color = Colors.white70;
        prefix = 'ℹ';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$prefix ',
              style: TextStyle(
                  color: color, fontSize: 26.sp, fontFamily: 'monospace')),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color, fontSize: 26.sp, fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardDismissOnTap(
      child: CupertinoPageScaffold(
        navigationBar: _buildNavigationBar(),
        child: SafeArea(
          child: Obx(() => Stack(
                children: [
                  _buildCodeField(),
                  if (controller.showConsole.value) _buildConsolePanel(),
                  if (!controller.showConsole.value)
                    Positioned(
                      bottom: 20.h,
                      right: 30.w,
                      child: GestureDetector(
                        onTap: () => controller.toggleConsole(),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 12.h),
                          decoration: BoxDecoration(
                            color: Get.theme.primaryColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(CupertinoIcons.terminal,
                                  color: Colors.white, size: 36.sp),
                              SizedBox(width: 8.w),
                              Text('控制台',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 28.sp)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              )),
        ),
      ),
    );
  }
}
