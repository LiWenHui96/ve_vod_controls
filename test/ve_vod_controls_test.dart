import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ve_vod_controls/ve_vod_controls.dart';
import 'package:ve_vod_controls/ve_vod_controls_method_channel.dart';
import 'package:ve_vod_controls/ve_vod_controls_platform_interface.dart';

class MockVeVodControlsPlatform
    with MockPlatformInterfaceMixin
    implements VeVodControlsPlatform {
  @override
  Future<String?> getPlatformVersion() => Future<String?>.value('42');
}

void main() {
  final VeVodControlsPlatform initialPlatform = VeVodControlsPlatform.instance;

  test('$MethodChannelVeVodControls is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVeVodControls>());
  });

  test('getPlatformVersion', () async {
    final VeVodControls veVodControlsPlugin = VeVodControls();
    final MockVeVodControlsPlatform fakePlatform = MockVeVodControlsPlatform();
    VeVodControlsPlatform.instance = fakePlatform;

    expect(await veVodControlsPlugin.getPlatformVersion(), '42');
  });
}
