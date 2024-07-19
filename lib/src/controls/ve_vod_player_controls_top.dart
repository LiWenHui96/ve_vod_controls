/// @Describe: 视频控制组件 顶部
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of ve_vod_controls;

class VeVodPlayerControlsTop extends StatelessWidget {
  const VeVodPlayerControlsTop({super.key});

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerValue value = controller.value;
    final VeVodPlayerControlsConfig config = controller.controlsConfig;

    final Widget leading = IconButton(
      onPressed: () async => Navigator.maybePop(context),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const Icon(Icons.arrow_back_ios),
    );

    final List<Widget> children = <Widget>[
      IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: config.foregroundColor,
            iconSize: config.iconSize,
          ),
        ),
        child: config.backButton ?? leading,
      ),
      _buildTitle(context, config, value),
    ];

    final List<Widget>? actions =
        config.actions?.call(context, value.isFullScreen);
    if (actions != null && actions.isNotEmpty && !value.isCompleted) {
      children.addAll(actions);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: config.backgroundColor,
        ),
      ),
      child: Row(children: children),
    );
  }

  /// 标题
  Widget _buildTitle(
    BuildContext context,
    VeVodPlayerControlsConfig config,
    VeVodPlayerValue value,
  ) {
    final String? title = config.title;

    /// 标题不为空
    final bool isNotBlank = title != null && title.isNotEmpty;

    /// 是否为横屏
    final bool isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isNotBlank && isLandscape && !value.isCompleted) {
      final Text child =
          Text(title, style: config.defaultTextStyle, maxLines: 1);
      return Expanded(child: ControlsMarquee(child: child));
    } else {
      return const Spacer();
    }
  }
}
