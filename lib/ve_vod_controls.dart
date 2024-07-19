library ve_vod_controls;

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:ve_vod/ve_vod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 've_vod_controls_platform_interface.dart';

export 'package:ve_vod/ve_vod.dart';

part 'src/controls/ve_vod_player_controls.dart';
part 'src/controls/ve_vod_player_controls_bottom.dart';
part 'src/controls/ve_vod_player_controls_top.dart';
part 'src/controls/widget/controls_duration.dart';
part 'src/controls/widget/controls_marquee.dart';
part 'src/controls/widget/controls_max_playback.dart';
part 'src/controls/widget/controls_play_pause.dart';
part 'src/controls/widget/controls_vertical.dart';
part 'src/ve_vod_controls.dart';
part 'src/ve_vod_player.dart';
part 'src/ve_vod_player_body.dart';
part 'src/ve_vod_player_config.dart';

/// Android 渠道默认值
const String kAppChannel = 'VeVodControlsChannel';

/// Android 默认缓存地址文件夹名称
const String kCacheDir = 'VeVodControlsCache';

/// 默认缓存地址文件夹大小
/// Android 300 * 1024 * 1024 (300MB)
/// iOS 100 * 1024 * 1024 (100MB)
int kMaxCacheSize = (isIOS ? 100 : 300) * 1024 * 1024;

/// Whether the operating system is a version of
/// [Android](https://en.wikipedia.org/wiki/Android_%28operating_system%29).
bool isAndroid = defaultTargetPlatform == TargetPlatform.android;

/// Whether the operating system is a version of
/// [iOS](https://en.wikipedia.org/wiki/IOS).
bool isIOS = defaultTargetPlatform == TargetPlatform.iOS;

/// 版本号合规验证
bool isAppVersion(String input) {
  if (input.isEmpty) return false;
  return RegExp(r'^\d+(\.\d+){2,}$').hasMatch(input);
}

/// 日志
void kLog(String message) => debugPrint('VeVodControls $message');
