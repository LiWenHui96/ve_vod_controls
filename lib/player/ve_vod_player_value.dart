/// @Describe: [VeVodPlayerController] 播放数据
///
/// @Author: LiWeNHuI
/// @Date: 2025/4/25

part of 've_vod_player.dart';

class VeVodPlayerValue extends _VeVodPlayerValue {
  const VeVodPlayerValue({
    required super.duration,
    super.size,
    super.position,
    super.buffered,
    super.isReadyToDisplay,
    super.isPlaying,
    super.isBuffering,
    super.isLooping,
    super.isLock,
    super.isFullScreen,
    super.isExceedsPreviewTime,
    super.playbackSpeed = 1.0,
    super.isPlaybackSpeed,
    super.isMaxPlaybackSpeed,
    super.isMuted,
    super.resolution,
    super.resolutions,
    super.isDragVertical,
    super.isDragVerticalWithGesture,
    super.dragVerticalType,
    super.dragVerticalValue,
    super.isDragProgress,
    super.dragDuration,
    super.error,
    super.isCompleted,
  });

  /// 返回尚未加载的实例
  const VeVodPlayerValue.uninitialized() : this(duration: Duration.zero);

  /// 返回与当前实例具有相同值新实例，但作为参数传递给[copyWith]，任何重写除外
  VeVodPlayerValue copyWith({
    Duration? duration,
    Size? size,
    Duration? position,
    Duration? buffered,
    bool? isReadyToDisplay,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLooping,
    bool? isLock,
    bool? isFullScreen,
    bool? isExceedsPreviewTime,
    double? playbackSpeed,
    bool? isPlaybackSpeed,
    bool? isMaxPlaybackSpeed,
    bool? isMuted,
    TTVideoEngineResolutionType? resolution,
    List<TTVideoEngineResolutionType>? resolutions,
    bool clearDrag = false,
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
      isReadyToDisplay: isReadyToDisplay ?? this.isReadyToDisplay,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLooping: isLooping ?? this.isLooping,
      isLock: isLock ?? this.isLock,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isExceedsPreviewTime: isExceedsPreviewTime ?? this.isExceedsPreviewTime,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isPlaybackSpeed: isPlaybackSpeed ?? this.isPlaybackSpeed,
      isMaxPlaybackSpeed: isMaxPlaybackSpeed ?? this.isMaxPlaybackSpeed,
      isMuted: isMuted ?? this.isMuted,
      resolution: resolution ?? this.resolution,
      resolutions: resolutions ?? this.resolutions,
      isDragVertical: !clearDrag && _isDragVertical,
      isDragVerticalWithGesture: !clearDrag && _isDragVerticalWithGesture,
      dragVerticalType: _dragVerticalType,
      dragVerticalValue: _dragVerticalValue,
      isDragProgress: isDragProgress ?? this.isDragProgress,
      dragDuration: dragDuration ?? this.dragDuration,
      error: clearError ? null : error ?? this.error,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  /// 返回与当前实例具有相同值新实例，但作为参数传递给[copyWith]，任何重写除外
  VeVodPlayerValue _copyWith({
    bool? isDragVertical,
    bool? isDragVerticalWithGesture,
    bool clearDragVerticalType = false,
    DragVerticalType? dragVerticalType,
    double? dragVerticalValue,
  }) {
    return VeVodPlayerValue(
      duration: duration,
      size: size,
      position: position,
      buffered: buffered,
      isReadyToDisplay: isReadyToDisplay,
      isPlaying: isPlaying,
      isBuffering: isBuffering,
      isLooping: isLooping,
      isLock: isLock,
      isFullScreen: isFullScreen,
      isExceedsPreviewTime: isExceedsPreviewTime,
      playbackSpeed: playbackSpeed,
      isPlaybackSpeed: isPlaybackSpeed,
      isMaxPlaybackSpeed: isMaxPlaybackSpeed,
      isMuted: isMuted,
      resolution: resolution,
      resolutions: resolutions,
      isDragVertical: isDragVertical ?? _isDragVertical,
      isDragVerticalWithGesture:
          isDragVerticalWithGesture ?? _isDragVerticalWithGesture,
      dragVerticalType:
          clearDragVerticalType ? null : dragVerticalType ?? _dragVerticalType,
      dragVerticalValue: dragVerticalValue ?? _dragVerticalValue,
      isDragProgress: isDragProgress,
      dragDuration: dragDuration,
      error: error,
      isCompleted: isCompleted,
    );
  }
}

@immutable
class _VeVodPlayerValue {
  const _VeVodPlayerValue({
    required this.duration,
    this.size = Size.zero,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.isReadyToDisplay = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isLooping = false,
    this.isLock = false,
    this.isFullScreen = false,
    this.isExceedsPreviewTime = false,
    this.playbackSpeed = 1.0,
    this.isPlaybackSpeed = false,
    this.isMaxPlaybackSpeed = false,
    this.isMuted = false,
    this.resolution =
        TTVideoEngineResolutionType.TTVideoEngineResolutionTypeABRAuto,
    this.resolutions = const <TTVideoEngineResolutionType>[],
    bool isDragVertical = false,
    bool isDragVerticalWithGesture = false,
    DragVerticalType? dragVerticalType,
    double dragVerticalValue = 0,
    this.isDragProgress = false,
    this.dragDuration = Duration.zero,
    this.error,
    this.isCompleted = false,
  })  : _isDragVertical = isDragVertical,
        _isDragVerticalWithGesture = isDragVerticalWithGesture,
        _dragVerticalType = dragVerticalType,
        _dragVerticalValue = dragVerticalValue;

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
  final bool isExceedsPreviewTime;

  /// 当前播放速度
  final double playbackSpeed;

  /// 是否显示当前播放速度
  final bool isPlaybackSpeed;

  /// 是否以最大速率播放视频
  final bool isMaxPlaybackSpeed;

  /// 是否静音
  final bool isMuted;

  /// 当前清晰度
  final TTVideoEngineResolutionType resolution;

  /// 清晰度列表
  final List<TTVideoEngineResolutionType> resolutions;

  /// 是否正在调整显示亮度或音量
  final bool _isDragVertical;

  /// 是否为手势调整显示亮度或音量
  final bool _isDragVerticalWithGesture;

  /// 调节音量或屏幕亮度
  final DragVerticalType? _dragVerticalType;

  /// 亮度或音量
  final double _dragVerticalValue;

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

  /// 是否已加载并准备播放。
  bool get isInitialized => duration > Duration.zero;

  /// 提示是否处于错误状态
  /// 如果为true，则[error]包含问题信息
  bool get hasError => error != null;

  /// Device orientation after full screen.
  List<DeviceOrientation> get _orientations {
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
  Duration get _dragTotalDuration {
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

  /// 展示 “播放” 按钮
  bool get _hasPlayButton =>
      isReadyToDisplay &&
      !isCompleted &&
      !isPlaying &&
      !isBuffering &&
      !isExceedsPreviewTime &&
      !isPlaybackSpeed &&
      !_isDragVertical &&
      !isDragProgress;

  /// 播放“完成” - 播放完成、存在异常、试看时间已过
  bool get _allowControls => isCompleted || isExceedsPreviewTime;

  /// 是否展示控制器 - 顶部
  bool get _allowControlsTop => !isLock && !isDragProgress;

  /// 是否展示控制器 - 中部
  bool get _allowControlsCenter =>
      !isCompleted && !isDragProgress && isFullScreen;

  /// 是否展示控制器 - 底部
  bool get _allowControlsBottom =>
      !isLock && !isCompleted && !isExceedsPreviewTime;

  /// 是否可以执行操作
  bool get _allowPressed => isInitialized && !isLock && !isExceedsPreviewTime;

  /// 是否不可触发 长按 操作
  bool get _allowLongPress => _allowPressed && isPlaying && !isMaxPlaybackSpeed;

  /// 是否可以触发纵向滑动操作
  bool get _allowVerticalDrag =>
      _allowPressed &&
      !isCompleted &&
      (!_isDragVerticalWithGesture || !_isDragVertical);

  /// 是否可以触发横向滑动操作
  bool get _allowHorizontalDrag =>
      _allowPressed && !isCompleted && !isDragProgress;

  /// 是否可以点击进度条
  bool get _allowTapProgress => _allowPressed && !isBuffering && !isCompleted;

  @override
  String toString() {
    return '${objectRuntimeType(this, 'VodPlayerValue')}('
        'hashCode: $hashCode, '
        'duration: $duration, '
        'size: $size, '
        'position: $position, '
        'buffered: $buffered, '
        'isReadyToDisplay: $isReadyToDisplay, '
        'isPlaying: $isPlaying, '
        'isBuffering: $isBuffering, '
        'isLock: $isLock, '
        'isLooping: $isLooping, '
        'isFullScreen: $isFullScreen, '
        'isExceedsPreviewTime: $isExceedsPreviewTime, '
        'playbackSpeed: $playbackSpeed, '
        'isPlaybackSpeed: $isPlaybackSpeed, '
        'isMaxPlaybackSpeed: $isMaxPlaybackSpeed, '
        'isMuted: $isMuted, '
        'resolution: $resolution, '
        'resolutions: $resolutions, '
        'isDragVertical: $_isDragVertical, '
        'isDragVerticalWithGesture: $_isDragVerticalWithGesture, '
        'dragVerticalType: $_dragVerticalType, '
        'dragVerticalValue: $_dragVerticalValue, '
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
          isReadyToDisplay == other.isReadyToDisplay &&
          isPlaying == other.isPlaying &&
          isBuffering == other.isBuffering &&
          isLock == other.isLock &&
          isLooping == other.isLooping &&
          isFullScreen == other.isFullScreen &&
          isExceedsPreviewTime == other.isExceedsPreviewTime &&
          playbackSpeed == other.playbackSpeed &&
          isPlaybackSpeed == other.isPlaybackSpeed &&
          isMaxPlaybackSpeed == other.isMaxPlaybackSpeed &&
          isMuted == other.isMuted &&
          resolution == other.resolution &&
          resolutions == other.resolutions &&
          _isDragVertical == other._isDragVertical &&
          _isDragVerticalWithGesture == other._isDragVerticalWithGesture &&
          _dragVerticalType == other._dragVerticalType &&
          _dragVerticalValue == other._dragVerticalValue &&
          isDragProgress == other.isDragProgress &&
          dragDuration == other.dragDuration &&
          error == other.error &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => Object.hash(
        size,
        Object.hash(duration, position, buffered),
        isReadyToDisplay,
        isPlaying,
        isBuffering,
        isLock,
        isLooping,
        isFullScreen,
        isExceedsPreviewTime,
        Object.hash(playbackSpeed, isPlaybackSpeed, isMaxPlaybackSpeed),
        isMuted,
        Object.hash(resolution, resolutions),
        Object.hash(
          _isDragVertical,
          _isDragVerticalWithGesture,
          _dragVerticalType,
          _dragVerticalValue,
        ),
        Object.hash(isDragProgress, dragDuration),
        error,
        isCompleted,
      );
}
