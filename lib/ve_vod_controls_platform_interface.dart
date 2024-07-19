import 'package:flutter/foundation.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 've_vod_controls.dart';
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

  /// {@template ve.vod.controls.init}
  /// 初始化VodSDK
  /// Flutter: https://www.volcengine.com/docs/4/1264702
  /// Android: https://www.volcengine.com/docs/4/112130
  /// iOS: https://www.volcengine.com/docs/4/112131
  ///
  /// [appId] AppID，从控制台 -> 应用管理获取
  ///
  /// [licenseFilePath] License 文件地址
  /// 放置在 flutter 目录下 `assets/license/xxx.lic` 路径
  ///
  /// [appName] App 英文名，从控制台 -> 应用管理获取
  ///
  /// [appVersion] App 版本号
  ///
  /// [appChannel] 渠道号，业务自定义，默认为[kAppChannel]
  ///
  /// [cacheDirPath] 视频缓存路径，默认为[kCacheDir]
  ///
  /// [maxCacheSize] 视频缓存文件夹大小，默认值为[kMaxCacheSize]
  ///
  /// [isDebug] 是否开启日志调试，建议线上版本关闭日志，减少性能开销
  /// 默认为false，建议使用[kDebugMode]
  /// {@endtemplate}
  Future<void> init({
    required String appId,
    required String licenseFilePath,
    required String appName,
    required String appVersion,
    required String? appChannel,
    String? cacheDirPath,
    int? maxCacheSize,
    bool isDebug = false,
  }) {
    throw UnimplementedError('init() has not been implemented.');
  }

  /// {@template ve.vod.controls.setUserUniqueID}
  /// 设置自定义UniqueID
  /// 用于实现单点追查功能，即进行用户级和播放会话级的全链路问题定位和追踪
  ///
  /// 如何使用自定义ID
  /// Flutter: https://www.volcengine.com/docs/4/1264702#%E8%AE%BE%E7%BD%AE%E8%87%AA%E5%AE%9A%E4%B9%89-id
  /// Android: https://www.volcengine.com/docs/4/161480
  /// iOS: https://www.volcengine.com/docs/4/171486
  /// {@endtemplate}
  Future<void> setUserUniqueID(String userId) {
    throw UnimplementedError('setUserUniqueID() has not been implemented.');
  }

  /// {@template ve.vod.controls.getUserUniqueID}
  /// 获取当前的自定义UniqueID
  /// {@endtemplate}
  Future<String?> getUserUniqueID() {
    throw UnimplementedError('getUserUniqueID() has not been implemented.');
  }

  /// {@template ve.vod.controls.clearUserUniqueID}
  /// 清除自定义UniqueID
  /// {@endtemplate}
  Future<void> clearUserUniqueID() {
    throw UnimplementedError('clearUserUniqueID() has not been implemented.');
  }

  /// {@template ve.vod.controls.getDeviceID}
  /// 获取设备ID
  /// {@endtemplate}
  Future<String?> getDeviceID() {
    throw UnimplementedError('getDeviceID() has not been implemented.');
  }

  /// {@template ve.vod.controls.getEngineUniqueID}
  /// 获取当前设备 DRM 唯一标识
  /// {@endtemplate}
  Future<String?> getEngineUniqueID() {
    throw UnimplementedError('getEngineUniqueID() has not been implemented.');
  }
}
