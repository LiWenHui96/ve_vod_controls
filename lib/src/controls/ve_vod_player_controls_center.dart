/// @Describe: 视频控制组件 中部
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/22

part of ve_vod_controls;

class VeVodPlayerControlsCenter extends StatelessWidget {
  const VeVodPlayerControlsCenter({super.key, this.onVisible});

  /// 用于显示控制器
  final VoidCallback? onVisible;

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerValue value = controller.value;
    final VeVodPlayerControlsConfig config = controller.controlsConfig;

    ControlsLock lockButton() {
      return ControlsLock(
        isLock: value.isLock,
        allowLock: config.allowLock,
        color: config.foregroundColor,
        onLock: () {
          onVisible?.call();
          controller.toggleLock();
        },
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

    final Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        actions(config.centerLeftActionsBuilder),
        actions(config.centerRightActionsBuilder),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SafeArea(top: false, bottom: false, child: child),
    );
  }
}
