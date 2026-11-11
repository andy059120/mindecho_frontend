import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../auth/auth_widgets.dart';
import '../dashboard/controller.dart';
import '../dashboard/models.dart';
import '../dashboard/widgets.dart';

Future<void> showCheckIn(
  BuildContext context,
  DashboardController controller,
) => showCupertinoSheet<void>(
  context: context,
  scrollableBuilder: (_, _) => CheckInPage(controller: controller),
);

class CheckInPage extends StatefulWidget {
  const CheckInPage({required this.controller, super.key});
  final DashboardController controller;
  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  final _answers = List<int?>.filled(5, null);
  int _question = -1;
  bool _busy = false, _transition = false, _done = false;
  String? _error;
  Future<void> _select(int value) async {
    if (_busy || _transition) return;
    setState(() {
      _answers[_question] = value;
      _transition = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    setState(() => _transition = false);
    if (_question < 4) {
      setState(() => _question++);
    } else {
      await _submit();
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.submitCheckIn(_answers.cast<int>());
      if (mounted) setState(() => _done = true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: _done
        ? null
        : CupertinoNavigationBar(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.lightYellow,
            border: null,
            trailing: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(22),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '關閉',
                style: TextStyle(fontSize: 17, color: CupertinoColors.label),
              ),
            ),
          ),
    child: ContentFrame(
      maxWidth: 760,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: _done
                        ? _result()
                        : _question < 0
                        ? _intro()
                        : _questionView(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  List<Widget> _intro() => [
    const Spacer(),
    MindCard(
      padding: 24,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            const Text(
              '每日檢測',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '花一分鐘記錄今天的狀態，幫助你更好地了解自己的健康趨勢。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 32),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: AuthAction(
        '開始檢測',
        height: 52,
        onPressed: () => setState(() => _question = 0),
      ),
    ),
    const Spacer(),
  ];
  List<Widget> _questionView() => [
    const SizedBox(height: 20),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Container(
            height: 4,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (_question + 1) / 5,
                child: Container(color: AppColors.orange),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '問題${_question + 1}/5',
            style: const TextStyle(fontSize: 12, color: AppColors.orange),
          ),
        ],
      ),
    ),
    const Spacer(),
    const SizedBox(height: 24),
    MindCard(
      padding: 20,
      child: Column(
        children: [
          Text(
            _questions[_question].$1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _questions[_question].$2,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.title.withValues(alpha: .7),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              for (var i = 0; i < 5; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      onPressed: _busy || _transition
                          ? null
                          : () => _select(i + 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _answers[_question] == i + 1
                              ? AppColors.orange.withValues(alpha: .15)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              moods[i].emoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              moods[i].label,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.title,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_question > 0) ...[
            const SizedBox(height: 24),
            AuthAction(
              '上一題',
              secondary: true,
              height: 44,
              onPressed: _busy || _transition
                  ? null
                  : () => setState(() => _question--),
            ),
          ],
        ],
      ),
    ),
    if (_busy)
      const Padding(
        padding: EdgeInsets.all(20),
        child: CupertinoActivityIndicator(),
      ),
    if (_error != null) ...[
      const SizedBox(height: 20),
      Text(_error!, style: const TextStyle(color: CupertinoColors.systemRed)),
      const SizedBox(height: 12),
      AuthAction('重新送出', onPressed: _submit),
    ],
    const SizedBox(height: 24),
    const Spacer(),
  ];
  List<Widget> _result() {
    final overall = (_answers.cast<int>().reduce((a, b) => a + b) / 5).round();
    final color = overall >= 4
        ? CupertinoColors.systemGreen
        : overall == 3
        ? AppColors.orange
        : CupertinoColors.systemRed;
    final status = switch (overall) {
      5 => '極佳狀態',
      4 => '良好狀態',
      3 => '一般狀態',
      2 => '需要關注',
      _ => '需要調整',
    };
    return [
      const SizedBox(height: 32),
      const Text(
        '今日檢測完成！',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      Text(
        '已記錄到您的健康檔案',
        style: TextStyle(
          fontSize: 15,
          color: AppColors.title.withValues(alpha: .7),
        ),
      ),
      const Spacer(),
      const SizedBox(height: 24),
      MindCard(
        padding: 24,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('今日健康指數', style: headingStyle),
                  const SizedBox(height: 16),
                  for (final item in [
                    ('生理健康', 0),
                    ('精神狀態', 1),
                    ('情緒狀態', 2),
                    ('睡眠品質', 3),
                    ('飲食表現', 4),
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.$1,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Text(
                            '${_answers[item.$2]}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('綜合健康指數', style: headingStyle),
            const SizedBox(height: 20),
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _ScoreRing(overall / 5, color),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$overall',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      const SizedBox(height: 24),
      const Spacer(),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 40),
        child: AuthAction('進入首頁', onPressed: () => Navigator.pop(context)),
      ),
    ];
  }
}

class _ScoreRing extends CustomPainter {
  _ScoreRing(this.value, this.color);
  final double value;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawOval(
      rect,
      Paint()
        ..color = CupertinoColors.systemGrey.withValues(alpha: .2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * value,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRing old) =>
      old.value != value || old.color != color;
}

const _questions = [
  ('身體感覺有活力嗎？', '評估你的身體活力狀態'),
  ('今天心情如何？', '評估你的情緒狀態'),
  ('腦筋覺得靈活好使嗎？', '評估你的思緒清晰度'),
  ('這一夜的睡眠品質如何？', '評估你的睡眠品質'),
  ('今天的食慾如何？', '評估你的飲食狀態'),
];
