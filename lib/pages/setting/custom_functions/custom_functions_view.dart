import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import 'package:deup/common/index.dart';
import 'package:deup/pages/setting/custom_functions/custom_functions_controller.dart';

class CustomFunctionsPage extends GetView<CustomFunctionsController> {
  const CustomFunctionsPage({Key? key}) : super(key: key);

  CupertinoNavigationBar _buildNavigationBar() {
    return CupertinoNavigationBar(
      backgroundColor: CommonUtils.backgroundColor,
      border: Border.all(width: 0, color: Colors.transparent),
      leading: CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        child: Icon(FontAwesomeIcons.xmark, size: CommonUtils.navIconSize),
        onPressed: () => Get.back(),
      ),
      middle: Text('自定义函数'),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Icon(CupertinoIcons.add, size: CommonUtils.navIconSize),
        onPressed: () => _showEditorDialog(),
      ),
    );
  }

  Future<void> _showEditorDialog({String? id, String? name, String? code}) async {
    final nameController = TextEditingController(text: name ?? '');
    final codeController = TextEditingController(text: code ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<bool>(
      context: Get.overlayContext!,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        child: Text('取消'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      Text(
                        id == null ? '新建函数' : '编辑函数',
                        style: Get.textTheme.bodyLarge,
                      ),
                      CupertinoButton(
                        child: Text('保存'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: CupertinoTextField(
                      controller: nameController,
                      placeholder: '函数名称',
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text('函数代码', style: Get.textTheme.bodySmall),
                  SizedBox(height: 8.h),
                  Container(
                    height: 300.h,
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: CupertinoTextField(
                      controller: codeController,
                      placeholder: 'function myFunc(args) {\n  // your code here\n  return args;\n}',
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      padding: EdgeInsets.all(12.w),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    '函数将以 function 形式注入到脚本上下文中，脚本中可直接调用。',
                    style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == true) {
      final n = nameController.text.trim();
      final c = codeController.text.trim();
      if (n.isEmpty) {
        SmartDialog.showToast('请输入函数名称');
        return;
      }
      if (c.isEmpty) {
        SmartDialog.showToast('请输入函数代码');
        return;
      }

      if (id != null) {
        await controller.updateFunction(id, n, c);
      } else {
        await controller.addFunction(n, c);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: _buildNavigationBar(),
      backgroundColor: CommonUtils.backgroundColor,
      child: Obx(() {
        if (controller.functions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.function, size: 60.r, color: Colors.grey),
                SizedBox(height: 16.h),
                Text('暂无自定义函数', style: Get.textTheme.bodyLarge?.copyWith(color: Colors.grey)),
                SizedBox(height: 8.h),
                Text('点击右上角 + 添加', style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(top: 12.h),
          itemCount: controller.functions.length,
          itemBuilder: (context, index) {
            final func = controller.functions[index];
            return CupertinoListTile(
              title: Text(func.name, style: Get.textTheme.bodyLarge),
              subtitle: Text(
                func.code.length > 60 ? '${func.code.substring(0, 60)}...' : func.code,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontFamily: 'monospace',
                  fontSize: 11.sp,
                ),
              ),
              leading: Icon(CupertinoIcons.function, color: Get.theme.primaryColor),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(CupertinoIcons.delete, size: 20.r, color: Colors.red),
                onPressed: () async {
                  final ok = await showOkCancelAlertDialog(
                    context: Get.overlayContext!,
                    title: '提示',
                    message: '确定要删除「${func.name}」吗？',
                    okLabel: '删除',
                    cancelLabel: '取消',
                    isDestructiveAction: true,
                  );
                  if (ok == OkCancelResult.ok) {
                    await controller.deleteFunction(func.id);
                  }
                },
              ),
              onTap: () => _showEditorDialog(
                id: func.id,
                name: func.name,
                code: func.code,
              ),
            );
          },
        );
      }),
    );
  }
}
