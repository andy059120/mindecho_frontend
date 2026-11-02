import 'package:flutter/cupertino.dart';

/// 對齊 Swift 參考畫面的 detail 導覽列高度，保留 Cupertino 的路由轉場。
class SwiftDetailNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  const SwiftDetailNavigationBar({required this.child, super.key});
  final CupertinoNavigationBar child;
  @override
  Size get preferredSize => Size.fromHeight(child.preferredSize.height + 20);
  @override
  bool shouldFullyObstruct(BuildContext context) =>
      child.shouldFullyObstruct(context);
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: CupertinoDynamicColor.resolve(
      child.backgroundColor ?? CupertinoTheme.of(context).barBackgroundColor,
      context,
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: child,
    ),
  );
}
