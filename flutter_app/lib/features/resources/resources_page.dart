import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/system_symbol.dart';
import '../dashboard/catalog.dart';
import '../dashboard/widgets.dart';
import '../profile/profile_page.dart';
import 'resource_sections.dart';

Future<void> showResource(
  BuildContext context,
  String kind,
  DashboardCatalog catalog,
) => showCupertinoSheet<void>(
  context: context,
  scrollableBuilder: (_, controller) =>
      ResourcePage(kind: kind, catalog: catalog, scrollController: controller),
);

class ResourcePage extends StatefulWidget {
  const ResourcePage({
    required this.kind,
    required this.catalog,
    this.scrollController,
    super.key,
  });
  final String kind;
  final DashboardCatalog catalog;
  final ScrollController? scrollController;
  @override
  State<ResourcePage> createState() => _ResourcePageState();
}

class _ResourcePageState extends State<ResourcePage> {
  String _section = '呼吸放鬆';
  @override
  Widget build(BuildContext context) {
    final relax = widget.kind == 'relax';
    final title = widget.kind == 'techniques' ? '情緒管理小技巧' : '心理諮詢熱線';
    return CupertinoPageScaffold(
      navigationBar: relax
          ? null
          : CupertinoNavigationBar(
              automaticallyImplyLeading: false,
              middle: Text(title),
              backgroundColor: AppColors.lightYellow,
              border: null,
              trailing: textAction(
                '關閉',
                () => Navigator.pop(context),
                size: 17,
              ),
            ),
      child: SafeArea(
        child: relax
            ? _relax()
            : ListView(
                controller: widget.scrollController,
                padding: const EdgeInsets.all(16),
                children: widget.kind == 'techniques'
                    ? _techniques()
                    : _hotlines(),
              ),
      ),
    );
  }

  Widget _surface(Widget child, {double padding = 16}) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [BoxShadow(color: Color(0x19000000), blurRadius: 2)],
    ),
    child: child,
  );
  List<Widget> _techniques() => [
    const Center(
      child: SystemSymbol(
        'heart.circle.fill',
        size: 80,
        color: AppColors.title,
        fallback: CupertinoIcons.heart_circle_fill,
      ),
    ),
    const SizedBox(height: 20),
    const Text(
      '情緒管理小技巧',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.title,
      ),
    ),
    const SizedBox(height: 20),
    for (final technique
        in (widget.catalog.resources['techniques'] as List? ?? [])
            .cast<Map<String, dynamic>>()) ...[
      _surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: SystemSymbol(
                    technique['symbol'] as String,
                    size: 28,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(technique['title'] as String, style: headingStyle),
                      const SizedBox(height: 4),
                      Text(
                        technique['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.title.withValues(alpha: .7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < (technique['steps'] as List).length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      child: Text(
                        '${i + 1}.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (technique['steps'] as List)[i] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ],
    _surface(
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 使用建議', style: headingStyle),
          SizedBox(height: 12),
          Text(
            '• 選擇適合自己的技巧定期練習\n• 在情緒平穩時先學習技巧\n• 持續練習才能見到效果\n• 結合多種技巧效果更佳',
            style: TextStyle(fontSize: 17, height: 1.5, color: AppColors.title),
          ),
        ],
      ),
    ),
  ];
  List<Widget> _hotlines() => [
    _surface(
      Column(
        children: [
          const SystemSymbol(
            'phone.circle.fill',
            size: 80,
            color: AppColors.title,
            fallback: CupertinoIcons.phone_circle_fill,
          ),
          const SizedBox(height: 12),
          const Text(
            '24 小時心理諮詢與求助資源',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '遇到危急情況請優先撥打 112、119 或 110，其他專線與網站可依需求尋求協助。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: AppColors.title.withValues(alpha: .8),
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    for (final section in resourceSections) ...[
      _surface(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SystemSymbol(
                  section['icon'] as String,
                  size: 17,
                  color: AppColors.title,
                ),
                const SizedBox(width: 10),
                Text(section['title'] as String, style: headingStyle),
              ],
            ),
            const SizedBox(height: 12),
            for (final resource
                in (widget.catalog.resources['hotlines'] as List? ?? [])
                    .cast<Map<String, dynamic>>()
                    .where(
                      (r) => (section['titles'] as List).contains(r['title']),
                    ))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _resourceRow(resource),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
    ],
    _surface(
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('使用提醒', style: headingStyle),
          SizedBox(height: 8),
          Text(
            '• 如有立即危險，請先聯絡緊急救援單位\n• 大多數專線提供匿名或保密協談服務\n• 網站資源可提供更多地區性諮商與轉介資訊',
            style: TextStyle(fontSize: 17, height: 1.5, color: AppColors.title),
          ),
        ],
      ),
    ),
  ];
  Widget _resourceRow(Map<String, dynamic> resource) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.lightYellow.withValues(alpha: .4),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: SystemSymbol(
            resource['kind'] == 'phone' ? 'phone.fill' : 'link',
            size: 20,
            color: AppColors.title,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(resource['title'] as String, style: headingStyle),
              const SizedBox(height: 4),
              Text(
                resource['description'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.title.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                resource['value'] as String,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.title.withValues(alpha: .75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          color: AppColors.title,
          borderRadius: BorderRadius.circular(8),
          onPressed: () => openExternal(
            context,
            resource['kind'] == 'phone'
                ? Uri(scheme: 'tel', path: resource['value'] as String)
                : Uri.parse(resource['value'] as String),
          ),
          child: Text(
            resource['kind'] == 'phone' ? '撥打' : '開啟',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _relax() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        const PageHeading('放鬆', subtitle: '透過冥想與呼吸，放鬆身心'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.lightYellow.withValues(alpha: .6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              for (final section in ['呼吸放鬆', '正念呼吸', '漸進式', '冥想'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: Size.zero,
                      onPressed: () => setState(() => _section = section),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _section == section
                              ? CupertinoColors.white
                              : null,
                          border: Border.all(
                            color: AppColors.lightBrown.withValues(alpha: .5),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            section,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.title.withValues(
                                alpha: _section == section ? 1 : .6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            children: [
              Text(_section, style: headingStyle),
              const SizedBox(height: 12),
              for (final video in widget.catalog.videos.where(
                (v) => v['section'] == _section,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => openExternal(
                      context,
                      Uri.parse(video['url'] as String),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: .9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.lightBrown.withValues(alpha: .4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: .15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const SystemSymbol(
                              'play.rectangle.fill',
                              size: 20,
                              color: AppColors.orange,
                              fallback: CupertinoIcons.play_rectangle_fill,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  video['title'] as String,
                                  maxLines: 2,
                                  style: headingStyle,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${video['duration']} ｜ ${video['topic']}',
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.title.withValues(
                                      alpha: .6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
