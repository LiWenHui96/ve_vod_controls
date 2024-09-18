/// @Describe: 火山云 视频点播 Flutter SDK 实现
///            https://www.volcengine.com/docs/4/1264515
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/15

part of ve_vod_controls;

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

/// {@template ve.vod.controls.VodPlayerController}
/// 播放控制器
///
/// 包含资源数据、配置文件
///
/// 实现 创建播放器、设置播放源 等基础功能，以及播放控制、设置自定义Header、设置填充模式、
/// 设置旋转角度、设置镜像模式、设置循环播放、设置倍速播放、静音、调节音量、设置业务类型、
/// 设置自定义标签、设置清晰度、播放私有加密视频、获取播放信息、播放状态回调 功能
///
/// 后续支持高阶功能
/// 纯音频播放、展示当前视频下载进度、短视频场景预加载和预渲染策略、自定义预加载等功能
///
/// https://www.volcengine.com/docs/4/1264702
/// {@endtemplate}
class VeVodPlayerController extends ValueNotifier<VeVodPlayerValue> {
  VeVodPlayerController(
    this.source, {
    VeVodPlayerConfig? config,
    VeVodPlayerControlsConfig? controlsConfig,
  })  : config = config ?? VeVodPlayerConfig(),
        controlsConfig = controlsConfig ?? VeVodPlayerControlsConfig(),
        super(const VeVodPlayerValue.uninitialized()) {
    _initVodPlayer();
  }

  /// 播放源
  final TTVideoEngineMediaSource source;

  /// 视频播放器[VeVodPlayer]配置
  final VeVodPlayerConfig config;

  /// 视频播放控制器[VeVodPlayerControls]配置
  final VeVodPlayerControlsConfig controlsConfig;

  /// 播放源ID
  String? get uniqueId => source.getUniqueId;

  /// 创建 [VodPlayerFlutter] 实例
  final VodPlayerFlutter _vodPlayer = VodPlayerFlutter();

  /// 屏幕亮度控制
  final ScreenBrightness _brightness = ScreenBrightness();

  /// 是否初始化成功
  bool _isInitialized = false;

  /// 是否为首次初始化
  bool _isFirstInit = true;

  /// 播放器视图id
  int viewId = -1;

  /// 本机视图类型，仅支持Android端
  NativeViewType _nativeViewType = NativeViewType.TextureView;

  /// 计时器
  Timer? _timer;

  /// 默认播放速度
  double _defaultPlaybackSpeed = 1;
  Timer? _playbackSpeedTimer;

  /// 是否为用户暂停操作
  bool _isPauseByUser = false;

  /// 监控全屏的状态变化
  final StreamController<bool> _fullScreenStream =
      StreamController<bool>.broadcast();

  /// 是否占满屏幕
  bool _isFull = false;

  bool _isDisposed = false;

  static VeVodPlayerController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VeVodPlayerInherited>()!
      .controller;

  /// 执行初始化[VodPlayerFlutter]操作
  Future<void> _initVodPlayer() async {
    /// 是否开启常亮模式
    if (!config.allowedScreenSleep) await WakelockPlus.enable();

    /// 创建播放器
    await _vodPlayer.createPlayer();

    /// 设置监听
    _listener();

    /// 设置 HTTP Header
    await _setCustomHeader(config.httpHeaders);

    /// 设置[TTVideoPlayerView.nativeViewType]
    _nativeViewType = NativeViewType.TextureView;

    if (!_isInitialized) {
      _isInitialized = true;
      if (!viewId.isNegative) unawaited(_init(viewId));
    }

    /// 设置播放源
    await _vodPlayer.setMediaSource(source);

    await Future.wait(<Future<void>>[
      /// 将起播位置设置为[config.startAt]
      setStartTimeMs(config.startAt),

      /// 设置是否循环播放
      setLooping(config.looping),

      /// 设置填充模式
      setScalingMode(
        TTVideoEngineScalingMode.TTVideoEngineScalingModeAspectFit,
      ),
    ]);

    if (config.autoInitialize || config.autoPlay) {
      /// 开启播放
      /// 用于获取相关信息
      /// 若未开启自动播放，则在[_vodPlayer.onPrepared]方法内暂停播放
      await play();
    }

    if (config.fullScreenAtStartUp) addListener(_fullScreenListener);
  }

