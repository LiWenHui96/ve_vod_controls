/// @Describe: 视频控制组件
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of 've_vod_player.dart';

class VeVodPlayerControls extends StatefulWidget {
  const VeVodPlayerControls({
    super.key,
    required this.controller,
    required this.value,
  });

  /// 构造
  static ChangeNotifierProvider<VeVodPlayerControlsController> structure(
    VeVodPlayerController controller, {
    required VeVodPlayerValue value,
  }) {
    return ChangeNotifierProvider<VeVodPlayerControlsController>(
      key: Key('VeVodPlayerControlsController_${controller.hashCode}'),
      create: (_) => VeVodPlayerControlsController(
        controller.controlsConfig,
        isVisible: value.isFullScreen,
        needTimer: value.isPlaying,
      ),
      child: VeVodPlayerControls(controller: controller, value: value),
    );
  }

  /// 播放控制器
  final VeVodPlayerController controller;

  /// 播放数据
  final VeVodPlayerValue value;

  @override
  State<VeVodPlayerControls> createState() => _VeVodPlayerControlsState();
}

class _VeVodPlayerControlsState extends State<VeVodPlayerControls> {
  late VeVodPlayerControlsController _controlsController;

  /// 监控全屏的状态变化
  StreamSubscription<bool>? _stream;

  /// 播放控制器
  VeVodPlayerController get controller => widget.controller;

  /// 播放数据
  VeVodPlayerValue get value => widget.value;

  @override
  void initState() {
    _controlsController = context.read<VeVodPlayerControlsController>();

    /// 全屏相关
    _stream = controller._fullScreenStream.stream.listen((bool isFullScreen) {
      Future<void>.delayed(Durations.long2, () {
        _controlsController.toggleImmVisible(visible: true);
        if (!isFullScreen) toggleVisible(visible: true);
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _stream?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Visibility(
          visible: value._allowControlsTop,
          child: const VeVodPlayerControlsTop(),
        ),
        Visibility(
          visible: value._allowControlsBottom,
          child: VeVodPlayerControlsBottom(
            onImmVisible: () {
              _controlsController.toggleImmVisible(visible: false);
            },
            onVisible: () => toggleVisible(visible: false),
            onPlayOrPause: togglePlayPause,
            onDragStart: onHorizontalDragStart,
            onDragUpdate: onDragUpdate,
            onDragEnd: onHorizontalDragEnd,
            onTapUp: onTapUp,
            onSpeed: (double speed) {
              controller.setPlaybackSpeed(speed: speed, hasTimer: true);
            },
            onFullScreen: () {
              final bool flag = controller.toggleFullScreen();
              if (!flag) _controlsController.toggleImmVisible(visible: true);
            },
          ),
        ),
      ],
    );

    /// 控制器主体
    /// + 显示/隐藏
    child = Selector<VeVodPlayerControlsController, bool>(
      builder: (_, bool isVisible, Widget? child) {
        return AnimatedOpacity(
          opacity: value._allowControls || isVisible ? 1 : 0,
          duration: kAnimationDuration,
          child: AbsorbPointer(absorbing: !isVisible, child: child),
        );
      },
      selector: (_, VeVodPlayerControlsController controller) {
        return controller._isVisible;
      },
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          child,
          if (value._allowControlsCenter)
            VeVodPlayerControlsCenter(
              onLock: () {
                toggleVisible(visible: true);
                controller._toggleLock();
              },
            ),
        ],
      ),
    );

    /// 控制器主体
    /// + 即刻显示/隐藏
    child = Selector<VeVodPlayerControlsController, bool>(
      builder: (_, bool isVisible, Widget? child) {
        child ??= const SizedBox.shrink();
        return Visibility(visible: isVisible, child: child);
      },
      selector: (_, VeVodPlayerControlsController controller) {
        return controller._immVisible;
      },
      child: child,
    );

    /// 双击播放/暂停、长按最大速度播放、调整音量、调整屏幕亮度、调节播放进度
    child = GestureDetector(
      onDoubleTap: togglePlayPause,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      onVerticalDragStart: onVerticalDragStart,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      onHorizontalDragStart: onHorizontalDragStart,
      onHorizontalDragUpdate: onHorizontalDragUpdate,
      onHorizontalDragEnd: onHorizontalDragEnd,
      behavior: HitTestBehavior.opaque,
      child: child,
    );

    /// [toggleVisible] 方法不受锁定的限制
    child = GestureDetector(onTap: toggleVisible, child: child);

    return Stack(
      children: <Widget>[
        VeVodPlayerSafeArea(child: _buildTooltip),
        child,
        _buildOperation,
      ],
    );
  }

