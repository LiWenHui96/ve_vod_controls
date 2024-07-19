import 'package:flutter_test/flutter_test.dart';
import 'package:ve_vod_controls/ve_vod_controls_method_channel.dart';
import 'package:ve_vod_controls/ve_vod_controls_platform_interface.dart';

void main() {
  final VeVodControlsPlatform initialPlatform = VeVodControlsPlatform.instance;

  test('$MethodChannelVeVodControls is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVeVodControls>());
  });
}
