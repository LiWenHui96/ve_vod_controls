import 've_vod_controls_platform_interface.dart';

class VeVodControls {
  Future<String?> getPlatformVersion() {
    return VeVodControlsPlatform.instance.getPlatformVersion();
  }
}
