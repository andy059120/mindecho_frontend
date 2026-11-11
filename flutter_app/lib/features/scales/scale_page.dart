import 'package:flutter/cupertino.dart';

import '../../shared/system_symbol.dart';
import 'scale_introductions.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../shared/widgets.dart';
import '../auth/auth_widgets.dart';
import '../dashboard/controller.dart';
import '../dashboard/widgets.dart';

int scaleTotal(Map<String, dynamic> meta, List<int> answers) {
  final questions = (meta['questions'] as List).cast<Map<String, dynamic>>();
  final options = (meta['options'] as List)
      .cast<Map<String, dynamic>>()
      .map((e) => e['score'] as int)
      .toList();
  return List.generate(answers.length, (i) {
    final answer = answers[i];
    if (meta['code'] == 'AQ10') {
      return [1, 2, 9, 10].contains(i + 1)
          ? (answer <= 2 ? 1 : 0)
          : (answer >= 3 ? 1 : 0);
    }
    if (meta['code'] == 'BSS21' && i >= 19) return 0;
    return questions[i]['isReverse'] == true
        ? options.first + options.last - answer
        : answer;
  }).fold(0, (a, b) => a + b);
}

(int, int) rfqScores(List<int> answers) {
  final up = [0, 0, 0, 0, 1, 2, 3], down = [3, 2, 1, 0, 0, 0, 0];
  return (
    List.generate(6, (i) => up[answers[i]]).fold(0, (a, b) => a + b),
    [1, 3, 4, 5, 6, 7]
        .map((i) => i == 6 ? up[answers[i]] : down[answers[i]])
        .fold(0, (a, b) => a + b),
  );
}

Future<void> showScale(
  BuildContext context,
  Map<String, dynamic> meta,
  DashboardController controller,
) => showCupertinoSheet<void>(
  context: context,
  scrollableBuilder: (_, _) => ScalePage(meta: meta, controller: controller),
);

class ScalePage extends StatefulWidget {
  const ScalePage({required this.meta, required this.controller, super.key});
  final Map<String, dynamic> meta;
  final DashboardController controller;
  @override
  State<ScalePage> createState() => _ScalePageState();
}

