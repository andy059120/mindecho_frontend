import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'responsive_layout.dart';

class TabTourOverlay extends StatelessWidget {
  const TabTourOverlay({
    required this.index,
    required this.title,
    required this.message,
    required this.onNext,
    required this.onClose,
    this.sidebar = false,
    super.key,
  });
  final bool sidebar;
  final int index;
  final String title, message;
  final VoidCallback onNext, onClose;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bottom = MediaQuery.paddingOf(context).bottom;
      final itemWidth = (constraints.maxWidth - 60) / 4;
      final rect = sidebar
          ? Rect.fromLTWH(
              12,
              MediaQuery.paddingOf(context).top + 92 + index * 60,
              WebLayout.sidebarWidth - 24,
              52,
            )
          : Rect.fromLTWH(
              6 + index * (itemWidth + 12),
              constraints.maxHeight - bottom - 68,
              itemWidth + 12,
              66,
            );
      final width = math.min(260.0, constraints.maxWidth - 32);
      final left = (rect.center.dx - width / 2).clamp(
        8.0,
        constraints.maxWidth - width - 8,
      );
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onNext,
              child: TweenAnimationBuilder<Rect?>(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                tween: RectTween(begin: rect, end: rect),
                builder: (context, value, _) =>
                    CustomPaint(painter: _TourMask(value!)),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            left: sidebar ? WebLayout.sidebarWidth + 16 : left,
            top: sidebar ? rect.top : null,
            bottom: sidebar ? null : bottom + 96,
            width: width,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.black.withValues(alpha: .75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.white.withValues(alpha: .9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        onPressed: onClose,
                        child: Text(
                          '略過',
                          style: TextStyle(
                            fontSize: 17,
                            color: CupertinoColors.white.withValues(alpha: .8),
                          ),
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        minimumSize: Size.zero,
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: onNext,
                        child: Text(
                          index == 3 ? '完成' : '下一步',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _TourMask extends CustomPainter {
  _TourMask(this.hole);
  final Rect hole;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(14)));
    canvas.drawPath(
      path,
      Paint()..color = CupertinoColors.black.withValues(alpha: .6),
    );
  }

  @override
  bool shouldRepaint(covariant _TourMask old) => old.hole != hole;
}
