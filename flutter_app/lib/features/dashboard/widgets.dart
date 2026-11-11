import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/system_symbol.dart';
import '../../shared/swift_menu_button.dart';
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
    this.chartStyle = false,
    super.key,
  });
  final Widget child;
  final double padding;
  final Color color;
  final bool chartStyle;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(chartStyle ? 12 : 16),
      boxShadow: [
        BoxShadow(
          color: Color(0x19000000),
          blurRadius: chartStyle ? 4 : 8,
          offset: chartStyle ? Offset.zero : const Offset(0, 2),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final spacious = constraints.maxWidth >= 600;
      final titleWidget = Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'CupertinoSystemDisplay',
          fontSize: spacious ? 28 : 22,
          height: 1.25,
          fontWeight: FontWeight.bold,
          color: AppColors.title,
        ),
      );
      return Padding(
        padding: EdgeInsets.fromLTRB(16, spacious ? top + 8 : top, 16, 12),
        child: Column(
          crossAxisAlignment: spacious
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (spacious)
              Row(
                children: [
                  Expanded(child: titleWidget),
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: trailing!,
                    ),
                ],
              )
            else
              SizedBox(
                height: math.max(
                  44,
                  MediaQuery.textScalerOf(context).scale(22) * 2.5,
                ),
                child: NavigationToolbar(
                  centerMiddle: true,
                  middle: titleWidget,
                  trailing: trailing,
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: spacious ? TextAlign.start : TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.title.withValues(alpha: .7),
                ),
              ),
            ],
          ],
        ),
      );
    },
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
    this.framed = false,
    this.emphasizeSeries = false,
    super.key,
  });
  final List<TrendSeries> series;
  final List<String> labels;
  final double maximum, minimum, height;
  final String? emptySubtitle;
  final double? referenceValue;
  final bool framed, emphasizeSeries;
  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selected;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        padding: widget.framed ? const EdgeInsets.all(8) : EdgeInsets.zero,
        decoration: widget.framed
            ? BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.lightBrown.withValues(alpha: .4),
                ),
              )
            : null,
        child: LayoutBuilder(
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
                      widget.framed,
                      widget.emphasizeSeries,
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
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Row(
          children: [
            for (final label in widget.labels)
              Expanded(
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: AppColors.title,
                      ),
                    ),
                  ),
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
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              color: AppColors.title.withValues(alpha: .6),
            ),
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
    this.framed,
    this.emphasizeSeries,
  );
  final List<TrendSeries> series;
  final double maximum, minimum;
  final double? referenceValue;
  final int? selected;
  final bool framed, emphasizeSeries;
  @override
  void paint(Canvas canvas, Size size) {
    const left = 32.0, right = 25.0;
    final top = framed ? 14.0 : 0.0;
    final bottom = framed ? 2.0 : 0.0;
    final plotHeight = size.height - top - bottom;
    double yFor(double value) =>
        top + plotHeight * (1 - (value - minimum) / (maximum - minimum));
    for (var i = 0; i < 5; i++) {
      final value = maximum - i * (maximum ~/ 4);
      final y = yFor(value);
      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        Paint()
          ..color = const Color(0x1A808080)
          ..strokeWidth = .5,
      );
      final painter = TextPainter(
        text: TextSpan(
          text: value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            color: AppColors.title.withValues(alpha: .6),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          (left - painter.width) / 2,
          (y - painter.height / 2).clamp(0, size.height - painter.height),
        ),
      );
    }
    if (referenceValue != null) {
      final y = yFor(referenceValue!);
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
          yFor(value),
        );
        if (connected) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
        }
        connected = true;
        canvas.drawCircle(
          point,
          selected == i
              ? 5
              : emphasizeSeries
              ? 2.5
              : 2,
          Paint()..color = s.color,
        );
      }
      if (emphasizeSeries) {
        for (var i = 0; i < s.values.length; i++) {
          final value = s.values[i];
          if (value == null) continue;
          final label = TextPainter(
            text: TextSpan(
              text: value % 1 == 0
                  ? '${value.toInt()}'
                  : value.toStringAsFixed(1),
              style: TextStyle(fontSize: 11, height: 1.2, color: s.color),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final x =
              left +
              (size.width - left - right) *
                  i /
                  math.max(1, s.values.length - 1);
          label.paint(
            canvas,
            Offset(
              x - label.width / 2,
              math.max(0, yFor(value) - 12 - label.height / 2),
            ),
          );
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = emphasizeSeries ? 3 : 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
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
      chartStyle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '五項指標追蹤',
                  style: headingStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              SwiftMenuButton(
                label: _indicator,
                dividerAfterFirst: true,
                symbol: 'line.3.horizontal.decrease',
                accessibilityLabel: '選擇指標',
                options: ['顯示全部', ...indicators.map((e) => e.label)],
                onSelected: (value) {
                  if (mounted) {
                    setState(() => _indicator = value == '顯示全部' ? '全部' : value);
                  }
                },
              ),
              const SizedBox(width: 12),
              SwiftMenuButton(
                label: _period,
                accessibilityLabel: '時間週期',
                options: ['本週', '最近七週', '最近七月', '最近三年半'],
                onSelected: (value) {
                  if (mounted) setState(() => _period = value);
                },
              ),
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
                    Text(
                      s.label,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.2,
                        color: AppColors.title.withValues(alpha: .8),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SystemSymbol(
                'info.circle',
                size: 11,
                color: AppColors.title.withValues(alpha: .55),
                fallback: CupertinoIcons.info_circle,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _indicator == '全部'
                      ? '右上角的「全部」可切換成單一指標檢視'
                      : '可從右上角切換回全部或改看其他指標',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: AppColors.title.withValues(alpha: .55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) => TrendChart(
              height: (constraints.maxWidth * .28).clamp(200.0, 320.0),
              emphasizeSeries: _indicator != '全部',
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
      chartStyle: true,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '每日檢測紀錄',
                  style: headingStyle.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
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
              SwiftMenuButton(
                label: _period,
                filled: true,
                accessibilityLabel: '平均區間',
                options: ['這週', '這月', '這季', '這半年', '這年'],
                onSelected: (value) {
                  if (mounted) setState(() => _period = value);
                },
              ),
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
