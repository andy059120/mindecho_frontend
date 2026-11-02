import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/system_symbol.dart';

Future<void> showPrivacy(BuildContext context) => showCupertinoSheet<void>(
  context: context,
  scrollableBuilder: (_, controller) =>
      PrivacyPage(scrollController: controller),
);

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({this.scrollController, super.key});
  final ScrollController? scrollController;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late final _copy = rootBundle
      .loadString('assets/data/privacy_policy.json')
      .then((value) => jsonDecode(value) as Map<String, dynamic>);
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: const Text('隱私權保護政策與使用聲明'),
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
        child: const Text('完成'),
      ),
    ),
    child: SafeArea(
      child: FutureBuilder(
        future: _copy,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('無法載入隱私政策，請稍後再試'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final copy = snapshot.data!;
          return ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  gradient: const LinearGradient(
                    colors: [AppColors.orange, Color.fromRGBO(189, 107, 46, 1)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MindEcho',
                          style: TextStyle(
                            height: 1.2,
                            fontSize: 13,
                            color: CupertinoColors.white,
                          ),
                        ),
                        const SystemSymbol(
                          'checkmark.shield.fill',
                          size: 30,
                          color: CupertinoColors.white,
                          fallback: CupertinoIcons.shield_fill,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '隱私權保護政策\n與使用聲明',
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: 'CupertinoSystemDisplay',
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.white,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '當您註冊、登入或使用本服務之任何功能，即視為您已閱讀、瞭解並同意本政策之全部內容。若您不同意本政策之任何部分，請立即停止使用本服務。',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.white,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [Text('個資保護'), Text('AI 使用'), Text('跨境傳輸')],
              ),
              for (final section in _sections) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        section.$2,
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'CupertinoSystemDisplay',
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: section.$1 == 'warningSection'
                        ? AppColors.orange.withValues(alpha: 0.08)
                        : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.lightBrown.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Text(
                    copy[section.$1] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mediumBrown,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}

const _sections = [
  ('introduction', '一、前言'),
  ('warningSection', '二、重要警語與免責聲明（請務必詳閱）'),
  ('dataCategories', '三、蒐集之個人資料類別'),
  ('purposes', '四、蒐集目的與利用方式'),
  ('commitmentSection', '我們承諾'),
  ('thirdPartyProcessing', '五、資料之委外與第三方處理'),
  ('retentionSection', '六、資料保存期限'),
  ('rightsSection', '七、您的權利（個資法第 3 條）'),
  ('minors', '八、未成年人保護'),
  ('security', '九、資訊安全措施'),
  ('cookies', '十、Cookie 之使用'),
  ('revisions', '十一、政策修訂'),
  ('governingLaw', '十二、準據法與管轄'),
  ('appendixSection', '附錄 A：使用聲明（簡要重點）'),
];
