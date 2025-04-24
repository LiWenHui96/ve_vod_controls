/// @Describe: 视频控制组件
///
/// @Author: LiWeNHuI
/// @Date: 2025/4/23

library;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

import '../player/ve_vod_player.dart';

part 've_vod_player_controls_bottom.dart';

part 've_vod_player_controls_center.dart';

part 've_vod_player_controls_top.dart';

part 'widget/controls_duration.dart';

part 'widget/controls_lock.dart';

part 'widget/controls_marquee.dart';

part 'widget/controls_max_playback.dart';

part 'widget/controls_play_pause.dart';

part 'widget/controls_speed.dart';

part 'widget/controls_vertical.dart';

/// 动画时长
const Duration kAnimationDuration = Durations.medium2;

/// 音量或屏幕亮度
enum DragVerticalType {
  /// 屏幕亮度
  brightness,

  /// 音量
  volume;

  Icon? getIcon(double value) {
    if (this == DragVerticalType.brightness) {
      if (value == 0) {
        return const Icon(CupertinoIcons.sun_min);
      } else if (value < .3) {
        return const Icon(CupertinoIcons.sun_min_fill);
      } else if (value < .7) {
        return const Icon(CupertinoIcons.sun_min_fill, color: Colors.yellow);
      } else {
        return const Icon(CupertinoIcons.sun_max_fill, color: Colors.yellow);
      }
    } else if (this == DragVerticalType.volume) {
      if (value == 0) {
        return const Icon(CupertinoIcons.speaker_slash_fill);
      } else if (value < .25) {
        return const Icon(CupertinoIcons.speaker_1_fill);
      } else if (value < .5) {
        return const Icon(CupertinoIcons.speaker_1_fill, color: Colors.blue);
      } else if (value < .75) {
        return const Icon(CupertinoIcons.speaker_2_fill, color: Colors.blue);
      } else {
        return const Icon(CupertinoIcons.speaker_3_fill, color: Colors.blue);
      }
    }
    return null;
  }
}