  /// 执行初始化[TTVideoPlayerView]操作
  Future<void> _init(int viewId) async {
    if (!_isInitialized) {
      this.viewId = viewId;
      return;
    }

    /// 存储viewId
    if (!value.isFullScreen) this.viewId = viewId;

    /// 设置viewId
    await _setPlayerContainerView(viewId);
  }

  /// 设置[viewId]
  Future<void> _setPlayerContainerView(int viewId) async {
    await _vodPlayer.setPlayerContainerView(viewId);
  }

  /// 播放
  Future<void> play() async {
    /// 当存在异常时，跳转到异常位置
    if (value.hasError) await setStartTimeMs(value.position);

    await _vodPlayer.play();
  }

  /// 暂停
  Future<void> pause() async {
    await _vodPlayer.pause();
  }

  /// 停止
  Future<void> stop() async {
    await _vodPlayer.stop();
  }

  /// 将起播位置设置为[moment]
  Future<void> setStartTimeMs(Duration? moment) async {
    if (moment == null || value.isInitialized) return;
    await _vodPlayer.setStartTimeMs(moment.inMilliseconds.toDouble());
  }

  /// 将当前播放设置为[moment]。
  ///
  /// [onCompleted] 设置完成回调
  /// [onRenderCompleted] 设置后，第一帧渲染完成回调
  Future<void> seekTo(
    Duration? moment, {
    ValueChanged<bool>? onCompleted,
    VoidCallback? onRenderCompleted,
  }) async {
    if (moment == null) return;

    _closePlaybackSpeed();

    /// 开始缓冲
    value = value.copyWith(isBuffering: true);

    await _vodPlayer.seekToTimeMs(
      time: moment.inMilliseconds.toDouble(),
      seekCompleted: (bool isSeekCompleted) {
        onCompleted?.call(isSeekCompleted);

        value =
            value.copyWith(isBuffering: !value.isCompleted && isSeekCompleted);

        /// 设置失败情况下
        if (!isSeekCompleted) {
          value = value.copyWith(dragDuration: Duration.zero);
        }
      },
      seekRenderCompleted: () {
        onRenderCompleted?.call();

        /// 缓冲完成，渲染完第一帧，并清理[value.dragDuration]
        value = value.copyWith(isBuffering: false, dragDuration: Duration.zero);
      },
    );
  }

  /// 设置播放请求中的自定义 HTTP Header
  Future<void> _setCustomHeader(Map<String, String>? map) async {
    if (map == null || map.isEmpty) return;
    final Iterable<Future<void>> futures =
        map.entries.map((_) => _vodPlayer.setCustomHeader(_.key, _.value));
    await Future.wait(futures);
  }

  /// 设置填充模式
  /// TTVideoEngineScalingModeNone: 无拉伸，不会有变形，可能有黑边
  /// TTVideoEngineScalingModeAspectFit: 等比例适配，不会有变形，按照视频宽高等比适配画面，可能有黑边
  /// TTVideoEngineScalingModeAspectFill: 等比例填充，不会有变形，按照视频宽高等比充满画面，可能有画面裁切
  /// TTVideoEngineScalingModeFill: 拉伸填充，视频宽高比例与画面比例不一致，会导致画面变形
  Future<void> setScalingMode(TTVideoEngineScalingMode mode) async {
    await _vodPlayer.setScalingMode(mode);
  }

  /// 设置旋转方向
  /// 可设为 0、90、180、270
  Future<void> setRotation(int angle) async {
    await _vodPlayer.setRotation(angle);
  }

  /// 开启/关闭水平镜像
  Future<void> setMirrorHorizontal(bool mirror) async {
    await _vodPlayer.setMirrorHorizontal(mirror);
  }

