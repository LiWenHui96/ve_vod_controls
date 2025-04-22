import 'package:flutter_test/flutter_test.dart';
import 'package:ve_vod_controls/src/interface/ve_vod_controls.dart';

void main() {
  final VeVodControlsPlatform initialPlatform = VeVodControlsPlatform.instance;

  test('$MethodChannelVeVodControls is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVeVodControls>());
  });
}
