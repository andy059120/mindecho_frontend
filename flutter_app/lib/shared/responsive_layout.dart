import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

/// Web 使用可用空間；原生 App 保留既有 iOS 版面。
abstract final class WebLayout {
  static const sidebarWidth = 216.0;
  static bool wide(BuildContext context) =>
      kIsWeb && MediaQuery.sizeOf(context).width >= 900;
}

class WebContentFrame extends StatelessWidget {
  const WebContentFrame({required this.child, this.maxWidth = 1120, super.key});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => kIsWeb
      ? Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SizedBox(width: double.infinity, child: child),
          ),
        )
      : child;
}

/// 依實際內容區寬度切換，避免側邊欄或文字放大後擠壓卡片。
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

/// 寬螢幕自動換列，觸控窄螢幕維持 iOS 的橫向卡片。
class ResponsiveShelf extends StatelessWidget {
  const ResponsiveShelf({
    required this.itemCount,
    required this.itemBuilder,
    required this.itemHeight,
    super.key,
  });
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (kIsWeb && constraints.maxWidth >= 760) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 240,
            mainAxisExtent: itemHeight,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      }
      return SizedBox(
        height: itemHeight,
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