  /// 开启/关闭垂直镜像
  Future<void> setMirrorVertical(bool mirror) async {
    await _vodPlayer.setMirrorVertical(mirror);
  }

  /// 设置是否循环播放
  Future<void> setLooping(bool looping) async {
    await _vodPlayer.setLooping(looping);
    value = value.copyWith(isLooping: looping);
  }

  /// 设置播放速度
  ///
  /// 默认为[_defaultPlaybackSpeed]
  Future<void> setPlaybackSpeed({double? speed, bool hasTimer = false}) async {
    speed ??= _defaultPlaybackSpeed;

    /// 限制倍速范围
    if (speed <= 0 || speed > maxPlaybackSpeed) return;

    /// 当 `_playbackSpeedTimer` 存在，且处于活跃状态时，注销计时器
    if (_playbackSpeedTimer != null && _playbackSpeedTimer!.isActive) {
      _cancelPlaybackSpeedTimer();
    }

    if (hasTimer) {
      _playbackSpeedTimer = Timer.periodic(Durations.extralong4 * 2, (_) async {
        _closePlaybackSpeed();
      });
    } else {
      /// 记录默认播放速度
      if (speed == maxPlaybackSpeed) {
        _defaultPlaybackSpeed = value.playbackSpeed;
      } else {
        _defaultPlaybackSpeed = 1.0;
      }
    }

    await _vodPlayer.setPlaybackSpeed(speed);
    value = value.copyWith(
      playbackSpeed: speed,
      isPlaybackSpeed: hasTimer,
      isMaxPlaybackSpeed: !hasTimer && speed == maxPlaybackSpeed,
    );
  }

  /// 关闭播放速度展示
  void _closePlaybackSpeed() {
    value = value.copyWith(isPlaybackSpeed: false);
    _cancelPlaybackSpeedTimer();
  }

  /// 设置最大播放速度
  void setMaxPlaybackSpeed() => setPlaybackSpeed(speed: maxPlaybackSpeed);

  /// 静音播放
  Future<void> setMuted(bool muted) async {
    await _vodPlayer.setMuted(muted);
  }

  /// 获取当前音量，默认使用左声道
  Future<double> get volume async {
    final TTVolume? volume = await _vodPlayer.getVolume();
    return volume?.left ?? 0;
  }

  /// 设置播放音量
  Future<void> setVolume(double volume) async {
    volume = clampDouble(volume, 0, 1);
    await _vodPlayer.setVolume(volume: TTVolume(left: volume, right: volume));
  }

  /// 设置纯音频播放
  /// 仅高级版或企业版支持
  Future<void> setRadioMode(bool radioMode) async {
    await _vodPlayer.setRadioMode(radioMode);
  }

  /// 获取当前屏幕亮度
  Future<double> get brightness => _brightness.current;

  /// 设置屏幕亮度
  Future<void> setBrightness(double brightness) async {
    await _brightness.setScreenBrightness(clampDouble(brightness, 0, 1));
  }

  /// 重置屏幕亮度
  Future<void> _resetScreenBrightness() => _brightness.resetScreenBrightness();

  /// 设置是否正在调整显示亮度或音量
  void _setDragVertical(
    bool isDragVertical, {
    DragVerticalType? type,
    double? currentValue,
  }) {
    if (value.isPlaybackSpeed) _closePlaybackSpeed();

    value = value.copyWith(
      isDragVertical: isDragVertical,
      clearDragVerticalType: !isDragVertical,
      dragVerticalType: type,
      dragVerticalValue: currentValue ?? 0,
    );
  }

  /// 设置当前值（亮度或音量）
  void _setDragVerticalValue(double dragVerticalValue) {
    value = value.copyWith(dragVerticalValue: dragVerticalValue);
  }

