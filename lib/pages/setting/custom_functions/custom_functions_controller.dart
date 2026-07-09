import 'package:get/get.dart';

import 'package:deup/common/index.dart';
import 'package:deup/models/custom_function_model.dart';

class CustomFunctionsController extends GetxController {
  final functions = <CustomFunctionModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    CustomFunctionService.to.markSeen();
    loadFunctions();
  }

  void loadFunctions() {
    functions.value = CustomFunctionService.to.getAll();
  }

  Future<void> addFunction(String name, String code) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final func = CustomFunctionModel(
      id: CommonUtils.generateUuid(),
      name: name,
      code: code,
      createdAt: now,
      updatedAt: now,
    );
    await CustomFunctionService.to.add(func);
    loadFunctions();
  }

  Future<void> updateFunction(String id, String name, String code) async {
    final func = functions.firstWhere((f) => f.id == id);
    final updated = CustomFunctionModel(
      id: func.id,
      name: name,
      code: code,
      createdAt: func.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await CustomFunctionService.to.update(updated);
    loadFunctions();
  }

  Future<void> deleteFunction(String id) async {
    await CustomFunctionService.to.remove(id);
    loadFunctions();
  }
}
