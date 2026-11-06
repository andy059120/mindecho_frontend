import '../../core/network/api_client.dart';

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/widgets.dart';
import 'chat_content.dart';
import 'chat_models.dart';
import 'chat_repository.dart';
import 'chat_visuals.dart';

class ChatDetailPage extends StatefulWidget {
  const ChatDetailPage({
    required this.session,
    required this.repository,
    required this.content,
    super.key,
  });
  final ChatSession session;
  final ChatRepository repository;
  final ChatContent content;
  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final _text = TextEditingController();
  final _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _ended = false;
  ChatMode? _recommended;
  String? _error;
  bool _historyFailed = false;
  bool _sendUncertain = false;
  bool _quickReplies = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final messages = await widget.repository.history(widget.session.id);
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _historyFailed = false;
        _sendUncertain = false;
      });
      _scrollToEnd();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _historyFailed = true;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _send() async {
    final message = _text.text.trim();
    if (_sending ||
        _loading ||
        _historyFailed ||
        _sendUncertain ||
        _ended ||
        message.isEmpty) {
      return;
    }
    if (widget.content.containsCrisisTerms(message)) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('需要立即協助嗎？'),
          content: const Text('偵測到您提及嚴重負面/自傷意念。如果您正處於危險或緊急情況，請立即尋求協助。'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showContacts();
              },
              child: const Text('前往緊急聯絡資訊'),
            ),
          ],
        ),
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      // 不自動重試 POST，避免回應逾時時重複建立使用者訊息。
      final result = await widget.repository.send(widget.session.id, message);
      if (!mounted) return;
      final reply = result['reply'] as String;
      final initial = result['initialMode'] as Map<String, dynamic>?;
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            content: message,
            isFromUser: true,
          ),
        );
        _messages.add(
          ChatMessage(
            id: result['messageId'] as String? ?? 'reply-${_messages.length}',
            content: reply,
            isFromUser: false,
          ),
        );
        _text.clear();
        _ended = initial?['sessionEnded'] == true;
        _recommended = initial?['selectedMode'] == null
            ? null
            : ChatMode.parse(initial!['selectedMode'] as String);
      });
      _scrollToEnd();
    } catch (error) {
      if (mounted) {
        setState(() {
          _sendUncertain = true;
          _error =
              '${error is ApiException ? error.message : '伺服器回應格式異常'}。\n未能確認訊息傳送結果，請先重新載入紀錄，確認後再傳送。';
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showContacts() async {
    final user = widget.repository.auth.session?.user ?? {};
    final contacts = (user['emergencyContacts'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('緊急聯絡資訊'),
        message: Text(
          contacts.isEmpty
              ? '目前尚未設定緊急聯絡人。請聯絡您信任的親友，或尋求當地緊急協助。'
              : contacts
                    .map(
                      (contact) =>
                          '${contact['name']}（${contact['relation']}）\n${contact['contactInfo']}',
                    )
                    .join('\n\n'),
        ),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('關閉'),
        ),
      ),
    );
  }

  Future<void> _handoff() async {
    final nextMode = _recommended;
    if (nextMode == null || _sending) return;
    setState(() => _sending = true);
    try {
      final next = await widget.repository.create(nextMode, '');
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        CupertinoPageRoute<void>(
          builder: (_) => ChatDetailPage(
            session: next,
            repository: widget.repository,
            content: widget.content,
          ),
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    backgroundColor: CupertinoColors.white,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.chevron_left,
                        size: 20,
                        color: AppColors.userBubble,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '返回',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.userBubble,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        widget.session.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.session.mode.displayTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: () => showCupertinoSheet<bool>(
                    context: context,
                    scrollableBuilder: (_, _) =>
                        ModeIntroductionPage(mode: widget.session.mode),
                  ),
                  child: const Icon(
                    CupertinoIcons.info_circle,
                    size: 20,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                for (final mode in ChatMode.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: mode == widget.session.mode ? mode.color : null,
                        border: Border.all(color: mode.color),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        mode == ChatMode.initial ? '初始' : mode.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: mode == widget.session.mode
                              ? CupertinoColors.white
                              : mode.color,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: .5, color: CupertinoColors.separator),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(),
            ),
          Expanded(
            child: ColoredBox(
              color: AppColors.chatBackground,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  if (_messages.isEmpty && !_loading && !_historyFailed)
                    _bubble(
                      ChatMessage(
                        id: 'welcome',
                        content:
                            widget.content.welcomes[widget
                                    .session
                                    .mode
                                    .apiValue]
                                as String,
                        isFromUser: false,
                      ),
                    ),
                  ..._messages.map(_bubble),
                  if (_error != null)
                    ErrorNotice(_error!, onRetry: _sending ? null : _load),
                  if (_ended)
                    Surface(
                      child: Column(
                        children: [
                          const Text('初談已結束'),
                          if (_recommended != null)
                            CupertinoButton(
                              onPressed: _sending ? null : _handoff,
                              child: Text('開始${_recommended!.title}對話'),
                            ),
                          CupertinoButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('回到聊天頁面'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.bottomCenter,
            child: _quickReplies
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: AppColors.chatBackground.withValues(alpha: .5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '快速回覆',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: widget.session.mode.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              for (final reply
                                  in widget.session.mode.quickReplies)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    onPressed: () {
                                      _text.text = reply;
                                      setState(() => _quickReplies = false);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: CupertinoColors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: widget.session.mode.color
                                              .withValues(alpha: .3),
                                        ),
                                      ),
                                      child: Text(
                                        reply,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: widget.session.mode.color,
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
                  )
                : const SizedBox.shrink(),
          ),
          if (_sending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              color: AppColors.chatBackground,
              child: Row(
                children: [
                  CupertinoActivityIndicator(color: widget.session.mode.color),
                  const SizedBox(width: 8),
                  Text(
                    '訊息傳送中，請稍候...',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: widget.session.mode.color,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.chatBackground,
              border: Border(
                top: BorderSide(color: Color(0x4D8E8E93), width: .5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  onPressed: _sending || _ended
                      ? null
                      : () => setState(() => _quickReplies = !_quickReplies),
                  child: Icon(
                    _quickReplies
                        ? CupertinoIcons.xmark_circle
                        : CupertinoIcons.plus_circle,
                    size: 22,
                    color: _quickReplies
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: _text,
                    builder: (context, value, _) => CupertinoTextField(
                      controller: _text,
                      placeholder: widget.session.mode.placeholder,
                      placeholderStyle: const TextStyle(
                        fontSize: 17,
                        height: 1.2,
                        color: CupertinoColors.placeholderText,
                      ),
                      suffix: value.text.characters.length > 100
                          ? Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Text(
                                '${value.text.characters.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.2,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            )
                          : null,
                      minLines: 1,
                      maxLines: 4,
                      enabled:
                          !_sending &&
                          !_loading &&
                          !_historyFailed &&
                          !_sendUncertain &&
                          !_ended,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.2,
                        color: CupertinoColors.label,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: value.text.trim().isEmpty
                              ? CupertinoColors.systemGrey.withValues(alpha: .3)
                              : widget.session.mode.color.withValues(alpha: .5),
                          width: value.text.trim().isEmpty ? 1 : 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder(
                  valueListenable: _text,
                  builder: (context, value, _) => CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed:
                        _sending ||
                            _loading ||
                            _historyFailed ||
                            _sendUncertain ||
                            _ended ||
                            value.text.trim().isEmpty
                        ? null
                        : _send,
                    child: _sending
                        ? const CupertinoActivityIndicator()
                        : Icon(
                            value.text.trim().isEmpty
                                ? CupertinoIcons.arrow_up_circle
                                : CupertinoIcons.arrow_up_circle_fill,
                            size: 24,
                            color: value.text.trim().isEmpty
                                ? CupertinoColors.systemGrey
                                : widget.session.mode.color,
                            semanticLabel: '傳送訊息',
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

  Widget _bubble(ChatMessage message) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: message.isFromUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (!message.isFromUser) ...[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.session.mode.color.withValues(alpha: .2),
            ),
            child: Text(
              widget.session.mode == ChatMode.initial
                  ? '初始'
                  : widget.session.mode.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.session.mode.color,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.sizeOf(context).width -
                  (message.isFromUser ? 40 : 88),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: message.isFromUser
                  ? AppColors.userBubble
                  : CupertinoColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(message.isFromUser ? 20 : 0),
                bottomRight: Radius.circular(message.isFromUser ? 0 : 20),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.2,
                color: message.isFromUser
                    ? CupertinoColors.white
                    : AppColors.title,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