  /// 设置是否正在调整播放进度
  void _setDragProgress(bool isDragProgress) {
    if (value.isPlaybackSpeed) _closePlaybackSpeed();

    value = value.copyWith(
      isDragProgress: isDragProgress,
      dragDuration: isDragProgress
          ? value.dragDuration == Duration.zero
              ? value.position
              : value.dragDuration
          : null,
    );
  }

  /// 设置调整的播放进度
  void _setDragDuration(Duration duration) {
    if (duration < Duration.zero) {
      duration = Duration.zero;
    } else if (duration > value.duration) {
      duration = value.duration;
    }
    value = value.copyWith(dragDuration: duration);
  }

  /// 切换 全屏模式
  bool toggleFullScreen({bool? isFullScreen}) {
    if (!value.isInitialized) return false;

    value = value.copyWith(isFullScreen: isFullScreen ?? !value.isFullScreen);
    _fullScreenStream.add(value.isFullScreen);
    return true;
  }

  /// 屏幕旋转
  Future<void> _toggleOrientations() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    if (value.isFullScreen) {
      /// 进入全屏模式
      await SystemChrome.setPreferredOrientations(orientations);
    } else {
      /// 退出全屏模式
      await SystemChrome.setPreferredOrientations(
        config.orientationsExitFullScreen,
      );
    }
  }

  /// 初始全屏转换监听
  void _fullScreenListener() {
    if (value.isPlaying && !value.isFullScreen) {
      toggleFullScreen(isFullScreen: true);
      removeListener(_fullScreenListener);
    }
  }

  /// 全屏后的设备方向
  List<DeviceOrientation> get orientations {
    if (config.orientationsEnterFullScreen != null) {
      return config.orientationsEnterFullScreen!;
    }
    return value.orientations;
  }

  /// 切换 锁定状态
  void _toggleLock() {
    if (!value.isInitialized) return;

    value = value.copyWith(isLock: !value.isLock);
  }

  /// 获取播放时长
  ///
  /// 仅在 [VodPlayerFlutter.onPrepared] 回调中调用一次即可
  Future<void> _getDuration() async {
    final Duration duration = await _vodPlayer.duration;
    value = value.copyWith(duration: duration);
  }

  /// 获取播放进度/已缓冲的播放进度
  Future<void> _getPosition() async {
    final Duration position = await _vodPlayer.position;
    final Duration buffered = await _vodPlayer.playableDuration;
    value = value.copyWith(position: position, buffered: buffered);

    /// 进度监听
    config.onChanged?.call(value);
  }

  /// 获取视频尺寸
  Future<void> _getVideoSize() async {
    final int width = await _vodPlayer.videoWidth;
    final int height = await _vodPlayer.videoHeight;
    value = value.copyWith(size: Size(width.toDouble(), height.toDouble()));
  }

  /// 获取当前清晰度
  Future<void> _getResolution() async {
    final TTVideoEngineResolutionType resolution =
        await _vodPlayer.currentResolution;
    value = value.copyWith(resolution: resolution);
  }

  /// 获取清晰度列表
  Future<void> _getResolutions() async {
    final List<TTVideoEngineResolutionType> resolutions =
        await _vodPlayer.supportedResolutionTypes;
    value = value.copyWith(resolutions: resolutions);
  }

  /// 试看判断
  Future<void> _getMaxPreviewTimeState() async {
    final Duration? maxPreviewTime = config.maxPreviewTime;
    if (maxPreviewTime == null) return;

    final Duration position = value.position;
    if (position >= maxPreviewTime && !value.isMaxPreviewTime) {
      value = value.copyWith(isMaxPreviewTime: true);
      _reset();
      await pause();
      await seekTo(maxPreviewTime);
    } else if (position < maxPreviewTime && value.isMaxPreviewTime) {
      value = value.copyWith(isMaxPreviewTime: false);
      await play();
    }
  }

  /// 播放完成 or 播放失败 后，重置
  void _reset() {
    value = value.copyWith(
      isLock: false,
      isMaxPlaybackSpeed: false,
      isDragProgress: false,
      dragDuration: Duration.zero,
    );
  }

  /// 播放状态回调
  void _listener() {
    _vodPlayer
      ..onPrepared = () {
        /// 获取播放时长
        _getDuration();

        /// 获取视频尺寸
        _getVideoSize();

        /// 获取清晰度
        _getResolution();

        /// 完成初始化，即将开始播放。
        value = value.copyWith(
          isInitialized: true,
          clearError: true,
          isCompleted: false,
        );

        /// 若仅开启自动初始化并且未开启自动播放，则暂停播放
        /// 否则无须暂停
        if (config.autoInitialize && !config.autoPlay && _isFirstInit) pause();
        _isFirstInit = false;
      }
      ..readyToDisplay = () {
        /// 首帧渲染完成回调
        value = value.copyWith(isReadyToDisplay: true);
      }
      ..playbackStateDidChanged = (TTVideoEnginePlaybackState state) {
        /// 播放状态变化
        value = value.copyWith(
          isPlaying: state == TTVideoEnginePlaybackState.playing,
        );

        if (state == TTVideoEnginePlaybackState.stopped) {
          /// 播放停止
        } else if (state == TTVideoEnginePlaybackState.playing) {
          /// 开始播放
        } else if (state == TTVideoEnginePlaybackState.paused) {
          /// 播放暂停
        } else if (state == TTVideoEnginePlaybackState.error) {
          /// 播放错误
        }
      }
      ..loadStateDidChanged = (
        TTVideoEngineLoadState state,
        Map<Object?, Object?>? extra,
      ) {
        /// 加载状态变化
        if (state == TTVideoEngineLoadState.playable) {
          /// 缓冲结束
          /// 如果是缓冲中，则将缓冲状态设置为false
          if (value.isBuffering) value = value.copyWith(isBuffering: false);
        } else if (state == TTVideoEngineLoadState.stalled) {
          /// 缓冲中
          _closePlaybackSpeed();
          value = value.copyWith(isBuffering: true);
        } else if (state == TTVideoEngineLoadState.error) {
          /// 加载错误
        }
      }
      ..fetchedVideoModel = _getResolutions
      ..resolutionConfigCompletion = (
        bool flag,
        TTVideoEngineResolutionType completeResolution,
      ) {
        /// 切换清晰度成功
        if (flag) value = value.copyWith(resolution: completeResolution);
      }
      ..didFinish = (TTError? error) {
        if (error != null) {
          value = value.copyWith(error: error);
        } else {
          if (!value.isLooping) value = value.copyWith(isCompleted: true);
        }

        /// 重置
        _reset();
      };

    /// 当 `_timer` 存在，且处于活跃状态时，注销计时器
    if (_timer != null && _timer!.isActive) _cancelTimer();

    _timer = Timer.periodic(Durations.long2, (Timer timer) async {
      if (!timer.isActive) return;

      /// 获取播放进度/已缓冲的播放进度
      await _getPosition();

      /// 试看判断
      await _getMaxPreviewTimeState();
    });
  }

  /// 注销[_timer]
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// 注销[_playbackSpeedTimer]
  void _cancelPlaybackSpeedTimer() {
    _playbackSpeedTimer?.cancel();
    _playbackSpeedTimer = null;
  }

  /// 最大播放速度
  double get maxPlaybackSpeed => 3;

  /// 播放速度档位
  List<double> get playbackSpeeds => <double>[.5, 1, 1.5, 2, 3];

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    /// 释放播放器
    _vodPlayer.closeAsync();

    /// 注销计时器
    _cancelTimer();
    _cancelPlaybackSpeedTimer();

    /// 释放监听器
    _fullScreenStream.close();

    /// 重置屏幕亮度
    _resetScreenBrightness();

    /// 是否关闭常亮模式
    if (!config.allowedScreenSleep) WakelockPlus.disable();

    super.dispose();
  }
}

