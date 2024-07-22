/// @Describe: 视频控制组件
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of ve_vod_controls;

class VeVodPlayerControls extends StatefulWidget {
  const VeVodPlayerControls({
    super.key,
    required this.controller,
    required this.value,
    required this.size,
  });

  /// 构造
  static ChangeNotifierProvider<VeVodPlayerControlsController> structure(
    VeVodPlayerController controller, {
    required VeVodPlayerValue value,
    required Size size,
  }) {
    return ChangeNotifierProvider<VeVodPlayerControlsController>(
      key: Key('VeVodPlayerControlsController_${controller.hashCode}'),
      create: (_) => VeVodPlayerControlsController(
        controller.controlsConfig,
        isVisible: value.isFullScreen,
        needTimer: value.isPlaying,
      ),
      child: VeVodPlayerControls(
        controller: controller,
        value: value,
        size: size,
      ),
    );
  }

  /// 播放控制器
  final VeVodPlayerController controller;

  /// 播放数据
  final VeVodPlayerValue value;

  /// 尺寸范围
  final Size size;

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
      showOrHide(visible: false);
      if (!isFullScreen) {
        Future<void>.delayed(Durations.short4, () => showOrHide(visible: true));
      }
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
    /// 控制器主体
    /// + 显示/隐藏
    Widget child = Selector<VeVodPlayerControlsController, bool>(
      builder: (BuildContext context, bool isVisible, Widget? child) {
        return AnimatedOpacity(
          opacity: value.isCompleted || isVisible ? 1 : 0,
          duration: kAnimationDuration,
          child: AbsorbPointer(absorbing: !isVisible, child: child),
        );
      },
      selector: (_, __) => __._isVisible,
      child: _buildBody,
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

    /// [showOrHide] 方法不受锁定的限制
    child = GestureDetector(onTap: showOrHide, child: child);

    return Stack(
      children: <Widget>[
        VeVodPlayerSafeArea(size: widget.size, child: _buildTooltip),
        child,
      ],
    );
  }

