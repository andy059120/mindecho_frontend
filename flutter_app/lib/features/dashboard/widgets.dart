import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/system_symbol.dart';
import 'models.dart';

const headingStyle = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w600,
  color: AppColors.title,
);

class MindCard extends StatelessWidget {
  const MindCard({
    required this.child,
    this.padding = 16,
    this.color = CupertinoColors.white,
    super.key,
  });
  final Widget child;
  final double padding;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.title, {
    this.subtitle,
    this.trailing,
    this.top = 16,
    super.key,
  });
  final String title;
  final double top;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, top, 20, subtitle == null ? 12 : 0),
    child: Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: double.infinity,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'CupertinoSystemDisplay',
                  fontSize: 22,
                  height: 1.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.title,
                ),
              ),
            ),
            if (trailing != null)
              Align(alignment: Alignment.centerRight, child: trailing!),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 15,
              height: 1.2,
              color: AppColors.title.withValues(alpha: .7),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget textAction(
  String label,
  VoidCallback? onPressed, {
  Color color = AppColors.orange,
  double size = 12,
}) => CupertinoButton(
  padding: EdgeInsets.zero,
  minimumSize: Size.zero,
  onPressed: onPressed,
  child: Text(
    label,
    style: TextStyle(fontSize: size, color: color),
  ),
);
Future<String?> choose(
  BuildContext context,
  String title,
  List<String> options,
) => showCupertinoModalPopup<String>(
  context: context,
  builder: (context) => CupertinoActionSheet(
    title: Text(title),
    actions: [
      for (final option in options)
        CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context, option),
          child: Text(option),
        ),
    ],
    cancelButton: CupertinoActionSheetAction(
      onPressed: () => Navigator.pop(context),
      child: const Text('取消'),
    ),
  ),
);

class TrendSeries {
  const TrendSeries(this.label, this.color, this.values);
  final String label;
  final Color color;
  final List<double?> values;
}

