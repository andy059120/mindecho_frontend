import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../dashboard/widgets.dart' show PageHeading;
import '../../shared/widgets.dart';
import '../../shared/responsive_layout.dart';
import '../auth/auth_controller.dart';
import 'chat_content.dart';
import 'chat_detail_page.dart';
import 'chat_models.dart';
import 'chat_repository.dart';
import 'chat_visuals.dart';
import '../../shared/system_symbol.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({
    required this.auth,
    required this.content,
    this.embedded = false,
    super.key,
  });
  final AuthController auth;
  final ChatContent content;
  final bool embedded;
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  late final _repository = ChatRepository(widget.auth);
  final _sessions = <ChatSession>[];
  bool _loading = false;
  bool _mutating = false;
  bool _hasMore = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await _repository.sessions(
        offset: more ? _sessions.length : 0,
      );
      if (!mounted) return;
      setState(() {
        if (!more) _sessions.clear();
        final ids = _sessions.map((session) => session.id).toSet();
        _sessions.addAll(entries.where((entry) => !ids.contains(entry.id)));
        _hasMore = entries.length == 20;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create(ChatMode mode) async {
    if (_mutating || _loading) return;
    final accepted = await showCupertinoSheet<bool>(
      context: context,
      scrollableBuilder: (_, _) => ModeIntroductionPage(mode: mode),
    );
    if (accepted != true || !mounted) return;
    final title = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => const _TitleDialog(),
    );
    if (title == null || !mounted) return;
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      final session = await _repository.create(mode, title);
      if (mounted) await _open(session);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _open(ChatSession session) async {
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => ChatDetailPage(
          session: session,
          repository: _repository,
          content: widget.content,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _delete(ChatSession session) async {
    if (_mutating || _loading) return;
    if (!await confirm(
          context,
          title: '刪除對話',
          message: '確定要刪除「${session.title}」對話嗎？此操作無法復原。',
          action: '刪除',
          destructive: true,
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      _mutating = true;
      _error = null;
    });
    try {
      await _repository.delete(session.id);
      if (mounted) {
        setState(
          () => _sessions.removeWhere((entry) => entry.id == session.id),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _logout() async {
    if (!await confirm(context, title: '登出', message: '確定要登出嗎？') || !mounted) {
      return;
    }
    try {
      await widget.auth.logout();
    } catch (_) {
      if (mounted) setState(() => _error = '無法清除登入資訊，請重新嘗試');
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    resizeToAvoidBottomInset: false,
    navigationBar: widget.embedded
        ? null
        : CupertinoNavigationBar(
            middle: const Text('聊天室'),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _logout,
              child: const Text('登出'),
            ),
          ),
    child: SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeading('聊天室', subtitle: '選擇一種對話方式，開始今天的陪伴'),
          const SizedBox(height: 8),
          ResponsiveShelf(
            allowGrid:
                MediaQuery.sizeOf(context).height >=
                700 *
                    (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(
                      1.0,
                      2.0,
                    ),
            itemHeight: 164,
            itemCount: ChatMode.values.length,
            itemBuilder: (context, index) => ChatModeTile(
              mode: ChatMode.values[index],
              onPressed: _mutating || _loading
                  ? null
                  : () => _create(ChatMode.values[index]),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              '聊天紀錄',
              style: TextStyle(
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.title,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(onRefresh: _load),
                  if (_loading || _mutating)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CupertinoActivityIndicator(),
                      ),
                    ),
                  if (_error != null)
                    SliverToBoxAdapter(
                      child: ErrorNotice(_error!, onRetry: _load),
                    ),
                  if (_sessions.isEmpty && !_loading && _error == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SystemSymbol(
                              'bubble.left.and.bubble.right',
                              size: 56,
                              color: AppColors.title.withValues(alpha: .5),
                              fallback: CupertinoIcons.chat_bubble_2,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '還沒有聊天紀錄',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.title.withValues(alpha: .7),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '開始您的第一次心靈對話',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.title.withValues(alpha: .6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CupertinoButton(
                              color: AppColors.orange,
                              borderRadius: BorderRadius.circular(12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              onPressed: () => _create(ChatMode.initial),
                              child: const Text(
                                '開始聊天',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 16),
                    sliver: SliverList.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        return Column(
                          children: [
                            GestureDetector(
                              onLongPress: _mutating || _loading
                                  ? null
                                  : () => _sessionActions(session),
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                onPressed: _mutating
                                    ? null
                                    : () => _open(session),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: session.mode.color.withValues(
                                          alpha: .2,
                                        ),
                                      ),
                                      child: Text(
                                        session.mode == ChatMode.initial
                                            ? '初始'
                                            : session.mode.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: session.mode.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  session.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.title,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _dateLabel(session.createdAt),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.chatBackground,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              session.mode == ChatMode.initial
                                                  ? '初始'
                                                  : session.mode.title,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.userBubble,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 12,
                                      color: CupertinoColors.systemGrey
                                          .withValues(alpha: .6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (index < _sessions.length - 1)
                              const Padding(
                                padding: EdgeInsets.only(left: 80),
                                child: ContainerDivider(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  if (_hasMore && _sessions.isNotEmpty && !_loading)
                    SliverToBoxAdapter(
                      child: CupertinoButton(
                        onPressed: () => _load(more: true),
                        child: const Text('載入更多'),
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
  Future<void> _sessionActions(ChatSession session) =>
      showCupertinoModalPopup<void>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: Text(session.title),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(sheetContext);
                _delete(session);
              },
              child: const Text('刪除對話'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text('取消'),
          ),
        ),
      );
  String _dateLabel(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day),
        today = DateTime(now.year, now.month, now.day);
    if (day == today) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (day == today.subtract(const Duration(days: 1))) return '昨天';
    return '${date.month}/${date.day}';
  }
}

class ContainerDivider extends StatelessWidget {
  const ContainerDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      Container(height: .5, color: CupertinoColors.separator);
}

class _TitleDialog extends StatefulWidget {
  const _TitleDialog();
  @override
  State<_TitleDialog> createState() => _TitleDialogState();
}

class _TitleDialogState extends State<_TitleDialog> {
  final _title = TextEditingController();
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoAlertDialog(
    title: const Text('聊天室名稱'),
    content: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CupertinoTextField(
        controller: _title,
        placeholder: '可選填',
        autofocus: true,
      ),
    ),
    actions: [
      CupertinoDialogAction(
        onPressed: () => Navigator.pop(context, ''),
        child: const Text('略過'),
      ),
      CupertinoDialogAction(
        onPressed: () => Navigator.pop(context, _title.text),
        child: const Text('確定'),
      ),
    ],
  );
}
