/// @Describe: 控制器
///
/// @Author: LiWeNHuI
/// @Date: 2025/4/22

part of 've_vod_player.dart';

/// {@template ve.vod.controls.VodPlayerController}
/// 播放控制器
///
/// 包含资源数据、配置文件
///
/// 实现 创建播放器、设置播放源 等基础功能，以及播放控制、设置自定义Header、设置填充模式、
/// 设置旋转角度、设置镜像模式、设置循环播放、设置倍速播放、静音、调节音量、设置业务类型、
/// 设置自定义标签、设置清晰度、播放私有加密视频、获取播放信息、播放状态回调、纯音频播放 功能
///
/// 后续支持高阶功能
/// 展示当前视频下载进度、短视频场景预加载和预渲染策略、自定义预加载等功能
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
        super(const VeVodPlayerValue.uninitialized());

  /// 播放源
  final TTVideoEngineMediaSource source;

  /// 视频播放器[VeVodPlayer]配置
  final VeVodPlayerConfig config;

  /// 视频播放控制器[VeVodPlayerControls]配置
  final VeVodPlayerControlsConfig controlsConfig;

  /// 播放源ID
  String? get uniqueId => source.getUniqueId;

  /// 创建 [VodPlayerFlutter] 实例
  late VodPlayerFlutter _vodPlayer;

  /// 屏幕亮度控制
  final ScreenBrightness _brightness = ScreenBrightness.instance;

  /// 是否为首次初始化
  bool _isFirstInit = true;

  /// 应用是否为挂起状态
  bool _isAppInBackground = false;

  /// 上下文
  BuildContext? _context;

  /// 本机视图类型，仅支持Android端
  NativeViewType _nativeViewType = NativeViewType.TextureView;

  /// 计时器
  Timer? _timer;

  /// 音量/亮度显示计时器
  Timer? _verticalTimer;

  /// 默认播放速度
  double _defaultPlaybackSpeed = 1;
  Timer? _playbackSpeedTimer;

  /// 是否为用户暂停操作
  bool _isPauseByUser = false;

  /// 监控全屏的状态变化
  final StreamController<bool> _fullScreenStream =
      StreamController<bool>.broadcast();

  bool _isDisposed = false;

  static VeVodPlayerController of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<VeVodPlayerInherited>()!
      .controller;

  /// 执行初始化[VodPlayerFlutter]操作
  Future<void> _initVodPlayer() async {
    /// 是否开启常亮模式
    if (!config.allowedScreenSleep) await WakelockPlus.enable();

    /// 创建播放器
    _vodPlayer = VodPlayerFlutter();
    await _vodPlayer.createPlayer();

    /// 设置监听
    _listener();

    /// 设置 HTTP Header
    await _setCustomHeader(config.httpHeaders);

    /// 设置[TTVideoPlayerView.nativeViewType]
    _nativeViewType = NativeViewType.TextureView;

    /// 设置播放源
    await _vodPlayer.setMediaSource(source);

    await Future.wait(<Future<void>>[
      /// 将起播位置设置为[config.startAt]
      _setStartTimeMs(config.startAt),

      /// 设置是否循环播放
      if (!Platform.isAndroid) setLooping(config.looping),

      /// 设置填充模式
      setScalingMode(),

      /// 设置业务类型
      if (config.tag != null) _vodPlayer.setTag(config.tag!),

      /// 设置自定义标签
      if (config.subTag != null) _vodPlayer.setSubTag(config.subTag!),

      /// 设置静音
      if (config.mutedAtStartUp) setMuted(true),
    ]);

    if (config.autoInitialize || config.autoPlay) {
      /// 开启播放
      /// 用于获取相关信息
      /// 若未开启自动播放，则在[_vodPlayer.onPrepared]方法内暂停播放
      await play();
    }

    /// 在启动时开启全屏播放
    if (config.fullScreenAtStartUp) addListener(_fullScreenListener);
  }

  /// 执行初始化[TTVideoPlayerView]操作
  /// 设置[viewId]
  Future<void> _init(int viewId, {BuildContext? context}) async {
    await _initVodPlayer();
    await _vodPlayer.setPlayerContainerView(viewId);

    /// 赋值上下文
    _context = context;
  }

  /// 播放
  Future<void> play() async {
    /// 当存在异常时，跳转到异常位置
    if (value.hasError) await _setStartTimeMs(value.position);

    await _vodPlayer.play();

    /// 创建计时器，且不需要创建新的计时器
    _createTimer(needCreateNew: false);
  }

  /// 暂停
  Future<void> pause() async {
    await _vodPlayer.pause();
  }

  /// 停止
  Future<void> stop() async {
    await _vodPlayer.stop();
  }

  /// 重播
  Future<void> replay() async {
    _setIsCompleted(false);
    await play();
  }

  /// 将起播位置设置为[moment]
  Future<void> _setStartTimeMs(Duration? moment) async {
    if (moment == null) return;

    if (value.isInitialized) {
      /// 获取时长后，如果设置的起始位置超过视频时长，则恢复到初始位置
      if (moment >= value.duration) moment = Duration.zero;
      await seekTo(moment);
    } else {
      await _vodPlayer.setStartTimeMs(moment.inMilliseconds.toDouble());
    }
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
    if (moment == null || !value.isInitialized) return;

    _closePlaybackSpeed();

    /// 开始缓冲
    value = value.copyWith(isBuffering: true);

    await _vodPlayer.seekToTimeMs(
      time: moment.inMilliseconds.toDouble(),
      seekCompleted: (bool isSeekCompleted) {
        onCompleted?.call(isSeekCompleted);

        /// 进度调节完成，如果缓冲成功则清理[value.dragDuration]
        value = value.copyWith(
          isBuffering: !isSeekCompleted,
          dragDuration: isSeekCompleted ? Duration.zero : null,
        );
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
    final Iterable<Future<void>> futures = map.entries.map(
      (MapEntry<String, String> entry) {
        return _vodPlayer.setCustomHeader(entry.key, entry.value);
      },
    );
    await Future.wait(futures);
  }

  /// 设置填充模式
  /// TTVideoEngineScalingModeNone: 无拉伸，不会有变形，可能有黑边
  /// TTVideoEngineScalingModeAspectFit: 等比例适配，不会有变形，按照视频宽高等比适配画面，可能有黑边
  /// TTVideoEngineScalingModeAspectFill: 等比例填充，不会有变形，按照视频宽高等比充满画面，可能有画面裁切
  /// TTVideoEngineScalingModeFill: 拉伸填充，视频宽高比例与画面比例不一致，会导致画面变形
  Future<void> setScalingMode({TTVideoEngineScalingMode? mode}) async {
    mode ??= TTVideoEngineScalingMode.TTVideoEngineScalingModeAspectFit;
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
      _playbackSpeedTimer = Timer.periodic(
        Durations.extralong4 * 2,
        (Timer timer) {
          final bool flag = _handlePlaybackSpeedTimer(timer);
          if (flag) return;

          _closePlaybackSpeed();
        },
      );
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
    value = value.copyWith(isMuted: muted);
    await _vodPlayer.setMuted(muted);
  }

  /// 数字处理
  double _getNumValue(double value) {
    return double.tryParse(value.toStringAsFixed(5)) ?? 0;
  }

  /// 获取当前音量，默认使用左声道
  Future<double> get volume async {
    final TTVolume? volume = await _vodPlayer.getVolume();
    return _getNumValue(volume?.left ?? 0);
  }

  /// 设置播放音量
  Future<void> setVolume(double volume) async {
    volume = ui.clampDouble(volume, 0, 1);
    await _vodPlayer.setVolume(volume: TTVolume(left: volume, right: volume));
  }

  /// 系统音量变化监听
  void _addVolumeListener() {
    VeVodVolumeFactory.instance.addListener(
      key: hashCode,
      onData: (double volume) {
        final BuildContext? context = _context;
        final bool isCurrent =
            context != null && (ModalRoute.of(context)?.isCurrent ?? false);
        if (!isCurrent) {
          return;
        }

        if (_isAppInBackground) {
          _isAppInBackground = false;
          return;
        }

        volume = _getNumValue(volume);
        if (value.isMuted) setMuted(false);

        if (!value._isDragVerticalWithGesture) {
          if (value._isDragVertical &&
              value._dragVerticalType == DragVerticalType.volume) {
            _setDragVerticalValue(volume);
          } else if (!value._isDragVertical) {
            _setDragVertical(
              true,
              isDragVerticalWithGesture: false,
              type: DragVerticalType.volume,
              currentValue: volume,
            );
          }

          _closeDragVertical();
        }
      },
      fetchInitialVolume: _isAppInBackground,
    );
  }

  /// 设置纯音频播放
  /// 仅高级版或企业版支持
  Future<void> setRadioMode(bool radioMode) async {
    await _vodPlayer.setRadioMode(radioMode);
  }

  /// 获取当前屏幕亮度
  Future<double> get brightness async {
    if (Platform.isAndroid && !(await _brightness.canChangeSystemBrightness)) {
      return _brightness.application;
    }
    return _brightness.system;
  }

  /// 设置屏幕亮度
  Future<void> setBrightness(double brightness) async {
    brightness = ui.clampDouble(brightness, 0, 1);
    if (Platform.isAndroid && !(await _brightness.canChangeSystemBrightness)) {
      await _brightness.setApplicationScreenBrightness(brightness);
    } else {
      await _brightness.setSystemScreenBrightness(brightness);
    }
  }

  /// 重置屏幕亮度
  Future<void> _resetScreenBrightness() async {
    if (Platform.isAndroid && !(await _brightness.canChangeSystemBrightness)) {
      await _brightness.resetApplicationScreenBrightness();
    }
  }

  /// 设置是否正在调整显示亮度或音量
  void _setDragVertical(
    bool isDragVertical, {
    bool isDragVerticalWithGesture = true,
    DragVerticalType? type,
    double? currentValue,
  }) {
    if (value.isPlaybackSpeed) _closePlaybackSpeed();

    value = value._copyWith(
      isDragVertical: isDragVertical,
      isDragVerticalWithGesture: isDragVerticalWithGesture,
      clearDragVerticalType: !isDragVertical,
      dragVerticalType: type,
      dragVerticalValue: currentValue ?? 0,
    );
  }

  /// 设置当前值（亮度或音量）
  void _setDragVerticalValue(double value) {
    this.value = this.value._copyWith(dragVerticalValue: value);
  }

  /// 关闭调整显示亮度或音量
  void _closeDragVertical({Duration duration = Durations.extralong4}) {
    /// 注销计时器
    _cancelVerticalTimer();

    _verticalTimer = Timer.periodic(duration, (Timer timer) {
      final bool flag = _handleVerticalTimer(timer);
      if (flag) return;

      _setDragVertical(false, isDragVerticalWithGesture: false);
    });
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
    final Duration? maxPreviewTime = config.maxPreviewTime;

    if (maxPreviewTime != null && duration > maxPreviewTime) {
      duration = maxPreviewTime;
    } else if (duration < Duration.zero) {
      duration = Duration.zero;
    } else if (duration > value.duration) {
      duration = value.duration;
    }
    value = value.copyWith(dragDuration: duration);
  }

  /// 设置点击的播放进度
  void _setTapDuration(Duration duration) {
    final Duration? maxPreviewTime = config.maxPreviewTime;
    if (maxPreviewTime != null && duration > maxPreviewTime) {
      duration = maxPreviewTime;
    }
    seekTo(duration);
  }

  /// 切换 全屏模式
  bool toggleFullScreen({bool? isFullScreen}) {
    if (!value.isInitialized) return false;

    value = value.copyWith(isFullScreen: isFullScreen ?? !value.isFullScreen);
    if (value.isFullScreen) {
      config.onFullScreenChanged?.call(value.isFullScreen);
      Future<void>.delayed(Durations.short1, _toggleOrientations);
    } else {
      _toggleOrientations();
      Future<void>.delayed(Durations.short4, () {
        config.onFullScreenChanged?.call(value.isFullScreen);
      });
    }
    _fullScreenStream.add(value.isFullScreen);
    return true;
  }

  /// 屏幕旋转
  Future<void> _toggleOrientations() async {
    /// 重置系统 UI 模式
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);

    /// 设置系统 UI 模式
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: value.isFullScreen
          ? <SystemUiOverlay>[]
          : config.systemOverlaysExitFullScreen,
    );

    /// 设置设备方向
    await SystemChrome.setPreferredOrientations(orientations);
  }

  /// 初始全屏转换监听
  void _fullScreenListener() {
    if (value.isPlaying && !value.isFullScreen) {
      toggleFullScreen(isFullScreen: true);
      removeListener(_fullScreenListener);
    }
  }

  /// 全屏转换的设备方向
  List<DeviceOrientation> get orientations {
    if (value.isFullScreen) {
      if (config.orientationsEnterFullScreen != null) {
        return config.orientationsEnterFullScreen!;
      }
      return value._orientations;
    } else {
      return config.orientationsExitFullScreen;
    }
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

    /// 设置起播位置，用于修复起播位置超过播放时长引发的错误
    final Duration? startAt = config.startAt;
    if (startAt != null && startAt > duration) await _setStartTimeMs(startAt);
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
    if (position >= maxPreviewTime && !value.isExceedsPreviewTime) {
      if (config.resetOnMaxPreviewEnd && value.isFullScreen) {
        toggleFullScreen(isFullScreen: false);
      }

      value = value.copyWith(isExceedsPreviewTime: true);
      _reset();
      await pause();
      await seekTo(maxPreviewTime);
    } else if (position < maxPreviewTime && value.isExceedsPreviewTime) {
      value = value.copyWith(isExceedsPreviewTime: false);
      await play();
    }
  }

  /// 播放完成 or 播放失败 后，重置
  void _reset() {
    value = value.copyWith(
      isPlaying: false,
      isBuffering: false,
      isLock: false,
      isPlaybackSpeed: false,
      isMaxPlaybackSpeed: false,
      clearDrag: true,
      isDragProgress: false,
      dragDuration: Duration.zero,
    );
  }

  /// 设置播放完成的状态
  void _setIsCompleted(bool isCompleted) {
    value = value.copyWith(isCompleted: isCompleted);
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
        value = value.copyWith(clearError: true, isCompleted: false);

        /// 开启系统音量变化监听
        _addVolumeListener();

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
        bool success,
        TTVideoEngineResolutionType completeResolution,
      ) {
        /// 切换清晰度成功
        if (success) value = value.copyWith(resolution: completeResolution);
      }
      ..didFinish = (TTError? error) {
        if (error != null) {
          value = value.copyWith(error: error);

          /// 注销计时器
          _cancelTimer();
        } else if (Platform.isAndroid && config.looping) {
          play();
        } else if (!value.isLooping) {
          _setIsCompleted(true);
        }

        /// 重置
        _reset();
      };

    /// 创建计时器
    _createTimer();
  }

  /// 创建[_timer]
  void _createTimer({bool needCreateNew = true}) {
    /// 当 `_timer` 存在，且处于活跃状态时，注销计时器
    if ((_timer != null && _timer!.isActive) || needCreateNew) _cancelTimer();

    /// 如果计时器已存在，则无需生成新的计时器
    if (_timer != null) return;

    /// 生成新的计时器
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

  /// 处理[_verticalTimer]
  bool _handleVerticalTimer(Timer timer) {
    if (timer.isActive) {
      timer.cancel();
      _cancelVerticalTimer();
    } else {
      return true;
    }
    return false;
  }

  /// 注销[_verticalTimer]
  void _cancelVerticalTimer() {
    /// 当 `_verticalTimer` 存在，且处于活跃状态时，注销计时器
    if (_verticalTimer != null && _verticalTimer!.isActive) {
      _verticalTimer?.cancel();
      _verticalTimer = null;
    }
  }

  /// 处理[_playbackSpeedTimer]
  bool _handlePlaybackSpeedTimer(Timer timer) {
    if (timer.isActive) {
      timer.cancel();
      _cancelPlaybackSpeedTimer();
    } else {
      return true;
    }
    return false;
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
    _cancelVerticalTimer();
    _cancelPlaybackSpeedTimer();

    /// 释放监听器
    _fullScreenStream.close();

    /// 移除系统音量监听
    VeVodVolumeFactory.instance.removeListener(key: hashCode);

    /// 重置屏幕亮度
    _resetScreenBrightness();

    /// 是否关闭常亮模式
    if (!config.allowedScreenSleep) WakelockPlus.disable();

    super.dispose();
  }
}

