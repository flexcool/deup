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
    await Get.to(
      () => _FunctionEditorPage(
        id: id,
        initialName: name,
        initialCode: code,
      ),
      fullscreenDialog: true,
    );
  }
}

class _FunctionEditorPage extends StatefulWidget {
  final String? id;
  final String? initialName;
  final String? initialCode;

  const _FunctionEditorPage({
    this.id,
    this.initialName,
    this.initialCode,
  });

  @override
  State<_FunctionEditorPage> createState() => _FunctionEditorPageState();
}

class _FunctionEditorPageState extends State<_FunctionEditorPage> {
  late TextEditingController _nameController;
  late TextEditingController _codeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _codeController = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty) {
      SmartDialog.showToast('请输入函数名称');
      return;
    }
    if (code.isEmpty) {
      SmartDialog.showToast('请输入函数代码');
      return;
    }

    final controller = Get.find<CustomFunctionsController>();
    if (widget.id != null) {
      controller.updateFunction(widget.id!, name, code);
    } else {
      controller.addFunction(name, code);
    }
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CommonUtils.backgroundColor,
        border: Border.all(width: 0, color: Colors.transparent),
        leading: CupertinoButton(
          child: Text('取消'),
          onPressed: () => Get.back(),
        ),
        middle: Text(widget.id == null ? '新建函数' : '编辑函数'),
        trailing: CupertinoButton(
          child: Text('保存'),
          onPressed: _save,
        ),
      ),
      backgroundColor: CommonUtils.backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: CupertinoTextField(
                  controller: _nameController,
                  placeholder: '函数名称',
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 16.h),
              Text('函数代码', style: Get.textTheme.bodySmall),
              SizedBox(height: 8.h),
              Container(
                height: 400.h,
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey4),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: CupertinoTextField(
                  controller: _codeController,
                  placeholder: 'function myFunc(args) {\n  return args;\n}',
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  padding: EdgeInsets.all(12.w),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                '函数挂载在 \$custom 命名空间下，脚本中通过 \$custom.函数名() 调用。',
                style: Get.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
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
