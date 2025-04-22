import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ve_vod_controls/src/interface/ve_vod_controls.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelVeVodControls platform = MethodChannelVeVodControls();
  const MethodChannel channel = MethodChannel('ve_vod_controls');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
