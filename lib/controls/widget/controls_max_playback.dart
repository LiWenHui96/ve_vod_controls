/// @Describe: 最大播放速度提示
///
/// @Author: LiWeNHuI
/// @Date: 2024/6/4

part of '../ve_vod_player_controls.dart';

class ControlsMaxPlayback extends StatefulWidget {
  const ControlsMaxPlayback({super.key});

  @override
  State<ControlsMaxPlayback> createState() => _ControlsMaxPlaybackState();
}

class _ControlsMaxPlaybackState extends State<ControlsMaxPlayback>
    with TickerProviderStateMixin {
  late AnimationController controller;
  late Animation<int> _animation;

  /// Icon色值
  final List<double> _opacity = <double>[.25, .5, .75, 1];

  /// Icon1
  int _icon1 = 3;

  /// Icon2
  int _icon2 = 2;

  /// Icon3
  int _icon3 = 1;

  @override
  void initState() {
    super.initState();

    controller =
        AnimationController(duration: Durations.extralong4, vsync: this);

    _animation = IntTween(begin: 0, end: 5).animate(controller)
      ..addListener(_listener);

    /// 启动动画
    controller.repeat();
  }

  @override
  void dispose() {
    _animation.removeListener(_listener);
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildIcon(_icon1),
        _buildIcon(_icon2),
        _buildIcon(_icon3),
        const SizedBox(width: 4),
        const Text(
          '倍速播放中',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ],
    );
  }

  /// Icon
  Widget _buildIcon(int index) {
    return AnimatedOpacity(
      opacity: _opacity[index],
      duration: kAnimationDuration,
      child: const Icon(
        CupertinoIcons.play_arrow_solid,
        size: 14,
        color: Colors.white,
      ),
    );
  }

  /// 动画监听
  void _listener() {
    final int value = _animation.value;
    switch (value) {
      case 0:
        _icon1 = 3;
        _icon2 = 2;
        _icon3 = 1;
      case 1:
        _icon1 = 2;
        _icon2 = 3;
        _icon3 = 2;
      case 2:
        _icon1 = 1;
        _icon2 = 2;
        _icon3 = 3;
      case 3:
        _icon1 = 0;
        _icon2 = 1;
        _icon3 = 2;
      case 4:
        _icon1 = 1;
        _icon2 = 0;
        _icon3 = 1;
      case 5:
        _icon1 = 2;
        _icon2 = 1;
        _icon3 = 0;
    }
    setState(() {});
  }
}