/// [VeVodPlayerController] 播放数据
@immutable
class VeVodPlayerValue {
  const VeVodPlayerValue({
    required this.duration,
    this.size = Size.zero,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.isInitialized = false,
    this.isReadyToDisplay = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isLooping = false,
    this.isLock = false,
    this.isFullScreen = false,
    this.isMaxPreviewTime = false,
    this.playbackSpeed = 1.0,
    this.isPlaybackSpeed = false,
    this.isMaxPlaybackSpeed = false,
    this.resolution =
        TTVideoEngineResolutionType.TTVideoEngineResolutionTypeABRAuto,
    this.resolutions = const <TTVideoEngineResolutionType>[],
    this.isDragVertical = false,
    this.dragVerticalType,
    this.dragVerticalValue = 0,
    this.isDragProgress = false,
    this.dragDuration = Duration.zero,
    this.error,
    this.isCompleted = false,
  });

  /// 返回尚未加载的实例
  const VeVodPlayerValue.uninitialized() : this(duration: Duration.zero);

  /// 总时长
  ///
  /// 如果尚未初始化，持续时间为[Duration.zero]
  final Duration duration;

  /// 尺寸
  ///
  /// 如果尚未初始化，尺寸为[Size.zero]
  final Size size;

  /// 当前播放位置
  final Duration position;

