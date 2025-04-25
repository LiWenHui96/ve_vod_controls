/// @Describe: 播放进度
///
/// @Author: LiWeNHuI
/// @Date: 2024/6/4

part of '../ve_vod_player_controls.dart';

class ControlsDuration extends StatelessWidget {
  const ControlsDuration({
    super.key,
    required this.duration,
    required this.position,
  });

  /// 总时长
  final Duration duration;

  /// 当前位置
  final Duration position;

  @override
  Widget build(BuildContext context) {
    final VeVodPlayerController controller = VeVodPlayerController.of(context);
    final VeVodPlayerControlsConfig config = controller.controlsConfig;

    final TextStyle style = config.defaultTextStyle.copyWith(height: 1.2);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _buildText(position, style: style),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text('/', style: style),
        ),
        _buildText(duration, style: style),
      ],
    );
  }

  Widget _buildText(Duration duration, {TextStyle? style}) {
    style = style?.copyWith(
      fontFamily: 'RobotoMono',
      fontFeatures: <FontFeature>[const FontFeature.tabularFigures()],
    );
    return Text(formatDuration(duration), style: style);
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
    VeVodPlayerProgressColors? colors,
    required this.value,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTapUp,
  }) : colors = colors ?? VeVodPlayerProgressColors();

  /// 进度条的颜色
  final VeVodPlayerProgressColors colors;

  /// 视频相关数据
  final VeVodPlayerValue value;

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
        final double width =
            constraints.constrainWidth(MediaQuery.sizeOf(context).width);

        final Widget child = Center(
          child: CustomPaint(
            size: Size(width, 10),
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
  final VeVodPlayerProgressColors colors;

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
      if (value.isDragProgress) {
        canvas.drawCircle(
          Offset(playedPart, halfHeight + height / 2),
          height * 1.5,
          Paint()..color = colors.handleMoreColor,
        );
      }

      canvas.drawCircle(
        Offset(playedPart, halfHeight + height / 2),
        height,
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
