/// @Describe: 走马灯
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/18

part of '../../ve_vod_player.dart';

class ControlsMarquee extends StatefulWidget {
  ControlsMarquee({super.key, required this.child})
      : assert(child.maxLines == 1, '需保证文本仅一行');

  /// 子组件
  final Text child;

  @override
  State<ControlsMarquee> createState() => _ControlsMarqueeState();
}

class _ControlsMarqueeState extends State<ControlsMarquee> {
  /// 停滞时长
  final Duration stayDuration = const Duration(seconds: 1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final TextPainter painter = getTextPainter(
          context,
          text: text.data,
          style: style,
          maxLines: text.maxLines,
        )..layout(maxWidth: constraints.maxWidth);

        Widget child = text;
        if (painter.didExceedMaxLines) {
          child = Marquee(
            text: text.data ?? '',
            style: style,
            blankSpace: math.max(0, constraints.maxWidth / 2),
            velocity: 20,
            startAfter: stayDuration,
            pauseAfterRound: stayDuration,
          );
        }
        return SizedBox(height: painter.size.height, child: child);
      },
    );
  }

  /// 获取 [TextPainter]
  TextPainter getTextPainter(
    BuildContext? context, {
    String? text,
    TextStyle? style,
    int? maxLines,
  }) {
    if (context != null) {
      /// 解决渲染与输出不一致的问题
      /// https://github.com/flutter/flutter/issues/141172
      style = DefaultTextStyle.of(context).style.merge(style);
    }

    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      locale: WidgetsBinding.instance.platformDispatcher.locale,
    );
  }

  TextStyle get style => text.style ?? DefaultTextStyle.of(context).style;

  Text get text => widget.child;
}
