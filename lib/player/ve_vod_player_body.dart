/// @Describe: [VeVodPlayer] 主体布局
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of 've_vod_player.dart';

class VeVodPlayerBody extends StatefulWidget {
  const VeVodPlayerBody({
    super.key,
    required this.controller,
    required this.child,
  });

  /// {@macro ve.vod.controls.VodPlayerController}
  final VeVodPlayerController controller;

  /// 播放器视图
  final Widget child;

  @override
  State<VeVodPlayerBody> createState() => _VeVodPlayerBodyState();
}

class _VeVodPlayerBodyState extends State<VeVodPlayerBody>
    with WidgetsBindingObserver, RouteAware {
  /// 是否自动播放、暂停播放视频
  bool isAutoPlayVideo = false;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    // ignore: always_specify_types
    VeVodPlayer.observer.subscribe(this, ModalRoute.of(context)! as PageRoute);

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    VeVodPlayer.observer.unsubscribe(this);

    super.dispose();
  }

  @override
  void didPopNext() {
    if (isAutoPlayVideo && !controller.value.isPlaying) {
      controller.play();
      isAutoPlayVideo = false;
    }

    super.didPopNext();
  }

  @override
  void didPushNext() {
    Future<void>.delayed(Durations.short4, () {
      if (!controller.value.isFullScreen && controller.value.isPlaying) {
        controller.pause();
        isAutoPlayVideo = true;
      }
    });

    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      controller
        ..pause()
        .._isAppInBackground = true;
      if (Platform.isAndroid) controller._removeVolumeListener();
    } else if (state == AppLifecycleState.resumed &&
        !controller._isPauseByUser &&
        !isAutoPlayVideo) {
      controller._vodPlayer.forceDraw();
      controller.play();
      if (Platform.isAndroid) controller._addVolumeListener();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<VeVodPlayerController>.value(
      value: controller,
      builder: (_, __) => Stack(
        children: <Widget>[
          InteractiveViewer(
            maxScale: config.maxScale,
            minScale: config.minScale,
            panEnabled: config.panEnabled,
            scaleEnabled: config.scaleEnabled,
            child: _buildBody,
          ),
          VeVodPlayerInherited(controller: controller, child: _buildControls),
        ],
      ),
    );
  }

  /// 视频主体
  Widget get _buildBody {
    return Selector<VeVodPlayerController, bool>(
      builder: (_, bool isFullScreen, __) {
        return VeVodPlayerSafeArea.insert(
          useSafe: !isFullScreen,
          child: widget.child,
        );
      },
      selector: (_, VeVodPlayerController controller) {
        return controller.value.isFullScreen;
      },
    );
  }

  /// 控制器 + 遮罩层
  Widget get _buildControls {
    return Selector<VeVodPlayerController, VeVodPlayerValue>(
      builder: (_, VeVodPlayerValue value, __) {
        final List<Widget>? overlay =
            _buildSafeArea(builder: config.onOverlayBuilder, value: value);

        final List<Widget>? placeholder =
            _buildSafeArea(builder: config.onPlaceholderBuilder, value: value);

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ...?overlay,
            VeVodPlayerControls.structure(controller, value: value),
            ...?placeholder,
          ],
        );
      },
      selector: (_, VeVodPlayerController controller) => controller.value,
    );
  }

  List<Widget>? _buildSafeArea({
    required VeVodPlayerBuilder<List<Widget>?>? builder,
    required VeVodPlayerValue value,
  }) {
    return builder?.call(context, controller, value)?.map((Widget child) {
      return VeVodPlayerSafeArea(child: Center(child: child));
    }).toList();
  }

  VeVodPlayerConfig get config => controller.config;

  VeVodPlayerController get controller => widget.controller;
}

/// 安全区域
class VeVodPlayerSafeArea extends StatefulWidget {
  const VeVodPlayerSafeArea({
    super.key,
    this.left = true,
    this.top = true,
    this.right = true,
    this.bottom = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
    required this.child,
  });

  const VeVodPlayerSafeArea.insert({
    super.key,
    bool useSafe = true,
    this.minimum = EdgeInsets.zero,
    this.maintainBottomViewPadding = false,
    required this.child,
  })  : left = useSafe,
        top = useSafe,
        right = useSafe,
        bottom = useSafe;

  /// Whether to avoid system intrusions on the left.
  final bool left;

  /// Whether to avoid system intrusions at the top of the screen, typically the
  /// system status bar.
  final bool top;

  /// Whether to avoid system intrusions on the right.
  final bool right;

  /// Whether to avoid system intrusions on the bottom side of the screen.
  final bool bottom;

  /// This minimum padding to apply.
  ///
  /// The greater of the minimum insets and the media padding will be applied.
  final EdgeInsets minimum;

  /// Specifies whether the [SafeArea] should maintain the bottom
  /// [MediaQueryData.viewPadding] instead of the bottom
  /// [MediaQueryData.padding],
  /// defaults to false.
  ///
  /// For example, if there is an onscreen keyboard displayed above the
  /// SafeArea, the padding can be maintained below the obstruction rather than
  /// being consumed. This can be helpful in cases where your layout contains
  /// flexible widgets, which could visibly move when opening a software
  /// keyboard due to the change in the padding value. Setting this to true will
  /// avoid the UI shift.
  final bool maintainBottomViewPadding;

  /// 子组件
  final Widget child;

  @override
  State<VeVodPlayerSafeArea> createState() => _VeVodPlayerSafeAreaState();
}

class _VeVodPlayerSafeAreaState extends State<VeVodPlayerSafeArea> {
  /// 视图尺寸
  Size size = Size.zero;

  /// 距屏幕左上角的距离
  Offset topOffset = Offset.zero;

  /// 距屏幕左下角的距离
  Offset bottomOffset = Offset.zero;

  @override
  void initState() {
    _getData();

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _getData();

    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    /// 屏幕方向
    final Orientation orientation = MediaQuery.orientationOf(context);

    return SafeArea(
      left: widget.left,
      top: widget.top &&
          orientation == Orientation.portrait &&
          topOffset.dy <= 0,
      right: widget.right,
      bottom: widget.bottom &&
          orientation == Orientation.portrait &&
          bottomOffset.dy >= 0,
      minimum: widget.minimum,
      maintainBottomViewPadding: widget.maintainBottomViewPadding,
      child: widget.child,
    );
  }

  /// 获取屏幕相关数据
  void _getData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      /// 屏幕尺寸
      final Size screenSize = MediaQuery.sizeOf(context);

      setState(() {
        size = renderBox.size;
        topOffset = renderBox.localToGlobal(Offset.zero);
        bottomOffset = renderBox.localToGlobal(Offset(0, size.height)) -
            Offset(0, screenSize.height);
      });
    });
  }
}

/// 用于传递[VeVodPlayer]的小部件。
class VeVodPlayerInherited extends InheritedWidget {
  const VeVodPlayerInherited({
    super.key,
    required this.controller,
    required super.child,
  });

  /// 播放控制器
  final VeVodPlayerController controller;

  @override
  bool updateShouldNotify(covariant VeVodPlayerInherited oldWidget) =>
      controller != oldWidget.controller;
}