  /// 操作控件
  Widget get _buildOperation {
    Widget? child;

    if (value.hasError) {
      child = GestureDetector(
        onTap: () {
          controller
            ..seekTo(Duration.zero)
            .._setIsCompleted(false);
          togglePlayPause();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.refresh_rounded, color: Colors.white),
            const SizedBox(height: 4),
            Text('播放失败', style: config.defaultTextStyle),
          ],
        ),
      );
    }

    if (value.isExceedsPreviewTime) {
      child = config.onMaxPreviewTimeBuilder?.call(context, controller, value);
      child ??= Text('试看结束', style: config.defaultTextStyle);
    }

    if (value.isCompleted) {
      child = GestureDetector(
        onTap: () {
          controller._setIsCompleted(false);
          togglePlayPause();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, .85),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.refresh_rounded),
        ),
      );
    }

    if (value._hasPlayButton) {
      child = Icon(
        Icons.play_arrow_rounded,
        size: 60,
        color: config.foregroundColor,
      );

      child = GestureDetector(
        onTap: togglePlayPause,
        child: config.onPauseBuilder ?? child,
      );
    }

    return VeVodPlayerSafeArea(child: Center(child: child));
  }

  /// 提示组件
  Widget get _buildTooltip {
    if (value.hasError || value.isExceedsPreviewTime) {
      return Container(color: Colors.black);
    }
    if (value.isCompleted) {
      return Container(color: config.toolTipBackgroundColor);
    }

    Widget background({
      Widget? child,
      AlignmentGeometry? alignment,
      EdgeInsetsGeometry? margin,
    }) {
      if (child == null) return const SizedBox.shrink();
      return Align(
        alignment: alignment ?? Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: config.toolTipBackgroundColor,
            borderRadius: BorderRadius.circular(6),
          ),
          margin: margin,
          child: child,
        ),
      );
    }

    Widget? child;

    if (value.isMaxPlaybackSpeed) {
      return background(
        child: const ControlsMaxPlayback(),
        alignment: Alignment.topCenter,
        margin: const EdgeInsets.only(top: 12),
      );
    }

    if (value.isDragProgress) {
      child = ControlsDuration(
        duration: value.duration,
        position: value.dragDuration,
      );
    }

    if (value._isDragVertical) {
      child = ControlsVertical(
        value: value._dragVerticalValue,
        type: value._dragVerticalType,
      );
    }

    if (value.isBuffering) {
      child = Text('正在缓冲...', style: config.defaultTextStyle);
    }

    if (value.isPlaybackSpeed) {
      child = Text('x${value.playbackSpeed}', style: config.defaultTextStyle);
    }

    return background(child: child);
  }

  /// 显示/隐藏 控制器
  void toggleVisible({bool? visible, bool? needTimer}) {
    needTimer ??= value.isPlaying;
    _controlsController
      ..cancelTimer()
      ..toggleVisible(visible: visible, needTimer: needTimer);
  }

  /// 播放/暂停 视频
  Future<void> togglePlayPause() async {
    if (!value._allowPressed) return;

    if (value.isPlaying) {
      await controller.pause();
      controller._isPauseByUser = true;
    } else {
      await controller.play();
      controller._isPauseByUser = false;
    }

    /// 注销计时器，并开启显示
    await Future<void>.delayed(
      Durations.short1,
      () => toggleVisible(visible: true),
    );
  }

  /// 长按开始，触发最大播放速率播放
  void onLongPressStart(LongPressStartDetails details) {
    if (!config.allowLongPress || !value._allowLongPress) {
      toggleVisible(visible: true);
      return;
    }

    /// 隐藏
    toggleVisible(visible: false);
    controller.setMaxPlaybackSpeed();
  }

  /// 长按结束，恢复播放速率
  void onLongPressEnd(LongPressEndDetails details) {
    if (!value.isMaxPlaybackSpeed) return;
    controller.setPlaybackSpeed();
  }

  /// 纵向滑动开始，触发音量/亮度调节
  Future<void> onVerticalDragStart(DragStartDetails details) async {
    if (!config.allowVolumeOrBrightness || !value._allowVerticalDrag) {
      toggleVisible(visible: true);
      return;
    }

    final DragVerticalType type = details.globalPosition.dx < totalWidth / 2
        ? DragVerticalType.brightness
        : DragVerticalType.volume;
    double currentValue = 0;
    if (type == DragVerticalType.brightness) {
      currentValue = await controller.brightness;
    } else if (type == DragVerticalType.volume) {
      currentValue = await controller.volume;
    }
    controller._setDragVertical(true, type: type, currentValue: currentValue);
  }

  /// 纵向滑动，调节音量/亮度调节
  void onVerticalDragUpdate(DragUpdateDetails details) {
    if (!value._isDragVertical) return;

    double data = value._dragVerticalValue - (details.delta.dy / totalHeight);
    data = ui.clampDouble(data, 0, 1);
    controller._setDragVerticalValue(data);

    /// 实时改变
    if (value._dragVerticalType == DragVerticalType.brightness) {
      controller.setBrightness(data);
    } else if (value._dragVerticalType == DragVerticalType.volume) {
      controller.setVolume(data);
    }
  }

  /// 纵向滑动结束，结束音量/亮度调节触发
  void onVerticalDragEnd(DragEndDetails details) {
    if (!value._isDragVertical) return;
    controller._setDragVertical(false);
  }

  /// 横向滑动开始，触发播放进度调节
  void onHorizontalDragStart(DragStartDetails details) {
    if (!config.allowProgress || !value._allowHorizontalDrag) {
      toggleVisible(visible: true);
      return;
    }

    /// 显示
    toggleVisible(visible: true, needTimer: false);
    controller._setDragProgress(true);
  }

  /// 横向滑动，调节播放进度
  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!value.isDragProgress) return;

    final double relative = details.delta.dx / totalWidth;
    controller._setDragDuration(
      value.dragDuration + value._dragTotalDuration * relative,
    );
  }

  /// 滑动，调节播放进度
  void onDragUpdate(double relative) {
    if (!value.isDragProgress) return;
    controller._setDragDuration(value.duration * relative);
  }

  /// 横向滑动结束，结束播放进度调节触发
  void onHorizontalDragEnd(DragEndDetails details) {
    if (!value.isDragProgress) return;

    /// 显示
    toggleVisible(visible: true);

    /// 设置播放进度，并关闭进度调节
    controller
      ..seekTo(value.dragDuration)
      .._setDragProgress(false);
  }

  /// 点击进度条更改视频播放进度
  void onTapUp(double relative) {
    if (!value._allowTapProgress) return;
    controller._setTapDuration(value.duration * relative);
  }

  /// 配置
  VeVodPlayerControlsConfig get config => _controlsController.config;

  /// 水平范围
  double get totalWidth => size.width.ceilToDouble();

  /// 垂直范围
  double get totalHeight => size.height.ceilToDouble();

  /// 视图尺寸
  Size get size => context.size ?? MediaQuery.of(context).size;
}

