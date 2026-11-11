import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// 依視窗空間配置導覽；平台差異由各自的 adapter 處理。
abstract final class ResponsiveLayout {
  static const sidebarWidth = 216.0;
  static const dashboardMaxWidth = kIsWeb ? 1120.0 : double.infinity;
  static const bottomNavigationMaxWidth = 760.0;

  /// 原生 App 維持手機風格的底部分頁，Web 寬視窗採側邊導覽。
  static bool useSidebar(BuildContext context) => kIsWeb && wide(context);
  static bool wide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;
}

/// 主頁使用流動式留白；不將整個 Navigator 限制成手機寬度。
class ResponsivePage extends StatelessWidget {
  const ResponsivePage({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ColoredBox(
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: kIsWeb
              ? 0
              : ((constraints.maxWidth - 600) * .05).clamp(0.0, 40.0),
        ),
        child: child,
      ),
    ),
  );
}

class ContentFrame extends StatelessWidget {
  const ContentFrame({required this.child, this.maxWidth = 1120, super.key});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

/// Web 依內容區寬度切換雙欄；原生 App 維持手機風格的單欄。
class ResponsivePair extends StatelessWidget {
  const ResponsivePair({required this.first, required this.second, super.key});
  final Widget first, second;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        kIsWeb &&
            constraints.maxWidth >= 760 &&
            MediaQuery.textScalerOf(context).scale(16) <= 20
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 20),
              Expanded(child: second),
            ],
          )
        : Column(children: [first, const SizedBox(height: 12), second]),
  );
}

/// 卡片依可用空間換列；窄視窗維持橫向捲動。
class ResponsiveShelf extends StatelessWidget {
  const ResponsiveShelf({
    required this.itemCount,
    required this.itemBuilder,
    required this.itemHeight,
    this.maxItemWidth = 240,
    this.allowGrid = true,
    super.key,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemHeight;
  final double maxItemWidth;
  final bool allowGrid;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
        1.0,
        3.0,
      );
      final tileHeight = itemHeight + (scale - 1) * 120;
      if (allowGrid && constraints.maxWidth >= 760) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (constraints.maxWidth / (maxItemWidth * scale))
                .ceil()
                .clamp(1, itemCount > 0 ? itemCount : 1),
            mainAxisExtent: tileHeight + (itemHeight >= 180 ? 44 : 24),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      }
      return SizedBox(
        height: tileHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(width: 16),
          itemBuilder: itemBuilder,
        ),
      );
    },
  );
}
