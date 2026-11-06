import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../core/platform/local_media_store.dart';
import '../../core/storage/account_store.dart';
import '../../shared/system_symbol.dart';
import '../../shared/widgets.dart';
import '../auth/auth_widgets.dart';
import '../check_in/check_in_page.dart';
import '../diary/diary_page.dart';
import '../profile/treasure_page.dart';
import '../resources/resources_page.dart';
import '../scales/scale_page.dart';
import 'catalog.dart';
import 'controller.dart';
import 'models.dart';
import 'widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    required this.controller,
    required this.store,
    required this.media,
    required this.catalog,
    required this.onTour,
    super.key,
  });
  final DashboardController controller;
  final AccountStore store;
  final LocalMediaStore media;
  final DashboardCatalog catalog;
  final VoidCallback onTour;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: controller.refresh),
            SliverList.list(
              children: [
                PageHeading(
                  '首頁',
                  top: 8,
                  trailing: textAction('功能介紹', onTour, size: 15),
                ),
                if (controller.errors['metrics'] != null)
                  ErrorNotice(
                    controller.errors['metrics']!,
                    onRetry: controller.loadMetrics,
                  ),
                if (controller.loading.contains('metrics'))
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CupertinoActivityIndicator(),
                  ),
                _padding(
                  ResponsivePair(
                    first: IndicatorCard(records: controller.records),
                    second: ScoresCard(records: controller.records),
                  ),
                  top: 8,
                ),
                _padding(QuoteCard(quotes: catalog.quotes), top: 16),
                if (!controller.completedToday)
                  _padding(
                    _Reminder(
                      title: '今日健康檢測',
                      subtitle: '花1分鐘記錄今天的身心狀態',
                      button: '開始檢測',
                      symbol: 'heart.circle.fill',
                      onTap: () => showCheckIn(context, controller),
                    ),
                    top: 16,
                  ),
                if (controller.diaryOn(DateTime.now()) == null &&
                    !controller.loading.contains('diary') &&
                    controller.errors['diary'] == null)
                  _padding(
                    _Reminder(
                      title: '今日心情日記',
                      subtitle: '花1分鐘記錄今天的心情',
                      button: '前往日記',
                      symbol: 'book.closed.fill',
                      onTap: () => showCupertinoSheet<void>(
                        context: context,
                        scrollableBuilder: (sheetContext, _) =>
                            CupertinoPageScaffold(
                              navigationBar: CupertinoNavigationBar(
                                middle: const Text('心情日記'),
                                trailing: textAction(
                                  '關閉',
                                  () => Navigator.pop(sheetContext),
                                ),
                              ),
                              child: SafeArea(
                                child: DiaryPage(
                                  controller: controller,
                                  store: store,
                                ),
                              ),
                            ),
                      ),
                    ),
                    top: 16,
                  ),
                const SizedBox(height: 44),
                _section('進一步瞭解自己'),
                _padding(TestGuide(meta: catalog.scales.firstOrNull), top: 12),
                const SizedBox(height: 12),
                ResponsiveShelf(
                  itemHeight: 180,
                  itemCount: catalog.scales.length,
                  itemBuilder: (context, index) {
                    final meta = catalog.scales[index];
                    return _ScaleTile(
                      meta: meta,
                      onTap: () => showScale(context, meta, controller),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _section('我的重要時刻'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ResourceTile(
                      title: '時光寶盒',
                      subtitle: '整理情緒與收集力量',
                      symbol: 'suitcase.fill',
                      button: '前往查看',
                      color: const Color(0xFFFAE6B3),
                      onTap: () => showTreasure(context, media),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _section('求助資源'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      for (final resource in [
                        (
                          'hotline',
                          '24 小時求助資源',
                          '查看心理諮詢熱線、免費協談專線與其他求助管道',
                          'phone.connection.fill',
                          '查看資源',
                        ),
                        (
                          'techniques',
                          '情緒管理小技巧',
                          '如果感到難受或焦慮，你可以試著這樣做......',
                          'heart.circle.fill',
                          '查看更多',
                        ),
                        (
                          'relax',
                          '放鬆訓練',
                          '透過呼吸與冥想，幫助自己慢慢穩定下來',
                          'leaf.fill',
                          '開始練習',
                        ),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: _ResourceTile(
                            title: resource.$2,
                            subtitle: resource.$3,
                            symbol: resource.$4,
                            button: resource.$5,
                            color: const Color(0xFFFAE6B3),
                            onTap: () =>
                                showResource(context, resource.$1, catalog),
                          ),
                        ),
                    ],
                  ),
                ),
                _padding(
                  DiaryEditor(
                    key: ValueKey('home.diary.${dayKey(DateTime.now())}'),
                    controller: controller,
                    store: store,
                    date: DateTime.now(),
                    compact: true,
                  ),
                  top: 20,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  Widget _padding(Widget child, {double top = 0}) =>
      Padding(padding: EdgeInsets.fromLTRB(16, top, 16, 0), child: child);
  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(title, style: headingStyle),
  );
}

class _Reminder extends StatelessWidget {
  const _Reminder({
    required this.title,
    required this.subtitle,
    required this.button,
    required this.symbol,
    required this.onTap,
  });
  final String title, subtitle, button, symbol;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = title == '今日健康檢測'
        ? AppColors.orange
        : const Color(0xFFCC661A);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: .8)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 4)],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SystemSymbol(
                        symbol,
                        size: 22,
                        color: CupertinoColors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      color: CupertinoColors.white.withValues(alpha: .9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        button,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const SystemSymbol(
                        'arrow.right.circle.fill',
                        size: 15,
                        color: CupertinoColors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SystemSymbol(
              title == '今日健康檢測' ? 'list.clipboard.fill' : 'pencil.and.outline',
              size: 40,
              color: CupertinoColors.white.withValues(alpha: .8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleTile extends StatelessWidget {
  const _ScaleTile({required this.meta, required this.onTap});
  final Map<String, dynamic> meta;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    width: 160,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFAF0CC), Color(0xFFF2E08C), Color(0xFFF4E6A3)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SystemSymbol(
          meta['icon'] as String,
          size: 22,
          color: AppColors.darkBrown,
        ),
        const SizedBox(height: 6),
        Text(
          meta['title'] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          meta['subtitle'] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: AppColors.darkBrown),
        ),
        const Spacer(),
        Row(
          children: [
            const SystemSymbol(
              'clock',
              size: 8,
              color: AppColors.darkBrown,
              fallback: CupertinoIcons.clock,
            ),
            const SizedBox(width: 4),
            Text(
              '${(meta['count'] / 2).ceil()}分鐘',
              style: const TextStyle(fontSize: 10, color: AppColors.darkBrown),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const SystemSymbol(
              'questionmark.circle',
              size: 8,
              color: AppColors.darkBrown,
              fallback: CupertinoIcons.question_circle,
            ),
            const SizedBox(width: 4),
            Text(
              '${meta['count']}題',
              style: const TextStyle(fontSize: 10, color: AppColors.darkBrown),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AuthAction('開始測驗', height: 30, fontSize: 11, onPressed: onTap),
      ],
    ),
  );
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.title,
    required this.subtitle,
    required this.symbol,
    required this.button,
    required this.color,
    required this.onTap,
  });
  final String title, subtitle, symbol, button;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: button == '前往查看'
                ? [color, const Color(0xFFF2A659), const Color(0xFFE9975C)]
                : [
                    Color.alphaBlend(
                      color.withValues(alpha: .6),
                      AppColors.lightYellow,
                    ),
                    Color.alphaBlend(
                      const Color(0xFFF2A659).withValues(alpha: .6),
                      AppColors.lightYellow,
                    ),
                    Color.alphaBlend(
                      AppColors.orange.withValues(alpha: .6),
                      AppColors.lightYellow,
                    ),
                  ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SystemSymbol(
              symbol,
              size: 22,
              color: AppColors.darkBrown,
              fallback: CupertinoIcons.heart_fill,
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.darkBrown.withValues(alpha: .7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkBrown,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                button,
                style: const TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class TestGuide extends StatefulWidget {
  const TestGuide({this.meta, super.key});
  final Map<String, dynamic>? meta;
  @override
  State<TestGuide> createState() => _TestGuideState();
}

class _TestGuideState extends State<TestGuide> {
  bool _open = false;
  @override
  Widget build(BuildContext context) => MindCard(
    padding: 14,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () => setState(() => _open = !_open),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.info_circle_fill,
                size: 17,
                color: AppColors.orange,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '測驗說明',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.title,
                  ),
                ),
              ),
              Icon(
                _open ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                size: 14,
                color: AppColors.title,
              ),
            ],
          ),
        ),
        if (_open) ...[
          const SizedBox(height: 12),
          Text(
            widget.meta?['sharedOverviewText'] as String? ?? '',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            widget.meta?['sharedClosingText'] as String? ?? '',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ],
    ),
  );
}

class QuoteCard extends StatefulWidget {
  const QuoteCard({required this.quotes, super.key});
  final List<Map<String, dynamic>> quotes;
  @override
  State<QuoteCard> createState() => _QuoteCardState();
}

class _QuoteCardState extends State<QuoteCard>
    with SingleTickerProviderStateMixin {
  late final _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final _wheel = ([...widget.quotes]..shuffle()).take(12).toList();
  Map<String, dynamic>? _selected;
  double _from = 0, _to = 0;
  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  Future<void> _choose() async {
    if (_spin.isAnimating || _wheel.isEmpty) return;
    _from = _to;
    _to +=
        (3 + math.Random().nextInt(4)) * math.pi * 2 +
        math.Random().nextDouble() * math.pi * 2;
    await _spin.forward(from: 0);
    if (mounted) {
      setState(
        () => _selected =
            _wheel[((_to % (math.pi * 2)) / (math.pi * 2 / _wheel.length))
                    .floor() %
                _wheel.length],
      );
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: _choose,
    child: Container(
      height: 296,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(const Color(0x26FFFF00), AppColors.lightYellow),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withValues(alpha: .2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '今日箴言',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.mediumBrown,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _spin,
                  builder: (context, _) => Transform.rotate(
                    angle:
                        _from +
                        (_to - _from) * Curves.easeOut.transform(_spin.value),
                    child: CustomPaint(
                      size: const Size(110, 110),
                      painter: _WheelPainter(_wheel.length),
                    ),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFD173), Color(0xFFF59933)],
                    ),
                    border: Border.all(
                      color: CupertinoColors.white.withValues(alpha: .8),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 6,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    '按我',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _selected!['title'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.title,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _selected!['content'] as String,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, color: AppColors.title),
            ),
          ],
        ],
      ),
    ),
  );
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.count);
  final int count;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        radius = size.width / 2;
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFAE6B3));
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..color = CupertinoColors.white.withValues(alpha: .8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    for (var i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count - math.pi / 2;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 15),
        center + Offset(math.cos(angle), math.sin(angle)) * (radius - 5),
        Paint()
          ..color = CupertinoColors.white.withValues(alpha: .5)
          ..strokeWidth = 2,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 6, 3)
        ..lineTo(center.dx + 6, 3)
        ..lineTo(center.dx, 15)
        ..close(),
      Paint()..color = AppColors.title,
    );
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.count != count;
}
