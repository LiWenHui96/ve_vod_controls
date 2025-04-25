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
  });

  /// 当前数据
  final double value;

  /// 音量或屏幕亮度
  final DragVerticalType? type;

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
              backgroundColor: const Color.fromRGBO(255, 255, 255, .5),
              minHeight: height,
            ),
          ),
        ),
      ],
    );
  }

  Widget get _buildIcon {
    final Icon? icon = type?.getIcon(value);
    if (icon == null) return const SizedBox.shrink();

    const IconThemeData data = IconThemeData(size: 16, color: Colors.white);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: IconTheme(data: data, child: icon),
    );
  }
}
