/// @Describe: 播放速度
///
/// @Author: LiWeNHuI
/// @Date: 2024/9/3

part of ve_vod_controls;

class ControlsSpeed extends StatelessWidget {
  const ControlsSpeed({
    super.key,
    required this.speed,
    this.onChanged,
    this.onVisible,
  });

  /// 当前播放进度
  final double speed;

  /// 速度变化
  final ValueChanged<double>? onChanged;

  /// 隐蔽控制器
  final VoidCallback? onVisible;

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerControlsConfig config = controller.controlsConfig;

    final String label = speed == 1.0 ? '倍速' : 'x$speed';

    return TextButton(
      onPressed: () {
        onVisible?.call();
        _showDialog(
          context,
          speeds: controller.playbackSpeeds,
          playbackSpeed: speed,
          config: config,
          onChanged: onChanged,
        );
      },
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
      child: Text(label, style: config.defaultTextStyle),
    );
  }

  /// 设置播放速度
  Future<void> _showDialog(
    BuildContext context, {
    required List<double> speeds,
    required double playbackSpeed,
    required VeVodPlayerControlsConfig config,
    ValueChanged<double>? onChanged,
  }) async {
    final Size size = MediaQuery.sizeOf(context);
    final double width = size.width * .15;
    final double height = size.height;

    const double itemHeight = 45;
    final bool isMax = height >= itemHeight * speeds.length;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      useSafeArea: false,
      builder: (BuildContext ctx) {
        Widget child = Column(
          mainAxisAlignment:
              isMax ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.start,
          children: speeds.map((double speed) {
            final bool isSelected = speed == playbackSpeed;

            Widget child = Text(
              'x$speed',
              style: config.defaultTextStyle.copyWith(
                fontSize: 14,
                color: isSelected ? Theme.of(context).primaryColor : null,
              ),
            );

            child = Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: itemHeight),
              child: child,
            );

            return GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                onChanged?.call(speed);
              },
              behavior: HitTestBehavior.opaque,
              child: child,
            );
          }).toList(),
        );

        if (isMax) {
          child = Padding(
            padding: EdgeInsets.symmetric(vertical: height * .1),
            child: child,
          );
        } else {
          child = SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: height * .1),
            child: child,
          );
        }

        return Dialog(
          backgroundColor: config.toolTipBackgroundColor,
          insetPadding: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
          ),
          alignment: Alignment.centerRight,
          child: SizedBox.fromSize(
            size: Size(width, height),
            child: child,
          ),
        );
      },
    );
  }
}
