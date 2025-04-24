/// @Describe: 播放速度
///
/// @Author: LiWeNHuI
/// @Date: 2024/9/3

part of '../ve_vod_player_controls.dart';

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

    return GestureDetector(
      onTap: () {
        onVisible?.call();
        _showSpeedsDialog(
          context,
          speeds: controller.playbackSpeeds,
          playbackSpeed: speed,
          config: config,
          onChanged: onChanged,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Text(label, style: config.defaultTextStyle),
      ),
    );
  }
}

/// 展示倍速选择框
Future<void> _showSpeedsDialog(
  BuildContext context, {
  required List<double> speeds,
  required double playbackSpeed,
  required VeVodPlayerControlsConfig config,
  ValueChanged<double>? onChanged,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.transparent,
    useSafeArea: false,
    builder: (BuildContext ctx) {
      return Dialog(
        backgroundColor: config.toolTipBackgroundColor,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        alignment: Alignment.centerRight,
        child: SizedBox.fromSize(
          size: Size(0, MediaQuery.sizeOf(context).height),
          child: SpeedsDialog(
            speeds: speeds,
            playbackSpeed: playbackSpeed,
            config: config,
            onChanged: (double speed) {
              Navigator.pop(ctx);
              onChanged?.call(speed);
            },
          ),
        ),
      );
    },
  );
}

/// 弹窗视图
class SpeedsDialog extends StatelessWidget {
  const SpeedsDialog({
    super.key,
    required this.speeds,
    required this.playbackSpeed,
    required this.config,
    this.onChanged,
  });

  /// 倍速列表
  final List<double> speeds;

  /// 当前倍速
  final double playbackSpeed;

  /// 控制器配置
  final VeVodPlayerControlsConfig config;

  /// 倍速变化回调
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: speeds.map((double speed) {
        final bool isSelected = speed == playbackSpeed;

        Widget child = Text(
          'x$speed',
          style: config.defaultTextStyle.copyWith(
            color: isSelected ? Theme.of(context).primaryColor : null,
          ),
        );

        child = Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: child,
        );

        return GestureDetector(
          onTap: () => onChanged?.call(speed),
          behavior: HitTestBehavior.opaque,
          child: child,
        );
      }).toList(),
    );

    final double height = MediaQuery.sizeOf(context).height * .1;
    child = SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: height),
      child: child,
    );

    return Center(child: child);
  }
}