class VeVodPlayerControlsController extends ChangeNotifier {
  VeVodPlayerControlsController(
    this.config, {
    required bool isVisible,
    required bool needTimer,
  }) {
    if (config.showAtStartUp || isVisible) {
      final Duration duration = isVisible ? Durations.short4 : Duration.zero;
      Future<void>.delayed(
        duration,
        () => toggleVisible(visible: true, needTimer: needTimer),
      );
    }
  }

  final VeVodPlayerControlsConfig config;

  /// 防止页面销毁后，异步任务才完成，导致报错
  bool _isDisposed = false;

  /// 是否展示控制器
  bool _isVisible = false;

  /// 即刻消失
  bool _immVisible = true;

  /// 计时器
  Timer? _timer;

  /// 显示或隐藏控制组件
  void toggleVisible({bool? visible, bool needTimer = true}) {
    _isVisible = visible ?? !_isVisible;
    notifyListeners();

    if (_isVisible && needTimer) {
      startTimer();
    } else if (!_isVisible) {
      cancelTimer();
    }
  }

  /// 开启计时
  void startTimer() {
    cancelTimer();

    _timer = Timer.periodic(config.hideDuration, (Timer timer) {
      if (!timer.isActive) return;

      _isVisible = false;
      notifyListeners();

      /// 注销计时器
      cancelTimer();
    });
  }

  /// 注销[_timer]
  void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 即刻显示/消失
  void toggleImmVisible({bool? visible}) {
    _immVisible = visible ?? !_immVisible;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    /// 注销计时器
    cancelTimer();

    super.dispose();
  }
}
