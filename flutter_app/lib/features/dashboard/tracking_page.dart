import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../core/storage/account_store.dart';
import '../../shared/widgets.dart';
import '../../shared/swift_menu_button.dart';
import '../../shared/swift_segmented_control.dart';
import '../diary/diary_page.dart';
import '../scales/scale_introductions.dart';
import 'controller.dart';
import 'models.dart';
import 'widgets.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({
    required this.controller,
    required this.store,
    super.key,
  });
  final DashboardController controller;
  final AccountStore store;
  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          const PageHeading('追蹤', subtitle: '查看你的健康數據與情緒變化'),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: SwiftSegmentedControl<int>(
                value: _tab,
                labels: const {1: '心情日記', 2: '量表追蹤', 0: '五項指標追蹤'},
                onChanged: (value) {
                  setState(() => _tab = value);
                  if (value == 2) widget.controller.loadScales();
                },
              ),
            ),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) => _tab == 1
                  ? DiaryPage(
                      controller: widget.controller,
                      store: widget.store,
                    )
                  : CustomScrollView(
                      slivers: [
                        CupertinoSliverRefreshControl(
                          onRefresh: _tab == 2
                              ? widget.controller.loadScales
                              : widget.controller.loadMetrics,
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          sliver: SliverList.list(
                            children: [
                              if (_tab == 0) ...[
                                if (widget.controller.errors['metrics'] != null)
                                  ErrorNotice(
                                    widget.controller.errors['metrics']!,
                                    onRetry: widget.controller.loadMetrics,
                                  ),
                                _WeeklyOverview(controller: widget.controller),
                                const SizedBox(height: 8),
                                ResponsivePair(
                                  first: IndicatorCard(
                                    records: widget.controller.records,
                                  ),
                                  second: ScoresCard(
                                    records: widget.controller.records,
                                  ),
                                ),
                              ] else ...[
                                if (widget.controller.errors['scales'] != null)
                                  ErrorNotice(
                                    widget.controller.errors['scales']!,
                                    onRetry: widget.controller.loadScales,
                                  ),
                                if (widget.controller.loading.contains(
                                  'scales',
                                ))
                                  const CupertinoActivityIndicator(),
                                ScaleTracking(
                                  records: widget.controller.scaleRecords,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WeeklyOverview extends StatelessWidget {
  const _WeeklyOverview({required this.controller});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) {
    final since = calendarDay(DateTime.now()).subtract(const Duration(days: 6));
    final records = controller.records
        .where((r) => !calendarDay(r.date).isBefore(since))
        .toList();
    return MindCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本週整體狀態', style: headingStyle),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final i in indicators)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.lightBrown.withValues(alpha: .35),
                        ),
                      ),
                      child: Builder(
                        builder: (context) {
                          final average = records.isEmpty
                              ? 0.0
                              : records.fold<int>(
                                      0,
                                      (sum, r) => sum + r.values[i.key]!,
                                    ) /
                                    records.length;
                          return Column(
                            children: [
                              Text(
                                '${i.label}${i.emoji}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                average.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                records.isEmpty
                                    ? '—'
                                    : average < 2.5
                                    ? '不好'
                                    : average < 3.5
                                    ? '一般'
                                    : '良好',
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '今日 ${controller.todayRecord?.values[i.key] ?? '—'}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScaleTracking extends StatefulWidget {
  const ScaleTracking({required this.records, super.key});
  final List<Map<String, dynamic>> records;
  @override
  State<ScaleTracking> createState() => _ScaleTrackingState();
}

class _ScaleTrackingState extends State<ScaleTracking> {
  String _code = '全部';
  @override
  Widget build(BuildContext context) {
    final scales = widget.records
        .where((e) => _code == '全部' || e['code'] == _code)
        .toList();
    final series = <TrendSeries>[];
    for (var i = 0; i < scales.length; i++) {
      final sessions =
          (scales[i]['sessions'] as List).cast<Map<String, dynamic>>().toList()
            ..sort(
              (a, b) => (b['createdAt'] as String).compareTo(
                a['createdAt'] as String,
              ),
            );
      final values = sessions
          .take(5)
          .toList()
          .reversed
          .map((e) => (e['totalScore'] as num).toDouble())
          .toList();
      series.add(
        TrendSeries(
          scales[i]['code'] as String,
          const [
            CupertinoColors.systemRed,
            CupertinoColors.systemBlue,
            CupertinoColors.systemGreen,
            CupertinoColors.systemOrange,
            CupertinoColors.systemPurple,
            CupertinoColors.systemTeal,
            CupertinoColors.systemPink,
            AppColors.mediumBrown,
          ][i % 8],
          [...values, ...List<double?>.filled(5 - values.length, null)],
        ),
      );
    }
    final maximum = math.max(
      5.0,
      series
          .expand((s) => s.values)
          .whereType<double>()
          .fold<double>(0, math.max),
    );
    final reference = _code == '全部'
        ? null
        : scaleQuestionCounts[_code] == null
        ? null
        : scaleQuestionCounts[_code]! * 3.0;
    final chartMax = (math.max(maximum, reference ?? 0) / 5).ceil() * 5.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightYellow,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('量表追蹤', style: headingStyle)),
              SwiftMenuButton(
                label: _code,
                dividerAfterFirst: true,
                accessibilityLabel: '選擇量表',
                options: [
                  '全部',
                  ...widget.records.map((e) => e['code'] as String),
                ],
                onSelected: (value) {
                  if (mounted) setState(() => _code = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final s in series)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
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
                            color: AppColors.title.withValues(alpha: .8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TrendChart(
            framed: true,
            height: 230,
            series: series,
            maximum: chartMax,
            referenceValue: reference,
            emptySubtitle: null,
            labels: List.generate(5, (i) => '第${i + 1}次'),
          ),
          const SizedBox(height: 12),
          for (final scale in widget.records)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _table(scale),
            ),
        ],
      ),
    );
  }

  Widget _table(Map<String, dynamic> scale) {
    final sessions =
        (scale['sessions'] as List).cast<Map<String, dynamic>>().toList()..sort(
          (a, b) =>
              (b['createdAt'] as String).compareTo(a['createdAt'] as String),
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBrown.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${scaleDisplayTitles[scale['code']] ?? scale['name']} (${scale['code']})',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 6),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '暫無資料',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.title.withValues(alpha: .6),
                ),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightYellow.withValues(alpha: .4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _cells('日期', '分數', header: true),
            ),
            for (final session in sessions.take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _cells(
                  dayKey(parseDate(session['createdAt']) ?? DateTime.now())
                      .substring(2),
                  '${session['totalScore']}',
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _cells(String left, String right, {bool header = false}) => Row(
    children: [
      for (final value in [left, right])
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: header ? FontWeight.w600 : FontWeight.normal,
              color: AppColors.title,
            ),
          ),
        ),
    ],
  );
}
