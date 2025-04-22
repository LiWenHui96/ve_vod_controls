/// @Describe: 播放进度
///
/// @Author: LiWeNHuI
/// @Date: 2024/6/4

part of ve_vod_player;

class ControlsDuration extends StatelessWidget {
  const ControlsDuration({
    super.key,
    required this.duration,
    this.durationStyle,
    required this.position,
    this.positionStyle,
  });

  /// 总时长
  final Duration duration;

  /// [duration]文本样式
  final TextStyle? durationStyle;

  /// 当前位置
  final Duration position;

  /// [position]文本样式
  final TextStyle? positionStyle;

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerControlsConfig config = controller.controlsConfig;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildText(
          formatDuration(position),
          style: positionStyle ?? config.defaultTextStyle,
        ),
        Text('/', style: durationStyle ?? config.defaultTextStyle),
        _buildText(
          formatDuration(duration),
          style: durationStyle ?? config.defaultTextStyle,
        ),
      ],
    );
  }

  Widget _buildText(String text, {TextStyle? style}) {
    style = style?.copyWith(height: 1.4);
    final Size size = _calculateMaxWidth(style);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').map((String value) {
        final Widget child = Text(value, style: style);
        if (value == ':') return child;
        return SizedBox.fromSize(size: size, child: Center(child: child));
      }).toList(),
    );
  }

  /// 计算各方块最大宽度
  Size _calculateMaxWidth(TextStyle? style) {
    double maxWidth = double.minPositive;
    double maxHeight = double.minPositive;

    for (final String text in List<String>.generate(10, (_) => '$_')) {
      final TextPainter painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        locale: WidgetsBinding.instance.platformDispatcher.locale,
      )..layout();
      maxWidth = math.max(maxWidth, painter.width);
      maxHeight = math.max(maxHeight, painter.height);
    }

    return Size(maxWidth, maxHeight);
  }

  /// 通过[position]计算小时、分钟和秒
  String formatDuration(Duration position) {
    final int ms = position.inMilliseconds;

    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    final int minutes = seconds ~/ 60;
    seconds = seconds % 60;

    final String minutesString = minutes.toString().padLeft(2, '0');
    final String secondsString = seconds.toString().padLeft(2, '0');

    return '${hours == 0 ? '' : '$hours:'}$minutesString:$secondsString';
  }
}

class ControlsProgress extends StatefulWidget {
  ControlsProgress({
    super.key,
    ControlsProgressColors? colors,
    required this.value,
    required this.height,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapUp,
  }) : colors = colors ?? ControlsProgressColors();

  /// 进度条的颜色
  final ControlsProgressColors colors;

  /// 视频相关数据
  final VeVodPlayerValue value;

  /// 高度
  final double height;

  /// 滑动开始，触发进度调节
  final GestureDragStartCallback onDragStart;

  /// 滑动，调节播放进度
  final ValueChanged<double> onDragUpdate;

  /// 滑动结束，结束进度调节触发效果
  final GestureDragEndCallback onDragEnd;

  /// 点击进度条更改视频播放进度
  final ValueChanged<double> onTapUp;

  @override
  State<ControlsProgress> createState() => _ControlsProgressState();
}

class _ControlsProgressState extends State<ControlsProgress> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget child = Center(
          child: CustomPaint(
            size: Size(
              constraints.constrainWidth(MediaQuery.sizeOf(context).width),
              math.max(widget.height, 4),
            ),
            painter: ControlsProgressPainter(
              value: widget.value,
              colors: widget.colors,
            ),
          ),
        );

        return GestureDetector(
          onHorizontalDragStart: widget.onDragStart,
          onHorizontalDragUpdate: (DragUpdateDetails details) {
            widget.onDragUpdate.call(_seekToRelative(details.globalPosition));
          },
          onHorizontalDragEnd: widget.onDragEnd,
          onTapUp: (TapUpDetails details) {
            widget.onTapUp.call(_seekToRelative(details.globalPosition));
          },
          child: child,
        );
      },
    );
  }

  double _seekToRelative(Offset globalPosition) {
    final RenderBox box = context.findRenderObject()! as RenderBox;
    return box.globalToLocal(globalPosition).dx / box.size.width;
  }
}

class ControlsProgressPainter extends CustomPainter {
  ControlsProgressPainter({
    super.repaint,
    required this.value,
    required this.colors,
    this.isPoints = true,
  });

  /// 视频相关数据
  final VeVodPlayerValue value;

  /// 进度条的颜色
  final ControlsProgressColors colors;

  /// 是否绘制瞄点
  final bool isPoints;

  @override
  void paint(Canvas canvas, Size size) {
    const double height = 4;
    const Radius radius = Radius.circular(8);

    final double halfHeight = (size.height - height) / 2;

    final Offset start = Offset(0, halfHeight);
    final Offset end = Offset(size.width, halfHeight + height);

    /// 背景
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromPoints(start, end), radius),
      Paint()..color = colors.backgroundColor,
    );

    if (!value.isInitialized) return;

    /// 缓冲进度
    final double bufferedPartPercent =
        value.buffered.inMilliseconds / value.duration.inMilliseconds;
    final double bufferedPart = handleValue(bufferedPartPercent) * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(start, Offset(bufferedPart, halfHeight + height)),
        radius,
      ),
      Paint()..color = colors.bufferedColor,
    );

    /// 已播放/已调节进度
    final Duration position =
        value.isDragProgress || value.dragDuration > Duration.zero
            ? value.dragDuration
            : value.position;
    final double playedPartPercent =
        position.inMilliseconds / value.duration.inMilliseconds;
    final double playedPart = handleValue(playedPartPercent) * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromPoints(start, Offset(playedPart, halfHeight + height)),
        radius,
      ),
      Paint()..color = colors.playedColor,
    );

    if (isPoints) {
      canvas.drawCircle(
        Offset(playedPart, halfHeight + height / 2),
        height * (value.isDragProgress ? 1.35 : 1),
        Paint()..color = colors.handleColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ControlsProgressPainter) {
      return oldDelegate.value != value ||
          oldDelegate.colors != colors ||
          oldDelegate.isPoints != isPoints;
    }
    return false;
  }

  /// 计算数据
  double handleValue(double value) {
    if (value > 1) {
      return 1;
    } else if (value.isNegative) {
      return 0;
    } else {
      return value;
    }
  }
}
