import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/welcome_page.dart';
import '../features/chat/chat_content.dart';
import '../features/dashboard/catalog.dart';
import '../core/storage/account_store.dart';
import 'main_shell.dart';
import '../shared/widgets.dart';
import 'theme.dart';

class MindEchoApp extends StatefulWidget {
  const MindEchoApp({
    required this.auth,
    this.content,
    this.catalog,
    this.accountStore,
    super.key,
  });
  final AuthController auth;
  final ChatContent? content;
  final DashboardCatalog? catalog;
  final AccountStore? accountStore;
  @override
  State<MindEchoApp> createState() => _MindEchoAppState();
}

class _MindEchoAppState extends State<MindEchoApp> {
  ChatContent? _content;
  DashboardCatalog? _catalog;
  String? _error;
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _error = null);
    try {
      final content = widget.content ?? await ChatContent.load();
      final catalog = widget.catalog ?? await DashboardCatalog.load();
      await widget.auth.restore();
      if (mounted) {
        setState(() {
          _content = content;
          _catalog = catalog;
        });
      }
    } catch (error) {
      debugPrint(
        'MindEcho 啟動失敗：${error.runtimeType}'
        '${error is PlatformException ? ' (${error.code})' : ''}',
      );
      if (mounted) setState(() => _error = '無法載入應用程式資料，請重新嘗試');
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.auth,
    builder: (context, _) => CupertinoApp(
      // 登出後重建 Navigator，同時移除已推入的聊天室與敏感畫面。
      key: ValueKey(widget.auth.session == null ? 'guest' : 'authenticated'),
      title: 'MindEcho',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      builder: (context, child) => kIsWeb
          ? ColoredBox(
              color: const Color(0xFFF3F0EC),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: child!,
                ),
              ),
            )
          : child!,
      locale: const Locale.fromSubtags(
        languageCode: 'zh',
        scriptCode: 'Hant',
        countryCode: 'TW',
      ),
      supportedLocales: const [
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
          countryCode: 'TW',
        ),
      ],
      localizationsDelegates: GlobalCupertinoLocalizations.delegates,
      home: _error != null
          ? CupertinoPageScaffold(
              child: Center(child: ErrorNotice(_error!, onRetry: _initialize)),
            )
          : _content == null
          ? const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()),
            )
          : widget.auth.session == null
          ? WelcomePage(auth: widget.auth)
          : MainShell(
              auth: widget.auth,
              content: _content!,
              catalog: _catalog!,
              store: widget.accountStore,
            ),
    ),
  );
}
