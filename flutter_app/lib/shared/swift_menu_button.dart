import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';

import '../app/theme.dart';
import 'system_symbol.dart';

/// 與 SwiftUI Menu 相同，讓篩選選單緊鄰觸發按鈕。
class SwiftMenuButton extends StatefulWidget {
  const SwiftMenuButton({
    required this.label,
    required this.options,
    required this.onSelected,
    this.symbol = 'chevron.down',
    this.accessibilityLabel,
    this.filled = false,
    this.dividerAfterFirst = false,
    super.key,
  });
  final String label, symbol;
  final String? accessibilityLabel;
  final bool filled, dividerAfterFirst;
  final List<String> options;
  final ValueChanged<String> onSelected;
  @override
  State<SwiftMenuButton> createState() => _SwiftMenuButtonState();
}

class _SwiftMenuButtonState extends State<SwiftMenuButton> {
  final _anchor = GlobalKey();
  bool _open = false;
  Future<void> _show() async {
    if (_open || widget.options.isEmpty) return;
    final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
    setState(() => _open = true);
    final choice = await showGeneralDialog<String>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierLabel: '關閉選單',
      barrierColor: const Color(0x00000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondary) => _MenuSurface(
        anchor: rect,
        options: widget.options,
        animation: animation,
        dividerAfterFirst: widget.dividerAfterFirst,
      ),
      transitionBuilder: (context, animation, secondary, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (choice != null) widget.onSelected(choice);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.accessibilityLabel == null
        ? widget.label
        : '${widget.accessibilityLabel}，${widget.label}',
    button: true,
    excludeSemantics: true,
    onTap: _show,
    child: CupertinoButton(
      key: _anchor,
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: _show,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: widget.filled ? 10 : 6,
          vertical: widget.filled ? 6 : 4,
        ),
        decoration: BoxDecoration(
          color: _open
              ? AppColors.title.withValues(alpha: .06)
              : widget.filled
              ? AppColors.lightYellow.withValues(alpha: .45)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.title.withValues(alpha: .7),
              ),
            ),
            const SizedBox(width: 4),
            SystemSymbol(
              widget.symbol,
              size: 10,
              color: AppColors.title.withValues(alpha: .7),
              fallback: widget.symbol == 'chevron.down'
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.line_horizontal_3_decrease,
            ),
          ],
        ),
      ),
    ),
  );
}

class _MenuSurface extends StatelessWidget {
  const _MenuSurface({
    required this.anchor,
    required this.options,
    required this.animation,
    required this.dividerAfterFirst,
  });
  final Rect anchor;
  final bool dividerAfterFirst;
  final List<String> options;
  final Animation<double> animation;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final padding = MediaQuery.paddingOf(context);
      final width = math.min(250.0, constraints.maxWidth - 24);
      final height = math.min(
        options.length * 44.0 + 8 + (dividerAfterFirst ? .5 : 0),
        constraints.maxHeight - padding.top - padding.bottom - 24,
      );
      final left = (anchor.right - width).clamp(
        12.0,
        math.max(12.0, constraints.maxWidth - width - 12),
      );
      final below = constraints.maxHeight - padding.bottom - anchor.bottom - 8;
      final top =
          (below >= height ? anchor.center.dy - 36 : anchor.top - height + 26)
              .clamp(
                padding.top + 12,
                math.max(
                  padding.top + 12,
                  constraints.maxHeight - padding.bottom - height - 12,
                ),
              );
      return Stack(
        children: [
          Positioned(
            left: left.toDouble(),
            top: top.toDouble(),
            width: width,
            height: height,
            child: ScaleTransition(
              alignment: below >= height
                  ? Alignment.topRight
                  : Alignment.bottomRight,
              scale: Tween(begin: .94, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: ColoredBox(
                      color: CupertinoColors.systemBackground
                          .resolveFrom(context)
                          .withValues(alpha: .96),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: options.length,
                        separatorBuilder: (_, index) =>
                            dividerAfterFirst && index == 0
                            ? Container(
                                height: .5,
                                color: CupertinoColors.separator.resolveFrom(
                                  context,
                                ),
                              )
                            : const SizedBox.shrink(),
                        itemBuilder: (context, index) => CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          minimumSize: const Size(0, 44),
                          onPressed: () =>
                              Navigator.pop(context, options[index]),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              options[index],
                              style: const TextStyle(
                                fontSize: 17,
                                height: 1.2,
                                color: CupertinoColors.label,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