  /// 缓冲时长
  final Duration buffered;

  /// 是否已加载并准备播放。
  final bool isInitialized;

  /// 首帧渲染是否完成
  final bool isReadyToDisplay;

  /// 是否正在播放
  ///
  /// 如果为播放状态，则为true
  /// 如果为暂停状态，则为false
  final bool isPlaying;

  /// 是否正在缓冲
  final bool isBuffering;

  /// 是否循环播放
  final bool isLooping;

  /// 是否锁定[VeVodPlayerControls]
  final bool isLock;

  /// 是否是全屏模式
  final bool isFullScreen;

  /// 是否超过试看时间
  final bool isMaxPreviewTime;

  /// 当前播放速度
  final double playbackSpeed;

  /// 是否显示当前播放速度
  final bool isPlaybackSpeed;

  /// 是否以最大速率播放视频
  final bool isMaxPlaybackSpeed;

  /// 当前清晰度
  final TTVideoEngineResolutionType resolution;

  /// 清晰度列表
  final List<TTVideoEngineResolutionType> resolutions;

  /// 是否正在调整显示亮度或音量
  final bool isDragVertical;

  /// 调节音量或屏幕亮度
  final DragVerticalType? dragVerticalType;

  /// 亮度或音量
  final double dragVerticalValue;

  /// 是否正在调整播放进度
  final bool isDragProgress;

  /// 调整后的播放进度
  final Duration dragDuration;

  /// 如果存在，则为错误描述
  final TTError? error;

  /// 是否播放完毕
  ///
  /// 如果发生变化或开始播放，则恢复为false
  /// 如果正在循环，则不会更新
  final bool isCompleted;

  /// 提示是否处于错误状态
  /// 如果为true，则[error]包含问题信息
  bool get hasError => error != null;

