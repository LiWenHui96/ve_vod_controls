/// @Describe: 视频控制组件 底部
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of ve_vod_player;

class VeVodPlayerControlsBottom extends StatelessWidget {
  const VeVodPlayerControlsBottom({
    super.key,
    required this.onImmVisible,
    required this.onVisible,
    required this.onPlayOrPause,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapUp,
    required this.onSpeed,
    required this.onFullScreen,
  });

  /// 即刻隐蔽控制器
  final VoidCallback? onImmVisible;

  /// 隐蔽控制器
  final VoidCallback? onVisible;

  /// 播放/暂停 视频
  final VoidCallback? onPlayOrPause;

  /// 滑动开始，触发进度调节
  final GestureDragStartCallback onDragStart;

  /// 滑动，调节播放进度
  final ValueChanged<double> onDragUpdate;

  /// 滑动结束，结束进度调节触发效果
  final GestureDragEndCallback onDragEnd;

  /// 点击进度条更改视频播放进度
  final ValueChanged<double> onTapUp;

  /// 播放速度变化
  final ValueChanged<double>? onSpeed;

  /// 启用/禁用全屏模式
  final VoidCallback? onFullScreen;

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerValue value = controller.value;
    final VeVodPlayerControlsConfig config = controller.controlsConfig;

    /// 播放/暂停 按钮
    final Widget playPause = ControlsPlayPause(
      isPlaying: value.isPlaying,
      duration: kAnimationDuration,
      size: config.iconSize,
      color: config.foregroundColor,
      onPressed: onPlayOrPause,
    );

    /// 播放进度
    final Widget duration =
        ControlsDuration(position: value.position, duration: value.duration);

    /// 播放进度条
    final Widget progressBar = ControlsProgress(
      colors: config.progressColors,
      value: value,
      height: config.iconSize,
      onDragStart: onDragStart,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      onTapUp: onTapUp,
    );

    /// 全屏控制按钮
    final Widget fullScreenButton = IconButton(
      iconSize: config.iconSize,
      visualDensity: VisualDensity.comfortable,
      padding: EdgeInsets.zero,
      color: config.foregroundColor,
      onPressed: () {
        onImmVisible?.call();
        onFullScreen?.call();
      },
      enableFeedback: true,
      isSelected: value.isFullScreen,
      selectedIcon: const Icon(Icons.fullscreen_exit),
      icon: const Icon(Icons.fullscreen),
    );

    Widget child = Padding(
      padding: const EdgeInsets.only(left: 16),
      child: progressBar,
    );

    /// 屏幕方向
    final Orientation orientation = MediaQuery.orientationOf(context);

    if (orientation == Orientation.landscape) {
      /// 播放进度
      final Widget speedButton = ControlsSpeed(
        speed: value.playbackSpeed,
        onChanged: onSpeed,
        onVisible: onVisible,
      );

      child = Row(children: <Widget>[duration, Expanded(child: child)]);

      child = Column(
        children: <Widget>[
          Padding(padding: const EdgeInsets.fromLTRB(8, 8, 8, 0), child: child),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              playPause,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (value.isFullScreen) speedButton,
                  fullScreenButton,
                ],
              ),
            ],
          ),
        ],
      );
    } else if (orientation == Orientation.portrait) {
      child = Row(
        children: <Widget>[
          playPause,
          duration,
          Expanded(child: child),
          fullScreenButton,
        ],
      );
    }

    final EdgeInsets padding = MediaQuery.paddingOf(context);
    if (orientation == Orientation.landscape) {
      child = Padding(
        padding: EdgeInsets.only(bottom: padding.bottom / 4),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: config.backgroundColor,
        ),
      ),
      child: VeVodPlayerSafeArea(top: false, child: child),
    );
  }
}
