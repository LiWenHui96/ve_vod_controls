part of 've_vod_controls.dart';

/// An implementation of [VeVodControlsPlatform] that uses method channels.
class MethodChannelVeVodControls extends VeVodControlsPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel('ve_vod_controls');

  @override
  Future<void> init({
    required String appId,
    required String licenseFilePath,
    required String appName,
    required String appVersion,
    required String? appChannel,
    String? cacheDirPath,
    int? maxCacheSize,
    bool isDebug = false,
  }) async {
    assert(isAppVersion(appVersion), '请使用合法版本号，例如：1.0.0');

    if (isDebug) {
      /// 开启日志
      await FlutterTTSDKManager.openAllLog();

      /// 插件版本
      final String? pluginVersion =
          await FlutterTTSDKManager.getPluginVersion();
      kLog('VeVod PluginVersion: $pluginVersion');

      /// 注册插件日志
      TTFLogger.onLog = (LogLevel level, String msg) {
        kLog('onLog $level: $msg');
      };
    }

    /// 设置缓存信息
    final TTSDKVodConfiguration vodConfig = TTSDKVodConfiguration()
      ..cachePath = cacheDirPath ?? kCacheDir
      ..cacheMaxSize = maxCacheSize ?? kMaxCacheSize;

    /// 设置初始化信息
    final TTSDKConfiguration config =
        TTSDKConfiguration.defaultConfigurationWithAppIDAndLicPath(
      appID: appId,
      licenseFilePath: licenseFilePath,
      channel: appChannel ?? kAppChannel,
    )
          ..appName = appName
          ..appVersion = appVersion
          ..vodConfiguration = vodConfig;

    /// 初始化
    await FlutterTTSDKManager.startWithConfiguration(config);
  }

  @override
  Future<void> setUserUniqueID(String userId) {
    return FlutterTTSDKManager.setCurrentUserUniqueID(userId);
  }

  @override
  Future<String?> getUserUniqueID() {
    return FlutterTTSDKManager.getCurrentUserUniqueID();
  }

  @override
  Future<void> clearUserUniqueID() {
    return FlutterTTSDKManager.clearUserUniqueID();
  }

  @override
  Future<String?> getDeviceID() {
    return FlutterTTSDKManager.getDeviceID();
  }

  @override
  Future<String?> getEngineUniqueID() {
    return FlutterTTSDKManager.getEngineUniqueId();
  }

  @override
  Future<bool?> isDeviceSupportDrm() {
    return FlutterTTSDKManager.isDeviceSupportDrm();
  }

  @override
  Future<bool?> isSupportH265HardwareDecode() {
    return FlutterTTSDKManager.isSupportH265HardwareDecode();
  }

  @override
  Future<String?> getPlatformVersion() async {
    final String? version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
