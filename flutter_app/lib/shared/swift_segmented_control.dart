import 'package:flutter/cupertino.dart';

import '../app/theme.dart';

/// 對照 SwiftUI 的膠囊分段選單；保留呼叫端既有選取行為。
class SwiftSegmentedControl<T> extends StatelessWidget {
  const SwiftSegmentedControl({
    required this.value,
    required this.labels,
    required this.onChanged,
    super.key,
  });
  final T value;
  final Map<T, String> labels;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) {
    final keys = labels.keys.toList();
    final index = keys.indexOf(value);
    return Container(
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.title.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              alignment: Alignment(
                keys.length <= 1 ? 0 : -1 + 2 * index / (keys.length - 1),
                0,
              ),
              child: Container(
                width: constraints.maxWidth / keys.length,
                height: 26,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A000000), blurRadius: 2),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                for (final key in keys)
                  Expanded(
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => onChanged(key),
                      child: Semantics(
                        selected: key == value,
                        child: Text(
                          labels[key]!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: CupertinoColors.label,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