  /// Device orientation after full screen.
  List<DeviceOrientation> get orientations {
    if (size.width > size.height) {
      return <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    } else if (size.width < size.height) {
      return <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ];
    } else {
      return DeviceOrientation.values;
    }
  }

  /// 可调节的时间间隔
  Duration get dragTotalDuration {
    if (duration < const Duration(minutes: 1)) {
      return const Duration(seconds: 10);
    } else if (duration < const Duration(minutes: 10)) {
      return const Duration(minutes: 1);
    } else if (duration < const Duration(minutes: 30)) {
      return const Duration(minutes: 5);
    } else if (duration < const Duration(hours: 1)) {
      return const Duration(minutes: 10);
    } else {
      return const Duration(minutes: 15);
    }
  }

  /// 播放“完成” - 播放完成、存在异常、试看时间已过
  bool get allowControls => isCompleted || isMaxPreviewTime;

  /// 是否展示控制器 - 顶部
  bool get allowControlsTop => !isLock && !isDragProgress;

  /// 是否展示控制器 - 底部
  bool get allowControlsBottom => !isLock && !isCompleted && !isMaxPreviewTime;

  /// 返回与当前实例具有相同值新实例，但作为参数传递给[copyWith]，任何重写除外
  VeVodPlayerValue copyWith({
    Duration? duration,
    Size? size,
    Duration? position,
    Duration? buffered,
    bool? isInitialized,
    bool? isReadyToDisplay,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLooping,
    bool? isLock,
    bool? isFullScreen,
    bool? isMaxPreviewTime,
    double? playbackSpeed,
    bool? isPlaybackSpeed,
    bool? isMaxPlaybackSpeed,
    TTVideoEngineResolutionType? resolution,
    List<TTVideoEngineResolutionType>? resolutions,
    bool? isDragVertical,
    bool clearDragVerticalType = false,
    DragVerticalType? dragVerticalType,
    double? dragVerticalValue,
    bool? isDragProgress,
    Duration? dragDuration,
    bool clearError = false,
    TTError? error,
    bool? isCompleted,
  }) {
    return VeVodPlayerValue(
      duration: duration ?? this.duration,
      size: size ?? this.size,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      isInitialized: isInitialized ?? this.isInitialized,
      isReadyToDisplay: isReadyToDisplay ?? this.isReadyToDisplay,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLooping: isLooping ?? this.isLooping,
      isLock: isLock ?? this.isLock,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isMaxPreviewTime: isMaxPreviewTime ?? this.isMaxPreviewTime,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isPlaybackSpeed: isPlaybackSpeed ?? this.isPlaybackSpeed,
      isMaxPlaybackSpeed: isMaxPlaybackSpeed ?? this.isMaxPlaybackSpeed,
      resolution: resolution ?? this.resolution,
      resolutions: resolutions ?? this.resolutions,
      isDragVertical: isDragVertical ?? this.isDragVertical,
      dragVerticalType: clearDragVerticalType
          ? null
          : dragVerticalType ?? this.dragVerticalType,
      dragVerticalValue: dragVerticalValue ?? this.dragVerticalValue,
      isDragProgress: isDragProgress ?? this.isDragProgress,
      dragDuration: dragDuration ?? this.dragDuration,
      error: clearError ? null : error ?? this.error,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return '${objectRuntimeType(this, 'VodPlayerValue')}('
        'hashCode: $hashCode, '
        'duration: $duration, '
        'size: $size, '
        'position: $position, '
        'buffered: $buffered, '
        'isInitialized: $isInitialized, '
        'isReadyToDisplay: $isReadyToDisplay, '
        'isPlaying: $isPlaying, '
        'isBuffering: $isBuffering, '
        'isLock: $isLock, '
        'isLooping: $isLooping, '
        'isFullScreen: $isFullScreen, '
        'isMaxPreviewTime: $isMaxPreviewTime, '
        'playbackSpeed: $playbackSpeed, '
        'isPlaybackSpeed: $isPlaybackSpeed, '
        'isMaxPlaybackSpeed: $isMaxPlaybackSpeed, '
        'resolution: $resolution, '
        'resolutions: $resolutions, '
        'isDragVertical: $isDragVertical, '
        'dragVerticalType: $dragVerticalType, '
        'dragVerticalValue: $dragVerticalValue, '
        'isDragProgress: $isDragProgress, '
        'dragDuration: $dragDuration, '
        'error: $error, '
        'isCompleted: $isCompleted'
        ')';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VeVodPlayerValue &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          size == other.size &&
          position == other.position &&
          buffered == other.buffered &&
          isInitialized == other.isInitialized &&
          isReadyToDisplay == other.isReadyToDisplay &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          isLock == other.isLock &&
          isLooping == other.isLooping &&
          isFullScreen == other.isFullScreen &&
          isMaxPreviewTime == other.isMaxPreviewTime &&
          playbackSpeed == other.playbackSpeed &&
          isPlaybackSpeed == other.isPlaybackSpeed &&
          isMaxPlaybackSpeed == other.isMaxPlaybackSpeed &&
          resolution == other.resolution &&
          resolutions == other.resolutions &&
          isDragVertical == other.isDragVertical &&
          dragVerticalType == other.dragVerticalType &&
          dragVerticalValue == other.dragVerticalValue &&
          isDragProgress == other.isDragProgress &&
          dragDuration == other.dragDuration &&
          error == other.error &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        size,
        Object.hash(duration, position, buffered),
        isInitialized,
        isReadyToDisplay,
        isPlaying,
        isBuffering,
        isLock,
        isLooping,
        isFullScreen,
        isMaxPreviewTime,
        Object.hash(playbackSpeed, isPlaybackSpeed, isMaxPlaybackSpeed),
        Object.hash(resolution, resolutions),
        Object.hash(isDragVertical, dragVerticalType, dragVerticalValue),
        Object.hash(isDragProgress, dragDuration),
        error,
        isCompleted,
      );
}

