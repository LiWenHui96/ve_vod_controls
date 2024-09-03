/// @Describe: [VeVodPlayer] 主体布局
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/16

part of ve_vod_controls;

class VeVodPlayerBody extends StatefulWidget {
  const VeVodPlayerBody({
    super.key,
    required this.controller,
    required this.playerView,
  });

  /// {@macro ve.vod.controls.VodPlayerController}
  final VeVodPlayerController controller;

  /// 播放器视图
  final TTVideoPlayerView playerView;

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
    VeVodPlayer.observer.subscribe(this, ModalRoute.of(context)!);

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
    if (!controller.value.isFullScreen && controller.value.isPlaying) {
      controller.pause();
      isAutoPlayVideo = true;
    }

    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.pause();
    } else if (state == AppLifecycleState.resumed &&
        !controller._isPauseByUser) {
      controller._vodPlayer.forceDraw();
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size screenSize = MediaQuery.sizeOf(context);
        final double width = constraints.constrainWidth(screenSize.width);
        final double height = constraints.constrainHeight(screenSize.height);
        final Size size = Size(width, height);

        final Widget child = VeVodPlayerSafeArea(
          size: size,
          child: InteractiveViewer(
            maxScale: config.maxScale,
            minScale: config.minScale,
            panEnabled: config.panEnabled,
            scaleEnabled: config.scaleEnabled,
            child: SizedBox(child: widget.playerView),
          ),
        );

        return SizedBox.fromSize(
          size: size,
          child: Stack(
            children: <Widget>[
              child,
              VeVodPlayerInherited(
                controller: controller,
                child: ChangeNotifierProvider<VeVodPlayerController>.value(
                  value: controller,
                  builder: (_, __) => _buildControls(size),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 控制器 + 遮罩层
  Widget _buildControls(Size size) {
    return Selector<VeVodPlayerController, VeVodPlayerValue>(
      builder: (_, VeVodPlayerValue value, __) {
        final List<Widget>? overlay = config.overlayBuilder
            ?.call(context, controller, value)
            ?.map((_) => VeVodPlayerSafeArea(size: size, child: _))
            .toList();

        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...?overlay,
            VeVodPlayerControls.structure(controller, value: value, size: size),
          ],
        );
      },
      selector: (_, __) => __.value,
    );
  }

  VeVodPlayerController get controller => widget.controller;

  VeVodPlayerConfig get config => controller.config;
}

class VeVodPlayerFull extends StatefulWidget {
  const VeVodPlayerFull({super.key, required this.controller});

  /// {@macro ve.vod.controls.VodPlayerController}
  final VeVodPlayerController controller;

  @override
  State<VeVodPlayerFull> createState() => _VeVodPlayerFullState();
}

class _VeVodPlayerFullState extends State<VeVodPlayerFull> {
  @override
  void initState() {
    super.initState();

    controller._toggleOrientations();
  }

  @override
  Widget build(BuildContext context) {
    final TTVideoPlayerView vodPlayerView = TTVideoPlayerView(
      key: Key('Ve_Vod_Player_Full_${controller.hashCode}'),
      nativeViewType: controller._nativeViewType,
      onPlatformViewCreated: controller._init,
    );

    final Widget child = Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: controller.config.backgroundColor,
      body: VeVodPlayerBody(controller: controller, playerView: vodPlayerView),
    );

    return PopScope(
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        controller.toggleFullScreen(isFullScreen: false);
      },
      canPop: false,
      child: child,
    );
  }

  VeVodPlayerController get controller => widget.controller;
}
