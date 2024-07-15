import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 've_vod_controls_platform_interface.dart';

/// An implementation of [VeVodControlsPlatform] that uses method channels.
class MethodChannelVeVodControls extends VeVodControlsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('ve_vod_controls');

  @override
  Future<String?> getPlatformVersion() async {
    final String? version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
