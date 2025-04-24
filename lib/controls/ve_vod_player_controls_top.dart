/// @Describe: 视频控制组件 顶部
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of 've_vod_player_controls.dart';

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
      icon: const Icon(Icons.arrow_back_ios_rounded),
    );

    /// 是否展示返回按钮
    final bool hasBackButton = config.hasBackButton &&
        (value.isFullScreen || (ModalRoute.of(context)?.canPop ?? false));

    final List<Widget> children = <Widget>[
      if (hasBackButton) config.backButton ?? leading,
      _buildTitle(context, config, value),
    ];

    final List<Widget>? actions =
        config.onActionsBuilder?.call(context, controller, value);
    if (actions != null && actions.isNotEmpty) children.addAll(actions);

    Widget child = IconButtonTheme(
      data: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: config.foregroundColor,
          iconSize: config.iconSize,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: Row(children: children),
    );

    /// 屏幕方向
    final Orientation orientation = MediaQuery.orientationOf(context);
    if (orientation == Orientation.landscape) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: config.backgroundColor,
        ),
      ),
      child: VeVodPlayerSafeArea(bottom: false, child: child),
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
      final Text child = Text(
        title,
        style: config.titleTextStyle ?? config.defaultTextStyle,
        maxLines: 1,
      );
      return Expanded(child: ControlsMarquee(child: child));
    } else {
      return const Spacer();
    }
  }
}
