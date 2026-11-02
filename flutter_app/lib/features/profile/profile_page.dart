import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/platform/local_media_store.dart';
import '../../shared/system_symbol.dart';
import '../../shared/widgets.dart';
import '../auth/auth_widgets.dart';
import '../dashboard/controller.dart';
import '../dashboard/widgets.dart';
import 'treasure_page.dart';

String fullName(Map<String, dynamic> user) {
  final parts = [
    user['lastName'],
    user['firstName'],
  ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
  return user['name'] as String? ?? (parts.isEmpty ? '使用者' : parts);
}

String displayName(Map<String, dynamic> user) {
  final nickname = user['nickname'] as String?;
  return nickname?.isNotEmpty == true ? nickname! : fullName(user);
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.controller, required this.media, super.key});
  final DashboardController controller;
  final LocalMediaStore media;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Uint8List?> _avatar = widget.media.avatar().catchError(
    (Object _) => null,
  );
  Future<void> _avatarOptions() async {
    final choice = await choose(context, '更換頭貼', ['從相簿選擇', '拍照上傳', '使用預設頭像']);
    if (choice == null || !mounted) return;
    try {
      if (choice == '使用預設頭像') {
        await widget.media.store.write('avatar', null);
      } else {
        final image = await ImagePicker().pickImage(
          source: choice == '拍照上傳' ? ImageSource.camera : ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 90,
        );
        if (image == null) return;
        await widget.media.setAvatar(image.path);
      }
      if (mounted) setState(() => _avatar = widget.media.avatar());
    } catch (_) {
      if (mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('無法更換頭貼'),
            content: const Text('請檢查相機、照片權限與儲存空間。'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('確定'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    if (await confirm(
      context,
      title: '登出',
      message: '確定要登出嗎？',
      action: '登出',
      destructive: true,
    )) {
      await widget.controller.repository.auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final user = widget.controller.user;
      final contacts = (user['emergencyContacts'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      return CupertinoPageScaffold(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const CupertinoSliverNavigationBar(
              largeTitle: Text('個人檔案'),
              backgroundColor: AppColors.lightYellow,
            ),
            CupertinoSliverRefreshControl(
              onRefresh: widget.controller.loadProfile,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              sliver: SliverList.list(
                children: [
                  if (widget.controller.errors['profile'] != null)
                    ErrorNotice(
                      widget.controller.errors['profile']!,
                      onRetry: widget.controller.loadProfile,
                    ),
                  MindCard(
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _avatarOptions,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              FutureBuilder(
                                future: _avatar,
                                builder: (context, snapshot) => Container(
                                  width: 80,
                                  height: 80,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: CupertinoColors.systemOrange
                                        .withValues(alpha: .85),
                                    border: Border.all(
                                      color: CupertinoColors.white.withValues(
                                        alpha: .9,
                                      ),
                                      width: 3,
                                    ),
                                  ),
                                  child: snapshot.data == null
                                      ? Center(
                                          child: Text(
                                            fullName(user).runes
                                                .take(1)
                                                .map(String.fromCharCode)
                                                .join(),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: CupertinoColors.white,
                                            ),
                                          ),
                                        )
                                      : Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.orange,
                                    border: Border.all(
                                      color: CupertinoColors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const SystemSymbol(
                                    'camera.fill',
                                    size: 12,
                                    color: CupertinoColors.white,
                                    fallback: CupertinoIcons.camera_fill,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(displayName(user), style: headingStyle),
                              const SizedBox(height: 8),
                              const Text(
                                '查看與編輯個人資訊',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.only(left: 8),
                          minimumSize: Size.zero,
                          onPressed: () => Navigator.of(context).push(
                            CupertinoPageRoute<void>(
                              builder: (_) => PersonalInfoPage(
                                controller: widget.controller,
                              ),
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.chevron_right,
                            size: 18,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                  const Text('時光寶盒', style: headingStyle),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 188,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: _TreasureCard(
                        onTap: () => showTreasure(context, widget.media),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  MindCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('緊急聯繫', style: headingStyle),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _contactCard(
                                '緊急救援',
                                '119 消防局、救護與緊急救援',
                                '119',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _contactCard(
                                '心理支持專線',
                                '1925（依愛我）',
                                '1925',
                              ),
                            ),
                          ],
                        ),
                        for (final contact in contacts)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _contactCard(
                              contact['relation'] as String? ?? '緊急聯絡人',
                              '${contact['name']}（${contact['relation']}）：${contact['contactInfo']}',
                              contact['contactInfo'] as String? ?? '',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => openExternal(
                      context,
                      Uri.parse('https://forms.gle/K6GWAgxGZiH9tx2g6'),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightYellow,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          SystemSymbol(
                            'doc.text.fill',
                            size: 20,
                            color: AppColors.orange,
                            fallback: CupertinoIcons.doc_text_fill,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('每日回饋', style: headingStyle),
                                SizedBox(height: 4),
                                Text(
                                  '填寫每日測驗回饋表單，幫助我們調整與優化使用體驗',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12),
                          SystemSymbol(
                            'arrow.up.right.square',
                            size: 17,
                            color: AppColors.orange,
                            fallback: CupertinoIcons.arrow_up_right_square,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: Size.zero,
                    color: CupertinoColors.systemRed.withValues(alpha: .85),
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _logout,
                    child: const Text(
                      '登出',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget _contactCard(String title, String subtitle, String phone) => Container(
    height: 130,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 12,
          offset: Offset(0, 6),
        ),
        BoxShadow(
          color: Color(0x1FFF9500),
          blurRadius: 16,
          offset: Offset(0, 10),
        ),
      ],
      border: Border.all(
        color: CupertinoColors.systemOrange.withValues(alpha: .08),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemOrange.withValues(alpha: .15),
              ),
              child: const SystemSymbol(
                'lifepreserver',
                size: 15,
                color: CupertinoColors.systemOrange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mediumBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        CupertinoButton(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          onPressed: () => openExternal(
            context,
            Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^+0-9]'), '')),
          ),
          child: Container(
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.systemOrange.withValues(alpha: .95),
                  CupertinoColors.systemOrange.withValues(alpha: .75),
                ],
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SystemSymbol(
                  'phone.fill',
                  size: 12,
                  color: CupertinoColors.white,
                ),
                SizedBox(width: 6),
                Text(
                  '立即撥打',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _TreasureCard extends StatelessWidget {
  const _TreasureCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    height: 160,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CupertinoColors.systemOrange.withValues(alpha: .95),
                CupertinoColors.systemOrange.withValues(alpha: .75),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '支撐我的片刻',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '寫一句話，留給需要被支持的自己。',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: CupertinoColors.label),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withValues(
                        alpha: .12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        '查看我的理由 ›',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemOrange,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> openExternal(BuildContext context, Uri uri) async {
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw const FormatException();
    }
  } catch (_) {
    if (context.mounted) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('無法開啟連結'),
          content: const Text('請確認裝置是否支援此功能。'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('確定'),
            ),
          ],
        ),
      );
    }
  }
}

class PersonalInfoPage extends StatelessWidget {
  const PersonalInfoPage({required this.controller, super.key});
  final DashboardController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final user = controller.user;
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: const Text('個人資訊'),
          trailing: textAction(
            '編輯',
            () => Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (_) => _EditInfoPage(controller: controller),
              ),
            ),
            size: 17,
          ),
        ),
        child: SafeArea(
          child: ListView(
            children: [
              CupertinoListSection.insetGrouped(
                header: const Text('基本資料'),
                children: [
                  _row('Email', user['email']?.toString() ?? ''),
                  _row('姓名', fullName(user)),
                  _row('暱稱', user['nickname']?.toString() ?? '—'),
                  _row(
                    '出生年月',
                    user['birthYear'] != null
                        ? '${user['birthYear']}-${user['birthMonth']}'
                        : (user['dateOfBirth']?.toString() ?? '—'),
                  ),
                  _row('生理性別', user['gender']?.toString() ?? '—'),
                  _row('教育程度', user['educationLevel']?.toString() ?? '—'),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget _row(String label, String value) => CupertinoListTile(
    title: Text(label),
    additionalInfo: SizedBox(
      width: 160,
      child: Text(
        value,
        textAlign: TextAlign.right,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

class _EditInfoPage extends StatefulWidget {
  const _EditInfoPage({required this.controller});
  final DashboardController controller;
  @override
  State<_EditInfoPage> createState() => _EditInfoPageState();
}

class _EditInfoPageState extends State<_EditInfoPage> {
  late final _email = TextEditingController(
        text: widget.controller.user['email'] as String?,
      ),
      _name = TextEditingController(text: fullName(widget.controller.user));
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!isEmail(_email.text) || _name.text.trim().isEmpty) {
      setState(() => _error = '請輸入姓名與有效的 Email');
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.controller.updateProfile(_email.text, _name.text);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: const CupertinoNavigationBar(middle: Text('編輯個人資訊')),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AuthField(
            'Email',
            controller: _email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          AuthField('姓名', controller: _name),
          const SizedBox(height: 24),
          if (_error != null) ErrorNotice(_error!),
          AuthAction('保存變更', onPressed: _save, busy: _busy),
        ],
      ),
    ),
  );
}
