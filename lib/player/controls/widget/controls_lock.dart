/// @Describe: 锁定/解锁按钮
///
/// @Author: LiWeNHuI
/// @Date: 2024/7/22

part of '../../ve_vod_player.dart';

class ControlsLock extends StatelessWidget {
  const ControlsLock({
    super.key,
    required this.isLock,
    this.allowLock = true,
    this.size,
    this.color,
    this.onLock,
  });

  /// 是否被锁定
  final bool isLock;

  /// 是否可锁定
  ///
  /// 默认为true
  final bool allowLock;

  /// [IconButton] 的尺寸
  final double? size;

  /// [IconButton] 的颜色
  final Color? color;

  /// 点击事件
  final VoidCallback? onLock;

  @override
  Widget build(BuildContext context) {
    final Widget child = IconButton(
      iconSize: size,
      visualDensity: VisualDensity.comfortable,
      padding: EdgeInsets.zero,
      color: color,
      onPressed: onLock,
      enableFeedback: true,
      isSelected: isLock,
      selectedIcon: const Icon(Icons.lock_outline),
      icon: const Icon(Icons.lock_open_outlined),
    );

    return Visibility(visible: allowLock, child: child);
  }
}