  /// 控制器主体
  Widget get _buildBody {
    final Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Visibility(
          visible: !value.isLock && !value.isDragProgress,
          child: const VeVodPlayerControlsTop(),
        ),
        Visibility(
          visible: !value.isLock && !value.isCompleted,
          child: VeVodPlayerControlsBottom(
            onPlayOrPause: togglePlayPause,
            onDragStart: onHorizontalDragStart,
            onDragUpdate: onDragUpdate,
            onDragEnd: onHorizontalDragEnd,
            onTapUp: onTapUp,
            onFullScreen: controller.toggleFullScreen,
          ),
        ),
      ],
    );

    /// 视频播放完成所展示的按钮
    final Widget finish = GestureDetector(
      onTap: togglePlayPause,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.85),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.refresh_rounded),
      ),
    );

    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        child,
        if (!value.isCompleted && !value.isDragProgress && value.isFullScreen)
          VeVodPlayerControlsCenter(
            onShowControls: () => showOrHide(visible: true),
          ),
        if (value.isCompleted) finish,
      ],
    );
  }

  /// 提示组件
  Widget get _buildTooltip {
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
            color: _controlsController.config.toolTipBackgroundColor,
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

    if (value.isDragVertical) {
      child = ControlsVertical(
        value: value.dragVerticalValue,
        type: value.dragVerticalType,
        color: _controlsController.config.foregroundColor,
      );
    }

    if (value.isBuffering) {
      child = Text(
        '正在缓冲...',
        style: _controlsController.config.defaultTextStyle,
      );
    }

    if (value.isCompleted) {
      return Container(
        decoration: BoxDecoration(
          color: _controlsController.config.toolTipBackgroundColor,
        ),
      );
    }

    return background(child: child);
  }

  /// 显示/隐藏 控制器
  void showOrHide({bool? visible, bool? needTimer}) {
    _controlsController
      .._cancelTimer()
      ..showOrHide(visible: visible, needTimer: needTimer ?? value.isPlaying);
  }

  /// 播放/暂停 视频
  Future<void> togglePlayPause() async {
    if (!allowPressed) return;

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
      () => showOrHide(visible: true),
    );
  }

  /// 长按开始，触发最大播放速率播放
  void onLongPressStart(LongPressStartDetails details) {
    if (!allowPressed ||
        !_controlsController.config.allowLongPress ||
        !value.isPlaying ||
        value.isMaxPlaybackSpeed) {
      return;
    }

    /// 隐藏
    showOrHide(visible: false);
    controller.setMaxPlaybackSpeed();
  }

  /// 长按结束，恢复播放速率
  void onLongPressEnd(LongPressEndDetails details) {
    if (!value.isMaxPlaybackSpeed) return;
    controller.setPlaybackSpeed();
  }

  /// 纵向滑动开始，触发音量/亮度调节
  Future<void> onVerticalDragStart(DragStartDetails details) async {
    if (!allowPressed ||
        !_controlsController.config.allowVolumeOrBrightness ||
        value.isCompleted ||
        value.isDragVertical) return;

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
    if (!value.isDragVertical) return;

    double data = value.dragVerticalValue - (details.delta.dy / totalHeight);
    data = clampDouble(data, 0, 1);
    controller._setDragVerticalValue(data);

    /// 实时改变
    if (value.dragVerticalType == DragVerticalType.brightness) {
      controller.setBrightness(data);
    } else if (value.dragVerticalType == DragVerticalType.volume) {
      controller.setVolume(data);
    }
  }

  /// 纵向滑动结束，结束音量/亮度调节触发
  void onVerticalDragEnd(DragEndDetails details) {
    if (!value.isDragVertical) return;
    controller._setDragVertical(false);
  }

  /// 横向滑动开始，触发播放进度调节
  void onHorizontalDragStart(DragStartDetails details) {
    if (!allowPressed ||
        !_controlsController.config.allowProgress ||
        value.isCompleted ||
        value.isDragProgress) {
      return;
    }

    /// 显示
    showOrHide(visible: true, needTimer: false);
    controller._setDragProgress(true);
  }

  /// 横向滑动，调节播放进度
  void onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!value.isDragProgress) return;

    final double relative = details.delta.dx / totalWidth;
    controller._setDragDuration(
      value.dragDuration + value.dragTotalDuration * relative,
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
    showOrHide(visible: true);

    /// 设置播放进度，并关闭进度调节
    controller
      ..seekTo(value.dragDuration)
      .._setDragProgress(false);
  }

  /// 点击进度条更改视频播放进度
  void onTapUp(double relative) {
    if (!allowPressed || value.isBuffering || value.isCompleted) return;
    controller.seekTo(value.duration * relative);
  }

  /// 操作是否可以执行
  bool get allowPressed => !value.isLock && value.isInitialized;

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
        () => showOrHide(visible: true, needTimer: needTimer),
      );
    }
  }

  final VeVodPlayerControlsConfig config;

  /// 防止页面销毁后，异步任务才完成，导致报错
  bool _isDisposed = false;

  /// 是否展示计时器
  bool _isVisible = false;

  /// 计时器
  Timer? _timer;

  /// 显示或隐藏控制组件
  void showOrHide({bool? visible, bool needTimer = true}) {
    _isVisible = visible ?? !_isVisible;
    notifyListeners();

    if (_isVisible && needTimer) {
      _startTimer();
    } else if (!_isVisible) {
      _cancelTimer();
    }
  }

  /// 开启计时
  void _startTimer() {
    _cancelTimer();

    _timer = Timer.periodic(config.hideDuration, (Timer timer) {
      if (!timer.isActive) return;

      _isVisible = false;
      notifyListeners();

      /// 注销计时器
      _cancelTimer();
    });
  }

  /// 注销[_timer]
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    /// 注销计时器
    _cancelTimer();

    super.dispose();
  }
}

/// [VeVodPlayerControls]的默认隐藏时间
const Duration kDefaultHideDuration = Duration(seconds: 3);

/// 动画时长
const Duration kAnimationDuration = Duration(milliseconds: 300);

/// 音量或屏幕亮度
enum DragVerticalType {
  /// 屏幕亮度
  brightness(
    Icons.brightness_low_rounded,
    Icons.brightness_medium_rounded,
    Icons.brightness_high_rounded,
  ),

  /// 音量
  volume(
    Icons.volume_mute_rounded,
    Icons.volume_down_rounded,
    Icons.volume_up_rounded,
  );

  const DragVerticalType(this.iconLow, this.iconMedium, this.iconHigh);

  /// ≤ 0
  final IconData iconLow;

  /// > 0 and < .5
  final IconData iconMedium;

  /// ≥ .5
  final IconData iconHigh;

  IconData getIcon(double value) {
    if (value <= 0) {
      return iconLow;
    } else if (value < .5) {
      return iconMedium;
    } else {
      return iconHigh;
    }
  }
}