class _ScalePageState extends State<ScalePage> {
  late final _questions = (widget.meta['questions'] as List)
      .cast<Map<String, dynamic>>();
  late final _options = (widget.meta['options'] as List)
      .cast<Map<String, dynamic>>();
  late final _answers = List<int?>.filled(_questions.length, null);
  int _index = 0;
  String _stage = 'intro';
  bool _busy = false;
  String? _error;
  Future<void> _submit() async {
    if (_busy || _answers.any((a) => a == null)) return;
    setState(() => _busy = true);
    try {
      await widget.controller.repository.auth.authorized(
        'POST',
        '/main/scales/${widget.meta['code']}/answers',
        body: {
          'userId': widget.controller.repository.userId,
          'answers': [
            for (var i = 0; i < _answers.length; i++)
              {'questionId': _questions[i]['id'], 'value': _answers[i]},
          ],
        },
      );
      await widget.controller.loadScales();
      if (mounted) setState(() => _stage = 'result');
    } catch (error) {
      if (mounted) setState(() => _error = '送出失敗，答案仍保留：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.lightYellow,
      border: null,
      middle: Text(
        _stage == 'intro' ? '測驗開始前' : widget.meta['title'] as String,
      ),
      trailing: textAction('取消', () => Navigator.pop(context), size: 17),
    ),
    child: ContentFrame(
      maxWidth: 760,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_stage == 'intro') ...[
              const Text(
                '測驗前說明',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.meta['title'] as String,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.title.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 20),
              _ScaleIntroduction(meta: widget.meta),
              if (widget.meta['code'] == 'RFQ8') ...[
                const SizedBox(height: 20),
                _section('安心提醒', widget.meta['sharedClosingText'] as String),
              ],
              const SizedBox(height: 24),
              AuthAction(
                '開始測驗',
                height: 50,
                onPressed: () => setState(() => _stage = 'questions'),
              ),
            ] else if (_stage == 'questions') ...[
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (_index + 1) / _questions.length,
                    child: Container(color: AppColors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '第 ${_index + 1} 題，共 ${_questions.length} 題',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
              Text(
                widget.meta['instructions'] as String,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 12),
              Text(_questions[_index]['text'] as String, style: headingStyle),
              const SizedBox(height: 24),
              for (final option in _options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CupertinoButton(
                    color: _answers[_index] == option['score']
                        ? AppColors.orange.withValues(alpha: .18)
                        : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.all(16),
                    onPressed: () => setState(() {
                      _answers[_index] = option['score'] as int;
                      if (_index < _questions.length - 1) {
                        _index++;
                      } else {
                        _stage = 'review';
                      }
                    }),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option['label'] as String,
                              style: const TextStyle(
                                color: AppColors.title,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(${option['score']}分)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.title.withValues(alpha: .6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: AuthAction(
                      '上一題',
                      onPressed: _index == 0
                          ? null
                          : () => setState(() => _index--),
                      secondary: true,
                      height: 46,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthAction(
                      _index == _questions.length - 1 ? '確認答案' : '下一題',
                      height: 46,
                      fontSize: 17,
                      onPressed: _answers[_index] == null
                          ? null
                          : () => setState(() {
                              if (_index < _questions.length - 1) {
                                _index++;
                              } else {
                                _stage = 'review';
                              }
                            }),
                    ),
                  ),
                ],
              ),
            ] else if (_stage == 'review') ...[
              const Text(
                '答案確認',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '送出前可點選任一題返回修改。',
                style: TextStyle(fontSize: 15, color: AppColors.mediumBrown),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _index = i;
                            _stage = 'questions';
                          }),
                    child: MindCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '第 ${i + 1} 題',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _questions[i]['text'] as String,
                            style: const TextStyle(color: AppColors.title),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _options.firstWhere(
                                  (o) => o['score'] == _answers[i],
                                )['label']
                                as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_error != null) ErrorNotice(_error!),
              Row(
                children: [
                  Expanded(
                    child: AuthAction(
                      '返回作答',
                      secondary: true,
                      height: 46,
                      onPressed: _busy
                          ? null
                          : () => setState(() => _stage = 'questions'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AuthAction(
                      '確認送出',
                      height: 46,
                      onPressed: _submit,
                      busy: _busy,
                    ),
                  ),
                ],
              ),
            ] else ...[
              MindCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.orange.withValues(alpha: .15),
                          ),
                          child: const SystemSymbol(
                            'checkmark.seal.fill',
                            size: 22,
                            color: AppColors.orange,
                            fallback: CupertinoIcons.checkmark_seal_fill,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '量表完成',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '已記錄您的作答',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.title.withValues(alpha: .7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.meta['code'] != 'RFQ8')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightYellow,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.lightBrown.withValues(alpha: .35),
                          ),
                        ),
                        child: Text(
                          '總分 ${scaleTotal(widget.meta, _answers.cast<int>())}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _section(
                '測驗結果',
                widget.meta['code'] == 'RFQ8'
                    ? 'RFQ-C：${rfqScores(_answers.cast<int>()).$1}\nRFQ-U：${rfqScores(_answers.cast<int>()).$2}'
                    : '本次總分 ${scaleTotal(widget.meta, _answers.cast<int>())}',
              ),
              if (widget.meta['code'] != 'RFQ8') ...[
                const SizedBox(height: 20),
                _section('測驗結果解釋', _feedback()),
              ],
              const SizedBox(height: 20),
              _section(
                '分數意義',
                '以上回饋僅反映你近期一段時間的狀態，並非診斷。你可持續檢測，觀察自己的變化。',
                tinted: true,
              ),
              const SizedBox(height: 20),
              _section(
                '提醒您',
                '無論結果如何，你的感受都是真實且值得被重視的。理解自己，是改變與照顧自己的第一步。',
                tinted: true,
              ),
              const SizedBox(height: 26),
              AuthAction(
                '返回',
                height: 50,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  Widget _section(String title, String copy, {bool tinted = false}) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tinted ? AppColors.lightYellow : CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.lightBrown.withValues(alpha: .25),
          ),
          boxShadow: tinted
              ? null
              : const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: headingStyle),
            const SizedBox(height: 8),
            Text(
              copy,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppColors.title.withValues(alpha: .85),
              ),
            ),
          ],
        ),
      );
  String _feedback() {
    final ranges = (widget.meta['ranges'] as List).cast<int>();
    final total = scaleTotal(widget.meta, _answers.cast<int>());
    return (widget.meta['feedback'] as Map<String, dynamic>)[total <= ranges[0]
            ? 'low'
            : total <= ranges[1]
            ? 'medium'
            : 'high']
        as String;
  }
}

class _ScaleIntroduction extends StatelessWidget {
  const _ScaleIntroduction({required this.meta});
  final Map<String, dynamic> meta;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.lightBrown.withValues(alpha: .25)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${meta['title']} 簡介', style: headingStyle),
        const SizedBox(height: 8),
        Text(
          scaleIntroductions[meta['code']] ?? '',
          style: TextStyle(
            fontSize: 15,
            height: 1.4,
            color: AppColors.title.withValues(alpha: .85),
          ),
        ),
      ],
    ),
  );
}
