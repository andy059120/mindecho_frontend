import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/system_symbol.dart';
import 'chat_models.dart';

/// Swift 對照用的顯示文案；不參與 API 模式或 session 狀態。
extension ChatModePresentation on ChatMode {
  String get symbol => switch (this) {
    ChatMode.initial => 'sparkles',
    ChatMode.mbt => 'person.2.fill',
    ChatMode.cbt => 'brain.head.profile',
    ChatMode.dbt => 'waveform.path.ecg',
    ChatMode.mbct => 'leaf',
  };
  String get displayTitle => this == ChatMode.initial ? '初始模式' : '$title模式';
  String get introduction => switch (this) {
    ChatMode.initial => '初次對談，溫暖接住與建立安全感，讓對話自然開始',
    ChatMode.cbt => '溫柔引導探索想法－情緒－行為的連結，不糾正也不辯論',
    ChatMode.dbt => '聚焦情緒調節、壓力耐受與人際界線，幫助當下穩住自己',
    ChatMode.mbt => '培養對自己與他人內在狀態的好奇，放慢互動中的思考',
    ChatMode.mbct => '正念取向，觀察想法與情緒的起伏，需要時做簡短安定練習',
  };
  List<String> get features => switch (this) {
    ChatMode.initial => ['溫暖接住與建立安全感', '讓對話自然開始', '不做評估或制式提問'],
    ChatMode.cbt => ['識別負面思維模式', '挑戰不合理的想法', '建立積極的認知習慣'],
    ChatMode.dbt => ['先穩定強烈情緒與衝動', '練習在壓力下撐過當下', '整理需求與界線，改善互動'],
    ChatMode.mbt => ['增強情感覺察能力', '改善人際關係理解', '提升心智化水平'],
    ChatMode.mbct => ['觀察想法與情緒的起伏', '把想法當作事件來看', '必要時做簡短的呼吸安定'],
  };
  List<String> get quickReplies => switch (this) {
    ChatMode.initial => ['我不知道從哪說起', '最近有點煩', '想整理心情', '只是想聊聊'],
    ChatMode.cbt => ['我感到很焦慮', '總是擔心', '覺得壓力很大', '想不通'],
    ChatMode.dbt => ['我快失控了', '情緒一下子很滿', '我有強烈衝動', '我不知道怎麼冷靜'],
    ChatMode.mbt => ['人際關係困擾', '不理解他人', '情緒複雜', '感受不明'],
    ChatMode.mbct => ['最近壓力很大', '腦中一直想', '情緒起伏', '想練習正念'],
  };
  String get placeholder => switch (this) {
    ChatMode.initial => '從想聊的事情開始...',
    ChatMode.cbt => '分享您的想法或困擾...',
    ChatMode.dbt => '描述當下情緒、衝動或人際壓力...',
    ChatMode.mbt => '描述您的感受或人際困擾...',
    ChatMode.mbct => '覺察此刻的感受或念頭...',
  };
}

class ChatModeTile extends StatelessWidget {
  const ChatModeTile({required this.mode, required this.onPressed, super.key});
  final ChatMode mode;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: LayoutBuilder(
        builder: (context, constraints) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFAE6B3), Color(0xFFF2A659), Color(0xFFE9975C)],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x19000000), blurRadius: 4),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SystemSymbol(
                mode.symbol,
                size: 22,
                color: AppColors.darkBrown,
                fallback: mode.icon,
              ),
              const Spacer(),
              Text(
                mode.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mode.subtitle,
                maxLines: constraints.maxWidth >= 180 ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: constraints.maxWidth >= 180 ? 12 : 11,
                  height: 1.4,
                  color: AppColors.darkBrown.withValues(alpha: .7),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkBrown,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '開始對話',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ModeIntroductionPage extends StatelessWidget {
  const ModeIntroductionPage({required this.mode, super.key});
  final ChatMode mode;
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      middle: Text('聊天室介紹'),
      backgroundColor: AppColors.lightYellow,
      border: null,
    ),
    child: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x19000000), blurRadius: 4),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: mode.color.withValues(alpha: .2),
                          ),
                          child: Text(
                            mode.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: mode.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mode.displayTitle,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.title,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mode.introduction,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '特色功能：',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.title,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final feature in mode.features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: mode.color,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: _action(
                    '取消',
                    () => Navigator.pop(context, false),
                    false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _action(
                    '確定',
                    () => Navigator.pop(context, true),
                    true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  Widget _action(String label, VoidCallback onPressed, bool primary) =>
      CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: Size.zero,
        color: primary
            ? AppColors.darkBrown
            : CupertinoColors.systemGrey.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(12),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            color: primary ? CupertinoColors.white : AppColors.darkBrown,
          ),
        ),
      );
}