class TrendChart extends StatefulWidget {
  const TrendChart({
    required this.series,
    required this.labels,
    this.maximum = 5,
    this.minimum = 0,
    this.height = 200,
    this.emptySubtitle = '完成每日檢測後查看趨勢',
    this.referenceValue,
    super.key,
  });
  final List<TrendSeries> series;
  final List<String> labels;
  final double maximum, minimum, height;
  final String? emptySubtitle;
  final double? referenceValue;
  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selected;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          onTapDown: (details) => setState(
            () => _selected =
                ((details.localPosition.dx - 32) /
                        math.max(1, constraints.maxWidth - 57) *
                        math.max(1, widget.labels.length - 1))
                    .round()
                    .clamp(0, math.max(0, widget.labels.length - 1)),
          ),
          child: SizedBox(
            height: widget.height,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, widget.height),
                  painter: _TrendPainter(
                    widget.series,
                    widget.maximum,
                    widget.minimum,
                    _selected,
                    widget.referenceValue,
                  ),
                ),
                if (!widget.series.any((s) => s.values.any((v) => v != null)))
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SystemSymbol(
                        'chart.line.uptrend.xyaxis',
                        size: 40,
                        color: AppColors.title.withValues(alpha: .3),
                        fallback: CupertinoIcons.chart_bar,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '暫無數據',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.title.withValues(alpha: .6),
                        ),
                      ),
                      if (widget.emptySubtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.emptySubtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.title.withValues(alpha: .5),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 26, right: 20, top: 4),
        child: Row(
          children: [
            for (final label in widget.labels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: AppColors.title),
                ),
              ),
          ],
        ),
      ),
      if (_selected != null && widget.labels.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${widget.labels[_selected!]}  ${widget.series.map((s) => '${s.label}：${_selected! < s.values.length ? s.values[_selected!]?.toStringAsFixed(1) ?? '—' : '—'}').join('  ')}',
            style: const TextStyle(fontSize: 11, color: AppColors.title),
          ),
        ),
    ],
  );
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(
    this.series,
    this.maximum,
    this.minimum,
    this.selected,
    this.referenceValue,
  );
  final List<TrendSeries> series;
  final double maximum, minimum;
  final double? referenceValue;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0, right = 25.0;
    for (var i = 0; i < 5; i++) {
      final value = maximum - i * (maximum ~/ 4);
      final y =
          8 +
          (size.height - 16) * (1 - (value - minimum) / (maximum - minimum));
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        Paint()
          ..color = const Color(0x18000000)
          ..strokeWidth = .5,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1),
          style: const TextStyle(fontSize: 11, color: AppColors.title),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(4, y - painter.height / 2));
    }
    if (referenceValue != null) {
      final y =
          8 +
          (size.height - 16) *
              (1 - (referenceValue! - minimum) / (maximum - minimum));
      for (double x = left; x < size.width - right; x += 10) {
        canvas.drawLine(
          Offset(x, y),
          Offset(math.min(x + 6, size.width - right), y),
          Paint()
            ..color = CupertinoColors.systemRed
            ..strokeWidth = 1.5,
        );
      }
    }
    for (final s in series) {
      final path = Path();
      var connected = false;
      for (var i = 0; i < s.values.length; i++) {
        final value = s.values[i];
        if (value == null) {
          connected = false;
          continue;
        }
        final point = Offset(
          left +
              (size.width - left - right) *
                  i /
                  math.max(1, s.values.length - 1),
          8 +
              (size.height - 16) *
                  (1 - (value - minimum) / (maximum - minimum)),
        );
        if (connected) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
        }
        connected = true;
        canvas.drawCircle(
          point,
          selected == i ? 5 : 3,
          Paint()..color = s.color,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => true;
}

List<DateTime> trendStarts(String period, DateTime today) =>
    List.generate(7, (i) {
      final offset = 6 - i;
      return switch (period) {
        '最近七週' => calendarDay(today).subtract(Duration(days: offset * 7)),
        '最近七月' => DateTime(today.year, today.month - offset),
        '最近三年半' => DateTime(today.year, today.month - offset * 6),
        _ => calendarDay(today).subtract(Duration(days: offset)),
      };
    });
List<TrendSeries> aggregateTrends(
  List<DailyRecord> records,
  String period,
  DateTime today,
) {
  final starts = trendStarts(period, today);
  return [
    for (final indicator in indicators)
      TrendSeries(indicator.label, indicator.color, [
        for (final start in starts)
          _average(
            records.where((r) {
              final date = calendarDay(r.date);
              final end = switch (period) {
                '最近七週' => start.add(const Duration(days: 7)),
                '最近七月' => DateTime(start.year, start.month + 1),
                '最近三年半' => DateTime(start.year, start.month + 6),
                _ => start.add(const Duration(days: 1)),
              };
              return !date.isBefore(start) && date.isBefore(end);
            }),
            indicator.key,
          ),
      ]),
  ];
}

double? _average(Iterable<DailyRecord> records, String key) {
  final list = records.toList();
  return list.isEmpty
      ? null
      : list.fold<int>(0, (sum, r) => sum + r.values[key]!) / list.length;
}

class IndicatorCard extends StatefulWidget {
  const IndicatorCard({required this.records, super.key});
  final List<DailyRecord> records;
  @override
  State<IndicatorCard> createState() => _IndicatorCardState();
}

class _IndicatorCardState extends State<IndicatorCard> {
  String _period = '本週', _indicator = '全部';
  @override
  Widget build(BuildContext context) {
    final series = aggregateTrends(widget.records, _period, DateTime.now());
    final shown = series
        .where((s) => _indicator == '全部' || s.label == _indicator)
        .toList();
    final starts = trendStarts(_period, DateTime.now());
    return MindCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('五項指標追蹤', style: headingStyle)),
              textAction('$_indicator ☰', () async {
                final value = await choose(context, '選擇指標', [
                  '全部',
                  ...indicators.map((e) => e.label),
                ]);
                if (value != null && mounted) {
                  setState(() => _indicator = value);
                }
              }, color: AppColors.title),
              const SizedBox(width: 12),
              textAction('$_period ⌄', () async {
                final value = await choose(context, '時間週期', [
                  '本週',
                  '最近七週',
                  '最近七月',
                  '最近三年半',
                ]);
                if (value != null && mounted) setState(() => _period = value);
              }, color: AppColors.title),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final s in shown)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.color,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(s.label, style: const TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'ⓘ 右上角的「全部」可切換成單一指標檢視',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.title.withValues(alpha: .55),
            ),
          ),
          const SizedBox(height: 8),
          TrendChart(
            minimum: 1,
            series: shown,
            labels: starts
                .map(
                  (d) => _period == '最近七月' || _period == '最近三年半'
                      ? '${d.year}\n${d.month}月'
                      : _period == '本週'
                      ? const [
                          'Mon',
                          'Tue',
                          'Wed',
                          'Thu',
                          'Fri',
                          'Sat',
                          'Sun',
                        ][d.weekday - 1]
                      : '${d.month}/${d.day}',
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class ScoresCard extends StatefulWidget {
  const ScoresCard({required this.records, super.key});
  final List<DailyRecord> records;
  @override
  State<ScoresCard> createState() => _ScoresCardState();
}

class _ScoresCardState extends State<ScoresCard> {
  String _period = '這週';
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = switch (_period) {
      '這月' => DateTime(now.year, now.month),
      '這季' => DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1),
      '這半年' => DateTime(now.year, now.month <= 6 ? 1 : 7),
      '這年' => DateTime(now.year),
      _ => calendarDay(now).subtract(Duration(days: now.weekday - 1)),
    };
    final filtered =
        widget.records
            .where((r) => !calendarDay(r.date).isBefore(start))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return MindCard(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('每日檢測紀錄', style: headingStyle)),
              if (widget.records.isNotEmpty)
                textAction(
                  '查看全部',
                  () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => CupertinoPageScaffold(
                        navigationBar: const CupertinoNavigationBar(
                          middle: Text('每日檢測紀錄'),
                        ),
                        child: SafeArea(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              for (final r in widget.records)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: MindCard(child: _scoreRow(r)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('平均區間', style: TextStyle(fontSize: 12)),
              const Spacer(),
              textAction('$_period ⌄', () async {
                final value = await choose(context, '平均區間', [
                  '這週',
                  '這月',
                  '這季',
                  '這半年',
                  '這年',
                ]);
                if (value != null && mounted) setState(() => _period = value);
              }, color: AppColors.title),
            ],
          ),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '暫無資料',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.title.withValues(alpha: .6),
                ),
              ),
            )
          else ...[
            const SizedBox(height: 8),
            _cells(['日期', ...indicators.map((i) => i.label)], header: true),
            for (final record in filtered.take(7)) _scoreRow(record),
            Container(height: .5, color: CupertinoColors.separator),
            _cells([
              '$_period平均',
              for (final i in indicators)
                (filtered.fold<int>(0, (sum, r) => sum + r.values[i.key]!) /
                        filtered.length)
                    .toStringAsFixed(1),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _scoreRow(DailyRecord r) => _cells([
    '${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}',
    for (final i in indicators) '${r.values[i.key]}',
  ]);
  Widget _cells(List<String> values, {bool header = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: header ? AppColors.lightYellow.withValues(alpha: .4) : null,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      children: [
        for (final v in values)
          Expanded(
            child: Text(
              v,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: header ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
      ],
    ),
  );
}
