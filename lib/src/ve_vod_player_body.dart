/// @Describe: [VeVodPlayer] 主体布局
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of ve_vod_controls;

class VeVodPlayerBody extends StatelessWidget {
  const VeVodPlayerBody({super.key});

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerConfig config = controller.config;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size size = MediaQuery.sizeOf(context);
        final double width = constraints.constrainWidth(size.width);
        final double height = constraints.constrainHeight(size.height);

        /// 视频主体
        Widget child = InteractiveViewer(
          maxScale: config.maxScale,
          minScale: config.minScale,
          panEnabled: config.panEnabled,
          scaleEnabled: config.scaleEnabled,
          child: Selector<VeVodPlayerController, TTVideoPlayerView?>(
            builder: (BuildContext context, TTVideoPlayerView? view, _) {
              if (view == null) return const SizedBox.shrink();
              return view;
            },
            selector: (_, __) => __._vodPlayerView,
          ),
        );

        /// 占位图
        child = Selector<VeVodPlayerController, VeVodPlayerValue>(
          builder: (_, VeVodPlayerValue value, Widget? child) {
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if (child != null) child,
                ...?config.overlayBuilder?.call(value),
              ],
            );
          },
          selector: (_, __) => __.value,
          child: child,
        );

        /// 是否为竖屏
        final bool isPortrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;

        /// 距离顶部的高度
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        final double targetDy = renderBox != null && renderBox.hasSize
            ? renderBox.localToGlobal(Offset.zero).dy
            : 0;

        /// 竖屏情况下，且视频组件高度不为屏幕高度时，添加安全区域
        if (isPortrait && targetDy == 0 && size.height != height) {
          child = SafeArea(bottom: false, child: child);
        }

        /// 子组件
        final List<Widget> children = <Widget>[child];

        /// 控制器
        if (config.hasControls) {
          final Widget child = VeVodPlayerSafeArea(
            size: Size(width, height),
            child: Selector<VeVodPlayerController, VeVodPlayerValue>(
              builder: (BuildContext context, VeVodPlayerValue value, _) {
                return VeVodPlayerControls.structure(controller, value: value);
              },
              selector: (_, __) => __.value,
            ),
          );
          children.add(child);
        }

        return SizedBox.fromSize(
          size: Size(width, height),
          child: Stack(alignment: Alignment.center, children: children),
        );
      },
    );
  }
}

class VeVodPlayerFull extends StatefulWidget {
  const VeVodPlayerFull({
    super.key,
    required this.tag,
    required this.stream,
    required this.backgroundColor,
    required this.child,
    required this.orientationsEnterFullScreen,
    required this.systemOverlaysExitFullScreen,
    required this.orientationsExitFullScreen,
    this.onClose,
  });

  /// Hero Tag
  final Object tag;

  /// 监控全屏的状态变化
  final StreamController<bool> stream;

  /// 背景色
  final Color backgroundColor;

  /// 视频组件
  final VeVodPlayerInherited child;

  /// 定义进入全屏时允许的设备方向
  final List<DeviceOrientation> orientationsEnterFullScreen;

  /// 定义退出全屏后可见的系统层展示
  final List<SystemUiOverlay> systemOverlaysExitFullScreen;

  /// 定义退出全屏后允许的设备方向
  final List<DeviceOrientation> orientationsExitFullScreen;

  /// 关闭全屏
  final VoidCallback? onClose;

  @override
  State<VeVodPlayerFull> createState() => _VeVodPlayerFullState();
}

class _VeVodPlayerFullState extends State<VeVodPlayerFull> {
  /// 监控全屏的状态变化
  StreamSubscription<bool>? _stream;

  @override
  void initState() {
    Future<void>.delayed(Duration.zero, enterFullScreen);

    /// 全屏相关
    _stream = widget.stream.stream.listen(_listener);

    super.initState();
  }

  @override
  void dispose() {
    _stream?.cancel();

    super.dispose();
  }

  /// 全屏状态监听
  Future<void> _listener(bool isFullScreen) async {
    if (!isFullScreen) {
      Future<void>.delayed(Durations.short1, () => Navigator.pop(context));
      await exitFullScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = PopScope(
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        widget.onClose?.call();
      },
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: widget.backgroundColor,
        body: Center(child: widget.child),
      ),
    );

    return Hero(tag: widget.tag, child: child);
  }

  /// 进入全屏模式
  Future<void> enterFullScreen() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    await SystemChrome.setPreferredOrientations(
      widget.orientationsEnterFullScreen,
    );

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: <SystemUiOverlay>[],
    );
  }

  /// 退出全屏模式
  Future<void> exitFullScreen() async {
    await SystemChrome.setPreferredOrientations(<DeviceOrientation>[]);
    await SystemChrome.setPreferredOrientations(
      widget.orientationsExitFullScreen,
    );

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: widget.systemOverlaysExitFullScreen,
    );
  }
}
