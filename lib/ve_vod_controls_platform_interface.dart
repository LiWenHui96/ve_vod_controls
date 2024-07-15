import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 've_vod_controls_method_channel.dart';

abstract class VeVodControlsPlatform extends PlatformInterface {
  /// Constructs a VeVodControlsPlatform.
  VeVodControlsPlatform() : super(token: _token);

  static final Object _token = Object();

  static VeVodControlsPlatform _instance = MethodChannelVeVodControls();

  /// The default instance of [VeVodControlsPlatform] to use.
  ///
  /// Defaults to [MethodChannelVeVodControls].
  static VeVodControlsPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VeVodControlsPlatform] when
  /// they register themselves.
  static set instance(VeVodControlsPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
