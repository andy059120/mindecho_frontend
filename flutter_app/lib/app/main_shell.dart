import 'dart:ui';

import 'package:flutter/cupertino.dart';

import 'theme.dart';
import '../shared/responsive_layout.dart';
import '../features/auth/auth_widgets.dart';
import '../features/auth/privacy_page.dart';

import '../core/platform/local_media_store.dart';
import '../core/platform/media_picker.dart';
import '../shared/widgets.dart';
import '../core/storage/account_store.dart';
import '../features/auth/auth_controller.dart';
import '../features/check_in/check_in_page.dart';
import '../features/chat/chat_content.dart';
import '../features/chat/chat_list_page.dart';
import '../features/dashboard/catalog.dart';
import '../features/dashboard/controller.dart';
import '../features/dashboard/home_page.dart';
import '../features/dashboard/repository.dart';
import '../features/dashboard/tracking_page.dart';
import '../features/profile/profile_page.dart';
import '../shared/system_symbol.dart';
import '../shared/tab_tour_overlay.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.auth,
    required this.content,
    required this.catalog,
    this.store,
    this.mediaPicker,
    this.promptCheckIn = true,
    super.key,
  });
  final AuthController auth;
  final ChatContent content;
  final DashboardCatalog catalog;
  final AccountStore? store;
  final MediaPicker? mediaPicker;
  final bool promptCheckIn;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final _controller = DashboardController(
    DashboardRepository(widget.auth),
  );
  late final _accountId =
      (widget.auth.session!.user['userId'] ??
              widget.auth.session!.user['id'] ??
              widget.auth.session!.user['email'])
          as String;
  late final _store = widget.store ?? KeychainAccountStore(_accountId);
  late final _media = LocalMediaStore(_accountId, _store);
  final _navigatorKeys = List.generate(4, (_) => GlobalKey<NavigatorState>());
  int _tab = 0;
  bool _recoveringMedia = true;
  String? _mediaError;
  int? _tour;
  @override
  void initState() {
    super.initState();
    _recoverMedia();
    _load();
  }

  Future<void> _recoverMedia() async {
    setState(() {
      _recoveringMedia = true;
      _mediaError = null;
    });
    try {
      await (widget.mediaPicker ?? MediaPicker()).recover(_media);
    } catch (_) {
      if (mounted) setState(() => _mediaError = '無法恢復媒體匯入，請確認儲存空間後重試');
    } finally {
      if (mounted) setState(() => _recoveringMedia = false);
    }
  }

  Future<void> _load() async {
    await _controller.refresh();
    if (!mounted ||
        !widget.promptCheckIn ||
        _controller.errors['metrics'] != null ||
        _controller.completedToday ||
        widget.auth.session == null) {
      return;
    }
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CheckInPage(controller: _controller),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = WebLayout.wide(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: _tour == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _tour != null) setState(() => _tour = null);
      },
      child: CupertinoPageScaffold(
        child: Stack(
          children: [
            Row(
              children: [
                if (wide) _sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      if (_mediaError != null)
                        SafeArea(
                          bottom: false,
                          child: ErrorNotice(
                            _mediaError!,
                            onRetry: _recoverMedia,
                          ),
                        ),
                      Expanded(
                        child: WebContentFrame(
                          maxWidth: 1120,
                          child: _recoveringMedia
                              ? const Center(
                                  child: CupertinoActivityIndicator(),
                                )
                              : Stack(
                                  children: [
                                    IndexedStack(
                                      index: _tab,
                                      children: [
                                        for (var i = 0; i < 4; i++)
                                          TickerMode(
                                            enabled: i == _tab && _tour == null,
                                            child: CupertinoTabView(
                                              navigatorKey: _navigatorKeys[i],
                                              builder: (context) => switch (i) {
                                                0 => HomePage(
                                                  controller: _controller,
                                                  store: _store,
                                                  media: _media,
                                                  catalog: widget.catalog,
                                                  onTour: () =>
                                                      setState(() => _tour = 0),
                                                ),
                                                1 => ChatListPage(
                                                  auth: widget.auth,
                                                  content: widget.content,
                                                  embedded: true,
                                                ),
                                                2 => TrackingPage(
                                                  controller: _controller,
                                                  store: _store,
                                                ),
                                                _ => ProfilePage(
                                                  controller: _controller,
                                                  media: _media,
                                                ),
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      if (!wide && !(_tab == 1 && keyboard))
                        ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBackground
                                    .withValues(alpha: .8),
                                border: const Border(
                                  top: BorderSide(
                                    color: CupertinoColors.separator,
                                    width: .5,
                                  ),
                                ),
                              ),
                              child: SafeArea(
                                top: false,
                                child: SizedBox(
                                  height: 70,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        for (var i = 0; i < 4; i++)
                                          Expanded(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 8,
                                                  ),
                                              child: CupertinoButton(
                                                padding: EdgeInsets.zero,
                                                onPressed: () =>
                                                    setState(() => _tab = i),
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: _tab == i
                                                        ? CupertinoColors
                                                              .systemOrange
                                                              .withValues(
                                                                alpha: .15,
                                                              )
                                                        : null,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SystemSymbol(
                                                        _tabs[i].$2,
                                                        size: 15,
                                                        weight: 'semibold',
                                                        color: _tab == i
                                                            ? CupertinoColors
                                                                  .systemOrange
                                                            : CupertinoColors
                                                                  .secondaryLabel,
                                                        fallback: _tabs[i].$3,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        _tabs[i].$1,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: _tab == i
                                                              ? CupertinoColors
                                                                    .systemOrange
                                                              : CupertinoColors
                                                                    .secondaryLabel,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
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
              ],
            ),
            if (_tour != null)
              Positioned.fill(
                child: TabTourOverlay(
                  sidebar: wide,
                  index: _tour!,
                  title: _tabs[_tour!].$1,
                  message: _tourText[_tour!],
                  onClose: () => setState(() => _tour = null),
                  onNext: () =>
                      setState(() => _tour = _tour == 3 ? null : _tour! + 1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sidebar() => Container(
    width: WebLayout.sidebarWidth,
    decoration: BoxDecoration(
      color: CupertinoColors.white.withValues(alpha: .8),
      border: Border(
        right: BorderSide(color: AppColors.lightBrown.withValues(alpha: .18)),
      ),
    ),
    child: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: AuthBrand(size: 23, iconSize: 23),
                  ),
                  const SizedBox(height: 32),
                  for (var i = 0; i < _tabs.length; i++)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                      child: Semantics(
                        selected: _tab == i,
                        child: CupertinoButton(
                          color: _tab == i
                              ? AppColors.orange.withValues(alpha: .12)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          onPressed: () => setState(() => _tab = i),
                          child: Row(
                            children: [
                              SystemSymbol(
                                _tabs[i].$2,
                                size: 20,
                                fallback: _tabs[i].$3,
                                color: _tab == i
                                    ? AppColors.orange
                                    : AppColors.mediumBrown,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _tabs[i].$1,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: _tab == i
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: _tab == i
                                        ? AppColors.orange
                                        : AppColors.mediumBrown,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '給自己一點時間',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '陪伴、記錄，慢慢前進。',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.mediumBrown,
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => showPrivacy(context),
                          child: const Text(
                            '隱私政策',
                            style: TextStyle(fontSize: 13),
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
      ),
    ),
  );
}

const _tabs = [
  ('首頁', 'house', CupertinoIcons.house),
  ('聊天', 'bubble.left', CupertinoIcons.chat_bubble),
  ('追蹤', 'chart.bar', CupertinoIcons.chart_bar),
  ('個人檔案', 'person', CupertinoIcons.person),
];
const _tourText = [
  '總覽你的狀態與每日提醒。',
  '和 AI 進行對話、整理感受。',
  '記錄情緒與日記、追蹤變化。',
  '管理個人資料與重要聯絡資訊。',
];
