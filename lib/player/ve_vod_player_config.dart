/// @Describe: 视频播放配置
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/15

part of 've_vod_player.dart';

/// 依据[value]显示不同的小部件
typedef VeVodPlayerBuilder<T> = T Function(
  BuildContext context,
  VeVodPlayerController controller,
  VeVodPlayerValue value,
);

/// 中间的小部件。
typedef VeVodPlayerActionsBuilder = List<Widget>? Function(
  BuildContext context,
  VeVodPlayerController controller,
  VeVodPlayerValue value,
  Widget lockButton,
);

/// 视频播放器[VeVodPlayer]配置
class VeVodPlayerConfig {
  VeVodPlayerConfig({
    this.width,
    this.height,
    this.backgroundColor = Colors.black,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.panEnabled = false,
    this.scaleEnabled = false,
    this.allowedScreenSleep = true,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.startAt,
    this.maxPreviewTime,
    this.resetOnMaxPreviewEnd = true,
    this.looping = false,
    this.onOverlayBuilder,
    this.onPlaceholderBuilder,
    this.fullScreenAtStartUp = false,
    this.orientationsEnterFullScreen,
    this.systemOverlaysExitFullScreen = SystemUiOverlay.values,
    this.orientationsExitFullScreen = DeviceOrientation.values,
    this.hasControls = true,
    this.tag,
    this.subTag,
    this.httpHeaders,
    this.onChanged,
    this.onFullScreenChanged,
  });

  /// 控件最大宽度
  final double? width;

  /// 控件最大高度
  final double? height;

  /// 背景色，默认为[Colors.black]
  final Color backgroundColor;

  /// 允许缩放的最大比例，默认为2.5
  final double maxScale;

  /// 允许缩放的最小比例，默认为0.8
  final double minScale;

  /// 是否允许平移，默认为false
  final bool panEnabled;

  /// 是否允许缩放，默认为false
  final bool scaleEnabled;

  /// 屏幕是否会睡眠，默认为true
  final bool allowedScreenSleep;

  /// 是否在启动时初始化视频，这将为播放的视频做准备，默认为false
  final bool autoInitialize;

  /// 是否在启动时初始化完成后播放视频，默认为false
  final bool autoPlay;

  /// 视频首次播放时从哪里开始播放，默认为起始位置
  final Duration? startAt;

  /// 试看时长
  /// 如果设置的持续时间超过视频的最大持续时间，则视为可以观看整个视频。
  final Duration? maxPreviewTime;

  /// 达到试看时长后，是否恢复初始状态
  final bool resetOnMaxPreviewEnd;

  /// 是否循环播放，默认为false
  final bool looping;

  /// 放置在视频和控制器之间的小部件
  final VeVodPlayerBuilder<List<Widget>?>? onOverlayBuilder;

  /// 放置在控制器之上的小部件
  final VeVodPlayerBuilder<List<Widget>?>? onPlaceholderBuilder;

  /// 是否在启动时开启全屏播放，默认为false
  final bool fullScreenAtStartUp;

  /// 定义进入全屏时允许的设备方向
  final List<DeviceOrientation>? orientationsEnterFullScreen;

  /// 定义退出全屏后可见的系统显示
  final List<SystemUiOverlay> systemOverlaysExitFullScreen;

  /// 定义退出全屏后允许的设备方向
  final List<DeviceOrientation> orientationsExitFullScreen;

  /// 是否显示控制组件，默认为true
  final bool hasControls;

  /// 业务类型
  /// https://www.volcengine.com/docs/4/1264702#%E8%AE%BE%E7%BD%AE%E4%B8%9A%E5%8A%A1%E7%B1%BB%E5%9E%8B
  final String? tag;

  /// 自定义标签
  /// https://www.volcengine.com/docs/4/1264702#%E8%AE%BE%E7%BD%AE%E8%87%AA%E5%AE%9A%E4%B9%89%E6%A0%87%E7%AD%BE
  final String? subTag;

  /// 自定义 Http Header
  final Map<String, String>? httpHeaders;

  /// 进度监听
  final ValueChanged<VeVodPlayerValue>? onChanged;

  /// 是否开启/关闭全屏模式
  /// 用于开发者自行实现隐藏组件时
  final ValueChanged<bool>? onFullScreenChanged;

  Size? get size {
    if (width != null && height != null) return Size(width!, height!);
    if (width != null) return Size.fromWidth(width!);
    if (height != null) return Size.fromHeight(height!);
    return null;
  }
}

