import 'package:get/get.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:deup/common/index.dart';

class DeviceInfoService extends GetxService {
  static DeviceInfoService get to => Get.find();

  IosDeviceInfo? _iosInfo;
  IosDeviceInfo? get iosInfo => _iosInfo;

  AndroidDeviceInfo? _androidInfo;
  AndroidDeviceInfo? get androidInfo => _androidInfo;

  Future<DeviceInfoService> init() async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      if (GetPlatform.isIOS) _iosInfo = await deviceInfo.iosInfo;
      if (GetPlatform.isAndroid) _androidInfo = await deviceInfo.androidInfo;
    } catch (e) {
      CommonUtils.logger.e('DeviceInfo init failed: $e');
    }
    return this;
  }

  bool get isIpad =>
      GetPlatform.isIOS &&
      _iosInfo?.utsname.machine?.toLowerCase().contains('ipad') == true;
}
