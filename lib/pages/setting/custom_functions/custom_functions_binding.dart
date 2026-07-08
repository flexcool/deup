import 'package:get/get.dart';

import 'package:deup/pages/setting/custom_functions/custom_functions_controller.dart';

class CustomFunctionsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CustomFunctionsController>(() => CustomFunctionsController());
  }
}
