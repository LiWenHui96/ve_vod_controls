/// @Describe: 音量/屏幕亮度显示
///
/// @Author: LiWeNHuI
/// @Date: 2024/6/11

part of '../ve_vod_player_controls.dart';

class ControlsVertical extends StatelessWidget {
  const ControlsVertical({
    super.key,
    required this.value,
    required this.type,
    required this.color,
  });

  /// 当前数据
  final double value;

  /// 音量或屏幕亮度
  final DragVerticalType? type;

  /// 图标颜色
  final Color color;

  /// 进度条的高度
  static const double height = 6;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildIcon,
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: SizedBox(
            width: height * 20,
            height: height,
            child: LinearProgressIndicator(
              value: value,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(.5),
              minHeight: height,
            ),
          ),
        ),
      ],
    );
  }

  Widget get _buildIcon {
    final DragVerticalType? type = this.type;
    if (type == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Icon(type.getIcon(value), size: 16, color: color),
    );
  }

  /// Icon for volume.
  List<IconData> get volumeIcons => <IconData>[
        Icons.volume_mute_rounded,
        Icons.volume_down_rounded,
        Icons.volume_up_rounded,
      ];

  /// Icon for brightness.
  List<IconData> get brightnessIcons => <IconData>[
        Icons.brightness_low_rounded,
        Icons.brightness_medium_rounded,
        Icons.brightness_high_rounded,
      ];
}
