import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/platform/local_media_store.dart';
import '../../shared/system_symbol.dart';
import '../../shared/swift_detail_navigation_bar.dart';
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
      if (mounted) {
        setState(() {
          _avatar = widget.media.avatar();
        });
      }
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
                                media: widget.media,
                                onAvatarTap: _avatarOptions,
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

Widget _infoBackButton(BuildContext context) => Semantics(
  label: '返回',
  button: true,
  excludeSemantics: true,
  onTap: () => Navigator.pop(context),
  child: CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () => Navigator.pop(context),
    child: Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CupertinoColors.white.withValues(alpha: .9),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4)],
      ),
      child: const Icon(
        CupertinoIcons.chevron_left,
        size: 20,
        color: CupertinoColors.label,
      ),
    ),
  ),
);

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({
    required this.controller,
    this.media,
    this.onAvatarTap,
    super.key,
  });
  final DashboardController controller;
  final LocalMediaStore? media;
  final Future<void> Function()? onAvatarTap;
  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late Future<Uint8List?> _avatar =
      widget.media?.avatar().catchError((Object _) => null) ??
      Future.value(null);
  Future<void> _changeAvatar() async {
    await widget.onAvatarTap?.call();
    if (mounted) {
      setState(() {
        _avatar =
            widget.media?.avatar().catchError((Object _) => null) ??
            Future.value(null);
      });
    }
  }

  String _initials(Map<String, dynamic> user) {
    final initials = [user['firstName'], user['lastName']]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .map((s) => String.fromCharCodes(s.runes.take(1)))
        .join()
        .toUpperCase();
    return initials.isEmpty ? 'ME' : initials;
  }

  String _birthMonth(Map<String, dynamic> user) {
    if (user['birthYear'] != null && user['birthMonth'] != null) {
      return '${user['birthYear']}-${user['birthMonth'].toString().padLeft(2, '0')}';
    }
    final value = user['dateOfBirth']?.toString() ?? '';
    return value.isEmpty
        ? '-'
        : value.length >= 7
        ? value.substring(0, 7)
        : value;
  }

  Widget _card(Widget child, {bool header = false}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: header
          ? Color.alphaBlend(
              CupertinoColors.white.withValues(alpha: .9),
              AppColors.lightYellow,
            )
          : CupertinoColors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: CupertinoColors.black.withValues(alpha: header ? .08 : .05),
          blurRadius: header ? 10 : 8,
          offset: Offset(0, header ? 6 : 4),
        ),
      ],
    ),
    child: child,
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final user = widget.controller.user;
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.white,
        navigationBar: SwiftDetailNavigationBar(
          child: CupertinoNavigationBar(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 16),
            middle: const Text('個人資訊'),
            automaticallyImplyLeading: false,
            leading: _infoBackButton(context),
            backgroundColor: CupertinoColors.white,
            border: null,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            children: [
              Container(
                color: AppColors.lightYellow,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 64),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _card(
                      Column(
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            onPressed: widget.onAvatarTap == null
                                ? null
                                : _changeAvatar,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                FutureBuilder(
                                  future: _avatar,
                                  builder: (context, snapshot) => Container(
                                    width: 110,
                                    height: 110,
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
                                              _initials(user),
                                              style: const TextStyle(
                                                fontSize: 22,
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
                                    padding: const EdgeInsets.all(10),
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
                                      size: 15,
                                      weight: 'bold',
                                      color: CupertinoColors.white,
                                      fallback: CupertinoIcons.camera_fill,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName(user),
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                              color: AppColors.title,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '更換頭貼',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.2,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                      header: true,
                    ),
                    const SizedBox(height: 20),
                    _card(
                      Column(
                        children: [
                          _row(
                            'envelope.fill',
                            'Email',
                            user['email']?.toString() ?? '-',
                          ),
                          const SizedBox(height: 12),
                          _row('person.text.rectangle', '姓名', fullName(user)),
                          const SizedBox(height: 12),
                          _row('calendar', '出生年月', _birthMonth(user)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => Navigator.of(context).push(
                        CupertinoPageRoute<void>(
                          builder: (_) =>
                              _EditInfoPage(controller: widget.controller),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            SystemSymbol(
                              'pencil',
                              size: 17,
                              color: CupertinoColors.white,
                              fallback: CupertinoIcons.pencil,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '編輯個人資訊',
                                style: TextStyle(
                                  fontSize: 17,
                                  height: 1.2,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                            Icon(
                              CupertinoIcons.chevron_right,
                              size: 13,
                              color: CupertinoColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget _row(String icon, String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.orange.withValues(alpha: .15),
          ),
          child: SystemSymbol(
            icon,
            size: 14,
            weight: 'semibold',
            color: AppColors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: AppColors.title,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.2,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
          ),
        ),
      ],
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
    backgroundColor: CupertinoColors.systemGroupedBackground,
    navigationBar: SwiftDetailNavigationBar(
      child: CupertinoNavigationBar(
        padding: const EdgeInsetsDirectional.only(start: 24, end: 16),
        middle: const Text('編輯個人資訊'),
        automaticallyImplyLeading: false,
        leading: _infoBackButton(context),
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
    ),
    child: SafeArea(
      bottom: false,
      child: ListView(
        children: [
          CupertinoFormSection.insetGrouped(
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemGroupedBackground,
              borderRadius: BorderRadius.circular(26),
            ),
            header: const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 4),
              child: Text('基本資料', style: TextStyle(fontSize: 13, height: 1.2)),
            ),
            children: [
              CupertinoTextFormFieldRow(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                controller: _email,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enabled: !_busy,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  color: CupertinoColors.label,
                ),
              ),
              CupertinoTextFormFieldRow(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                controller: _name,
                placeholder: '姓名',
                enabled: !_busy,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.2,
                  color: CupertinoColors.label,
                ),
              ),
              CupertinoFormRow(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                prefix: const Text(
                  '出生年月',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    color: CupertinoColors.label,
                  ),
                ),
                child: Text(
                  _birthDisplay,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.2,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            ],
          ),
          if (_error != null)
            CupertinoFormSection.insetGrouped(
              decoration: BoxDecoration(
                color: CupertinoColors.secondarySystemGroupedBackground,
                borderRadius: BorderRadius.circular(26),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ),
              ],
            ),
          CupertinoFormSection.insetGrouped(
            margin: const EdgeInsets.fromLTRB(20, 26, 20, 10),
            decoration: BoxDecoration(
              color: CupertinoColors.secondarySystemGroupedBackground,
              borderRadius: BorderRadius.circular(26),
            ),
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _busy ? null : _save,
                child: Center(
                  child: _busy
                      ? const CupertinoActivityIndicator()
                      : const Text(
                          '保存變更',
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.systemOrange,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  String get _birthDisplay {
    final user = widget.controller.user;
    if (user['birthYear'] != null && user['birthMonth'] != null) {
      return '${user['birthYear']}-${user['birthMonth'].toString().padLeft(2, '0')}';
    }
    final raw = user['dateOfBirth']?.toString() ?? '';
    return raw.isEmpty
        ? '-'
        : raw.length >= 7
        ? raw.substring(0, 7)
        : raw;
  }
}