/// 视频播放控制器[VeVodPlayerControls]配置
class VeVodPlayerControlsConfig {
  VeVodPlayerControlsConfig({
    this.showAtStartUp = false,
    this.hideDuration = kDefaultHideDuration,
    this.backgroundColor = const <Color>[
      Color.fromRGBO(0, 0, 0, .8),
      Color.fromRGBO(0, 0, 0, .4),
      Color.fromRGBO(0, 0, 0, 0),
    ],
    this.toolTipBackgroundColor = const Color(0xB3000000),
    this.foregroundColor = Colors.white,
    this.textSize = 14,
    this.textStyle,
    this.iconSize = 20,
    this.hasBackButton = true,
    this.backButton,
    this.title,
    this.titleTextStyle,
    this.onActionsBuilder,
    this.onCenterLeftActionsBuilder,
    this.onCenterRightActionsBuilder,
    this.onPauseBuilder,
    this.allowLongPress = true,
    this.allowVolumeOrBrightness = true,
    this.allowProgress = true,
    this.allowLock = true,
    this.progressColors,
    this.onMaxPreviewTimeBuilder,
  });

  /// 首次启动时是否显示控制组件，默认为false
  final bool showAtStartUp;

  /// 在隐藏[VeVodPlayerControls]之前定义[Duration]，默认为[kDefaultHideDuration]
  final Duration hideDuration;

  /// 背景颜色
  final List<Color> backgroundColor;

  /// 显示音量、亮度、播放速度、播放进度等信息的小部件的背景颜色
  ///
  /// 默认为Color(0xB3000000)/Colors.black.withOpacity(.7)
  final Color toolTipBackgroundColor;

  /// 按钮和文本等小部件的颜色，默认为[Colors.white]
  final Color foregroundColor;

  /// 文本字体大小，默认为14
  final double textSize;

  /// 文本样式
  final TextStyle? textStyle;

  /// 图标尺寸，默认为20
  final double iconSize;

  /// 是否显示返回按钮，默认为true
  final bool hasBackButton;

  /// 自定义返回按钮
  final Widget? backButton;

  /// 标题
  final String? title;

  /// 标题文本样式
  final TextStyle? titleTextStyle;

  /// 自定义操作按钮
  final VeVodPlayerBuilder<List<Widget>?>? onActionsBuilder;

  /// 中间左侧的小部件
  ///
  /// `lockButton`是可锁定的按钮，用于决定把它放在哪里
  final VeVodPlayerActionsBuilder? onCenterLeftActionsBuilder;

  /// 中间右侧的小部件
  ///
  /// `lockButton`是可锁定的按钮，用于决定把它放在哪里
  final VeVodPlayerActionsBuilder? onCenterRightActionsBuilder;

  /// 暂停时显示的小部件
  final Widget? onPauseBuilder;

  /// 是否通过长按实现最大播放速度播放，默认为true
  final bool allowLongPress;

  /// 是否可以调整音量或亮度，默认为true
  final bool allowVolumeOrBrightness;

  /// 是否可以调整视频进度，默认为true
  final bool allowProgress;

  /// 是否可锁定，默认为true
  final bool allowLock;

  /// 指示器使用的默认颜色，有关默认值，请参阅[VeVodPlayerProgressColors]
  final VeVodPlayerProgressColors? progressColors;

  /// 超过试看时间时显示的小部件。
  final VeVodPlayerBuilder<Widget?>? onMaxPreviewTimeBuilder;

  /// 默认文本样式
  TextStyle get defaultTextStyle {
    final TextStyle style = TextStyle(
      fontSize: textSize,
      color: foregroundColor,
      shadows: const <Shadow>[
        Shadow(color: Colors.black54, offset: Offset(4, 4), blurRadius: 8),
      ],
    );
    if (textStyle != null) return style.merge(textStyle);
    return style;
  }
}

/// Used to configure the [ControlsProgress] widget's colors for how it
/// describes the video's status.
///
/// The widget uses default colors that are customizeable through this class.
class VeVodPlayerProgressColors {
  /// Any property can be set to any paint. They each have defaults.
  VeVodPlayerProgressColors({
    this.backgroundColor = const Color.fromRGBO(255, 255, 255, .3),
    this.playedColor = const Color.fromRGBO(255, 255, 255, 1),
    this.bufferedColor = const Color.fromRGBO(255, 255, 255, .6),
    this.handleColor = const Color.fromRGBO(255, 255, 255, 1),
  }) : handleMoreColor = handleColor.withOpacity(.7);

  /// [backgroundColor] defaults to white at 30% opacity. This is the background
  /// color behind both [playedColor] and [bufferedColor] to denote the total
  /// size of the video compared to either of those values.
  final Color backgroundColor;

  /// [playedColor] defaults to white. This fills up a portion of the
  /// [ControlsProgress] to represent how much of the video has played so far.
  final Color playedColor;

  /// [bufferedColor] defaults to white at 60% opacity. This fills up a portion
  /// of [ControlsProgress] to represent how much of the video has buffered so
  /// far.
  final Color bufferedColor;

  /// [handleColor] defaults to white. To represent the playback position of
  /// the current video.
  final Color handleColor;

  /// [handleMoreColor] defaults to white at 70% opacity. To represent the
  /// playback position of the current video.
  final Color handleMoreColor;
}

/// [VeVodPlayerControls]的默认隐藏时间
const Duration kDefaultHideDuration = Duration(seconds: 3);
