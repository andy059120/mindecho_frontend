import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../shared/system_symbol.dart';
import 'privacy_consent.dart';

Future<void> showPrivacy(BuildContext context) async {
  if (kIsWeb) {
    await Navigator.of(
      context,
      rootNavigator: true,
    ).push<void>(CupertinoPageRoute(builder: (_) => const PrivacyPage()));
    return;
  }
  await showCupertinoSheet<void>(
    context: context,
    scrollableBuilder: (_, controller) =>
        PrivacyPage(scrollController: controller),
  );
}

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({this.scrollController, super.key});
  final ScrollController? scrollController;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late Future<Map<String, dynamic>> _copy = _load();
  final _anchors = {for (final section in _sections) section.$1: GlobalKey()};
  final _webAnchor = GlobalKey();

  Future<Map<String, dynamic>> _load() async => jsonDecode(
    await rootBundle.loadString(
      'assets/data/privacy_policy.json',
      cache: false,
    ),
  ) as Map<String, dynamic>;

  void _jump(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 250),
        alignment: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      automaticallyImplyLeading: false,
      middle: const Text('隱私政策與聲明'),
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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('無法載入隱私政策，請稍後再試'),
                  CupertinoButton(
                    onPressed: () => setState(() {
                      _copy = _load();
                    }),
                    child: const Text('重試'),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CupertinoActivityIndicator());
          }
          final copy = snapshot.data!;
          return ContentFrame(
            maxWidth: 1180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ResponsiveLayout.wide(context))
                  SizedBox(
                    width: 260,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 32, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '閱讀目錄',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          for (final section in _sections)
                            _toc(section.$2, _anchors[section.$1]!),
                          _toc('網頁版資料保存說明', _webAnchor),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _pill(
                              'lock.fill',
                              CupertinoIcons.lock_fill,
                              '個資保護',
                              'dataCategories',
                            ),
                            _pill(
                              'brain.head.profile',
                              CupertinoIcons.person_crop_circle,
                              'AI 使用',
                              'warningSection',
                            ),
                            _pill(
                              'globe',
                              CupertinoIcons.globe,
                              '跨境傳輸',
                              'thirdPartyProcessing',
                            ),
                          ],
                        ),
                        for (final section in _sections)
                          _section(
                            section.$1,
                            section.$2,
                            copy[section.$1] as String,
                          ),
                        if (kIsWeb)
                          _legalSection(
                            key: _webAnchor,
                            title: '網頁版資料保存說明',
                            body: const SelectableText(
                              '登入狀態、記住的 email、日記草稿、頭貼與時光寶盒保存在此瀏覽器的網站資料中；不儲存密碼。這些本機資料不會自動與 iOS App 或其他裝置同步。已提交至伺服器的資料依上述政策處理。\n\n'
                              '清除網站資料、使用不同瀏覽器或更換網站來源（包括連接埠），可能無法再取得原本的本機資料。瀏覽器也可能因儲存空間不足而無法保存。\n\n'
                              '登出會清除登入 session，但會保留本機收藏與草稿，供同一帳號下次使用。共用裝置上使用完畢請登出；若不希望留下本機資料，請使用瀏覽器的網站資料設定清除本站資料。\n\n'
                              '如需行使查詢、更正、匯出或刪除等個資權利，可依第七節的聯絡方式提出申請。',
                              style: _bodyStyle,
                            ),
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _toc(String title, GlobalKey anchor) => CupertinoButton(
    padding: const EdgeInsets.symmetric(vertical: 10),
    alignment: Alignment.centerLeft,
    onPressed: () => _jump(anchor),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: AppColors.mediumBrown,
      ),
    ),
  );

  Widget _pill(
    String symbol,
    IconData fallback,
    String label,
    String section,
  ) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: const Size(44, 44),
    onPressed: () => _jump(_anchors[section]!),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.lightBrown.withValues(alpha: .28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SystemSymbol(
            symbol,
            size: 11,
            fallback: fallback,
            color: AppColors.darkBrown,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBrown,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.orange, Color.fromRGBO(189, 107, 46, 1)],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.orange.withValues(alpha: .22),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Text(
                'PsychEcho',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.orange,
                ),
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
            height: 1.6,
          ),
        ),
      ],
    ),
  );

  Widget _section(String id, String title, String text) => _legalSection(
    key: _anchors[id]!,
    title: title,
    warning: id == 'warningSection',
    success: id == 'commitmentSection' || id == 'appendixSection',
    highlight: id == 'appendixSection',
    body: id == 'appendixSection'
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < privacyConsentStatements.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
                  child: SelectableText(
                    privacyConsentStatements[i],
                    style: _bodyStyle,
                  ),
                ),
            ],
          )
        : id == 'retentionSection'
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in text.split('\n\n').indexed)
                Padding(
                  padding: EdgeInsets.only(top: item.$1 == 0 ? 0 : 8),
                  child: SelectableText(
                    item.$2,
                    style: item.$1 % 3 == 0
                        ? _bodyStyle.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          )
                        : _bodyStyle,
                  ),
                ),
            ],
          )
        : SelectableText(text, style: _bodyStyle),
  );

  Widget _legalSection({
    required GlobalKey key,
    required String title,
    required Widget body,
    bool warning = false,
    bool success = false,
    bool highlight = false,
  }) => Padding(
    key: key,
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: warning
                    ? const Color(0xFFD1612E)
                    : success
                    ? const Color(0xFF7D6B2E)
                    : AppColors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.orange.withValues(alpha: .12)
                : CupertinoColors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.lightBrown.withValues(alpha: .18),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: body,
        ),
      ],
    ),
  );
}

const _bodyStyle = TextStyle(
  fontSize: 14,
  color: AppColors.mediumBrown,
  height: 1.7,
);

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