class VeVodVolumeFactory {
  VeVodVolumeFactory._();

  static final VeVodVolumeFactory _instance = VeVodVolumeFactory._();

  static VeVodVolumeFactory get instance => _instance;

  int _listenerCount = 0;

  final Map<int, ValueChanged<double>> _listeners =
      <int, ValueChanged<double>>{};

  void addListener({
    required int key,
    required ValueChanged<double> onData,
    bool fetchInitialVolume = true,
  }) {
    /// 添加监听器
    if (!_listeners.containsKey(key)) {
      _listenerCount++;
      _listeners[key] = onData;
    } else {
      _listeners[key] = onData;
    }

    /// 创建监听器
    if (_listenerCount == 1) {
      VolumeController.instance.addListener(
        (double volume) {
          _listeners.forEach((int key, ValueChanged<double> listener) {
            listener(volume);
          });
        },
        fetchInitialVolume: fetchInitialVolume,
      );
    } else if (fetchInitialVolume) {
      VolumeController.instance.getVolume().then((double volume) {
        onData.call(volume);
      });
    }
  }

  void removeListener({int? key}) {
    _listenerCount--;

    /// 注销监听器
    if (_listenerCount <= 0) {
      VolumeController.instance.removeListener();
      _listeners.clear();
    } else {
      _listeners.remove(key);
    }
  }
}
