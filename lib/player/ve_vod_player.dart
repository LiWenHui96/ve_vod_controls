/// @Describe: 火山云 视频点播 Flutter SDK 实现
///            https://www.volcengine.com/docs/4/1264514
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/15

library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:ve_vod/ve_vod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../controls/ve_vod_player_controls.dart';

part 've_vod_player_body.dart';

part 've_vod_player_config.dart';

part 've_vod_player_controller.dart';

part 've_vod_player_controls.dart';

/// {@template ve.vod.controls.VodPlayer}
/// 视频播放器
/// 以火山云视频点播Flutter为基石，携带有控制器等功能
/// {@endtemplate}
class VeVodPlayer extends StatefulWidget {
  const VeVodPlayer({super.key, required this.controller});

  /// {@macro ve.vod.controls.VodPlayerController}
  final VeVodPlayerController controller;

  /// {@macro ve.vod.controls.VeVodPlayerRouteObserver}
  ///
  /// example:
  /// MaterialApp(
  ///   navigatorObservers: <NavigatorObserver>[
  ///     ...
  ///     VeVodPlayer.observer,
  ///     ...
  ///   ],
  /// );
  // ignore: always_specify_types
  static RouteObserver<PageRoute> observer = RouteObserver<PageRoute>();

  @override
  State<VeVodPlayer> createState() => _VeVodPlayerState();
}

class _VeVodPlayerState extends State<VeVodPlayer> {
  @override
  void didUpdateWidget(covariant VeVodPlayer oldWidget) {
    if (oldWidget.controller.uniqueId != widget.controller.uniqueId) {
      /// 注销
      oldWidget.controller.dispose();

      /// 初始化
      controller._initVodPlayer();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final TTVideoPlayerView vodPlayerView = TTVideoPlayerView(
      key: Key('Ve_Vod_Player_${controller.hashCode}'),
      nativeViewType: controller._nativeViewType,
      onPlatformViewCreated: controller._init,
    );

    return _buildSafeArea(
      build: (Size? size, bool useSafe) {
        Widget child = vodPlayerView;

        if (useSafe) child = VeVodPlayerSafeArea(child: child);

        return ColoredBox(
          color: config.backgroundColor,
          child: SizedBox.fromSize(
            size: size ?? MediaQuery.sizeOf(context),
            child: VeVodPlayerBody(controller: controller, child: child),
          ),
        );
      },
    );
  }

  /// 是否构建安全区域的判断
  Widget _buildSafeArea({required VeVodPlayerSafeAreaBuilder build}) {
    return ChangeNotifierProvider<VeVodPlayerController>.value(
      value: controller,
      builder: (_, __) => Selector<VeVodPlayerController, bool>(
        builder: (_, bool isFullScreen, __) => PopScope(
          onPopInvokedWithResult: (bool didPop, dynamic result) {
            if (didPop) return;
            if (isFullScreen) controller.toggleFullScreen(isFullScreen: false);
          },
          canPop: !isFullScreen,
          child: build.call(isFullScreen ? null : config.size, !isFullScreen),
        ),
        selector: (_, VeVodPlayerController controller) {
          return controller.value.isFullScreen;
        },
      ),
    );
  }

  VeVodPlayerConfig get config => controller.config;

  VeVodPlayerController get controller => widget.controller;
}

typedef VeVodPlayerSafeAreaBuilder = Widget Function(Size?, bool);
