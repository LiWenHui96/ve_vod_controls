/// @Describe: 播放/暂停按钮
///
/// @Author: LiWeNHuI
/// @Date: 2024/6/3

part of '../ve_vod_player_controls.dart';

class ControlsPlayPause extends StatefulWidget {
  const ControlsPlayPause({
    super.key,
    this.decoration,
    required this.isPlaying,
    this.duration,
    this.onPressed,
  });

  /// [ControlsPlayPause] 的装饰
  final Decoration? decoration;

  /// 是否正在播放
  final bool isPlaying;

  /// 动画的持续时间
  final Duration? duration;

  /// 点击事件
  final VoidCallback? onPressed;

  @override
  State<ControlsPlayPause> createState() => _ControlsPlayPauseState();
}

class _ControlsPlayPauseState extends State<ControlsPlayPause>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: widget.isPlaying ? 1 : 0,
    duration: widget.duration ?? kAnimationDuration,
  );

  @override
  void didUpdateWidget(ControlsPlayPause oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = IconButton(
      onPressed: widget.onPressed,
      enableFeedback: true,
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _controller,
      ),
    );

    if (widget.decoration == null) return child;
    return DecoratedBox(decoration: widget.decoration!, child: child);
  }
}
