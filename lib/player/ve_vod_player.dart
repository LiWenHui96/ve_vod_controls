/// @Describe: 火山云 视频点播 Flutter SDK 实现
///            https://www.volcengine.com/docs/4/1264514
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/15

library;

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
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
  /// 监控全屏的状态变化
  StreamSubscription<bool>? _fullScreenStream;

  @override
  void initState() {
    /// 全屏相关
    _fullScreenStream = controller._fullScreenStream.stream.listen(_listener);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant VeVodPlayer oldWidget) {
    if (oldWidget.controller.uniqueId != widget.controller.uniqueId) {
      /// 注销
      oldWidget.controller.dispose();

      /// 初始化
      controller._initVodPlayer();

      _fullScreenStream?.cancel();
      _fullScreenStream = controller._fullScreenStream.stream.listen(_listener);
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _fullScreenStream?.cancel();

    super.dispose();
  }

  /// 全屏状态监听
  Future<void> _listener(bool isFullScreen) async {
    if (controller._isFull) {
      unawaited(controller._toggleOrientations());
      return;
    }

    if (isFullScreen) {
      final PageRouteBuilder<dynamic> route = PageRouteBuilder<dynamic>(
        pageBuilder: (_, Animation<double> animation, ___) => AnimatedBuilder(
          animation: animation,
          builder: (_, __) => VeVodPlayerFull(controller: controller),
        ),
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          final CurvedAnimation parent =
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
          return SlideTransition(
            position: Tween<Offset>(begin: Offset.zero, end: Offset.zero)
                .animate(parent),
            child: child,
          );
        },
        fullscreenDialog: true,
      );
      await Navigator.push(context, route);
    } else {
      Future<void>.delayed(Durations.short1, () {
        controller._toggleOrientations();
        Navigator.pop(context);
      });
      await controller._setPlayerContainerView(controller.viewId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TTVideoPlayerView vodPlayerView = TTVideoPlayerView(
      key: Key('Ve_Vod_Player_${controller.hashCode}'),
      nativeViewType: controller._nativeViewType,
      onPlatformViewCreated: controller._init,
    );

    return _buildBody(
      build: (bool useSafe) {
        Widget child = vodPlayerView;

        if (useSafe) child = VeVodPlayerSafeArea(child: child);

        return Container(
          color: config.backgroundColor,
          width: config.width,
          height: config.height,
          child: VeVodPlayerBody(controller: controller, child: child),
        );
      },
    );
  }

  /// 主体
  Widget _buildBody({required Widget Function(bool) build}) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = constraints.constrain(config.size);

        /// 屏幕尺寸
        final Size screenSize = MediaQuery.sizeOf(context);

        if (size == screenSize) {
          controller._isFull = true;

          return ChangeNotifierProvider<VeVodPlayerController>.value(
            value: controller,
            builder: (_, __) => Selector<VeVodPlayerController, bool>(
              builder: (_, bool isFullScreen, __) {
                return PopScope(
                  onPopInvoked: (bool didPop) {
                    if (didPop) return;
                    if (isFullScreen) {
                      controller.toggleFullScreen(isFullScreen: false);
                    }
                  },
                  canPop: !isFullScreen,
                  child: build.call(!isFullScreen),
                );
              },
              selector: (_, __) => __.value.isFullScreen,
            ),
          );
        }

        return build.call(true);
      },
    );
  }

  VeVodPlayerConfig get config => controller.config;

  VeVodPlayerController get controller => widget.controller;
}
