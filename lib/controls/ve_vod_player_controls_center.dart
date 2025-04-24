/// @Describe: 视频控制组件 中部
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/22

part of 've_vod_player_controls.dart';

class VeVodPlayerControlsCenter extends StatelessWidget {
  const VeVodPlayerControlsCenter({super.key, this.onLock});

  /// 锁定点击事件
  final VoidCallback? onLock;

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerValue value = controller.value;
    final VeVodPlayerControlsConfig config = controller.controlsConfig;

    ControlsLock lockButton() {
      return ControlsLock(
        isLock: value.isLock,
        allowLock: config.allowLock,
        onLock: onLock,
      );
    }

    Widget actions(VeVodPlayerActionsBuilder? actions) {
      List<Widget>? list =
          actions?.call(context, controller, value, lockButton());
      list ??= <Widget>[lockButton()];

      final List<Widget> children = list.map((Widget child) {
        return Container(
          padding: child is IconButton || child is ControlsLock
              ? null
              : const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: config.toolTipBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        );
      }).toList();

      return Column(mainAxisSize: MainAxisSize.min, children: children);
    }

    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        actions(config.onCenterLeftActionsBuilder),
        actions(config.onCenterRightActionsBuilder),
      ],
    );

    child = IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: config.foregroundColor,
          iconSize: config.iconSize,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: child,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(top: false, bottom: false, child: child),
    );
  }
}