/// 用于传递[VeVodPlayer]的小部件。
class VeVodPlayerInherited extends InheritedWidget {
  const VeVodPlayerInherited({
    super.key,
    required this.controller,
    required super.child,
  });

  /// 播放控制器
  final VeVodPlayerController controller;

  @override
  bool updateShouldNotify(covariant VeVodPlayerInherited oldWidget) =>
      controller != oldWidget.controller;
}

/// 安全区域
class VeVodPlayerSafeArea extends StatefulWidget {
  const VeVodPlayerSafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
    required this.child,
  });

  /// Whether to avoid system intrusions on the left.
  final bool left;

  /// Whether to avoid system intrusions at the top of the screen, typically the
  /// system status bar.
  final bool top;

  /// Whether to avoid system intrusions on the right.
  final bool right;

  /// Whether to avoid system intrusions on the bottom side of the screen.
  final bool bottom;

  /// This minimum padding to apply.
  ///
  /// The greater of the minimum insets and the media padding will be applied.
  final EdgeInsets minimum;

  /// Specifies whether the [SafeArea] should maintain the bottom
  /// [MediaQueryData.viewPadding] instead of the bottom
  /// [MediaQueryData.padding],
  /// defaults to false.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// SafeArea, the padding can be maintained below the obstruction rather than
  /// being consumed. This can be helpful in cases where your layout contains
  /// flexible widgets, which could visibly move when opening a software
  /// keyboard due to the change in the padding value. Setting this to true will
  /// avoid the UI shift.
  final bool maintainBottomViewPadding;

  /// 子组件
  final Widget child;

  @override
  State<VeVodPlayerSafeArea> createState() => _VeVodPlayerSafeAreaState();
}

class _VeVodPlayerSafeAreaState extends State<VeVodPlayerSafeArea> {
  /// 视图尺寸
  Size size = Size.zero;

  /// 距屏幕左上角的距离
  Offset topOffset = Offset.zero;

  /// 距屏幕左下角的距离
  Offset bottomOffset = Offset.zero;

  @override
  void initState() {
    _getData();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _getData();

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    /// 屏幕方向
    final Orientation orientation = MediaQuery.orientationOf(context);

    return SafeArea(
      left: widget.left,
      top: widget.top &&
          orientation == Orientation.portrait &&
          topOffset.dy <= 0,
      right: widget.right,
      bottom: widget.bottom &&
          orientation == Orientation.portrait &&
          bottomOffset.dy >= 0,
      minimum: widget.minimum,
      maintainBottomViewPadding: widget.maintainBottomViewPadding,
      child: widget.child,
    );
  }

  /// 获取屏幕相关数据
  void _getData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      /// 屏幕尺寸
      final Size screenSize = MediaQuery.sizeOf(context);

      setState(() {
        size = renderBox.size;
        topOffset = renderBox.localToGlobal(Offset.zero);
        bottomOffset = renderBox.localToGlobal(Offset(0, size.height)) -
            Offset(0, screenSize.height);
      });
    });
  }
}
