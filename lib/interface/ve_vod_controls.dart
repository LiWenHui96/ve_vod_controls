/// @Describe: Plugin entry.
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/15

library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:ve_vod/ve_vod.dart';

part 've_vod_controls_method_channel.dart';

part 've_vod_controls_platform_interface.dart';

class VeVodControls {
  static final VeVodControls _instance = VeVodControls();

  static VeVodControls get instance => _instance;

  /// {@macro ve.vod.controls.init}
  void init({
    required String appId,
    required String licenseFilePath,
    required String appName,
    required String appVersion,
    required String? appChannel,
    String? cacheDirPath,
    int? maxCacheSize,
    bool isDebug = false,
  }) {
    VeVodControlsPlatform.instance.init(
      appId: appId,
      licenseFilePath: licenseFilePath,
      appName: appName,
      appVersion: appVersion,
      appChannel: appChannel,
      cacheDirPath: cacheDirPath,
      maxCacheSize: maxCacheSize,
      isDebug: isDebug,
    );
  }

  /// {@macro ve.vod.controls.setUserUniqueID}
  Future<void> setUserUniqueID(String userId) {
    return VeVodControlsPlatform.instance.setUserUniqueID(userId);
  }

  /// {@macro ve.vod.controls.getUserUniqueID}
  Future<String?> getUserUniqueID() {
    return VeVodControlsPlatform.instance.getUserUniqueID();
  }

  /// {@macro ve.vod.controls.clearUserUniqueID}
  Future<void> clearUserUniqueID() {
    return VeVodControlsPlatform.instance.clearUserUniqueID();
  }

  /// {@macro ve.vod.controls.getDeviceID}
  Future<String?> getDeviceID() {
    return VeVodControlsPlatform.instance.getDeviceID();
  }

  /// {@macro ve.vod.controls.getEngineUniqueID}
  Future<String?> getEngineUniqueID() {
    return VeVodControlsPlatform.instance.getEngineUniqueID();
  }

  /// {@macro ve.vod.controls.isDeviceSupportDrm}
  Future<bool?> isDeviceSupportDrm() {
    return VeVodControlsPlatform.instance.isDeviceSupportDrm();
  }

  /// {@macro ve.vod.controls.isSupportH265HardwareDecode}
  Future<bool?> isSupportH265HardwareDecode() {
    return VeVodControlsPlatform.instance.isSupportH265HardwareDecode();
  }

  Future<String?> getPlatformVersion() {
    return VeVodControlsPlatform.instance.getPlatformVersion();
  }
}
