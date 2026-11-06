import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../shared/system_symbol.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({
    required this.auth,
    this.scrollController,
    super.key,
  });
  final AuthController auth;
  final ScrollController? scrollController;
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _resetStep = false;
  bool _busy = false;
  String? _error;
  bool get _canProceed => _resetStep
      ? _password.text.isNotEmpty && _confirm.text.isNotEmpty
      : _name.text.trim().isNotEmpty && _email.text.trim().isNotEmpty;
  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _email, _password, _confirm]) {
      controller.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _next() async {
    setState(() => _error = null);
    if (!_resetStep) {
      if (_name.text.trim().isEmpty || !isEmail(_email.text)) {
        setState(() => _error = '請輸入姓名與有效的電子郵件地址');
        return;
      }
      // 與 Swift 相同，第一步只做本機格式驗證，實際驗證由重設 API 完成。
      setState(() => _resetStep = true);
      return;
    }
    if (_password.text.length < 8 || _password.text != _confirm.text) {
      setState(
        () => _error = _password.text.length < 8 ? '密碼至少需要8個字符' : '密碼不一致',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.auth.resetPassword(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('重設密碼成功'),
          content: const Text('請使用新密碼登入'),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('確定'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      leading: _resetStep
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              onPressed: _busy
                  ? null
                  : () => setState(() => _resetStep = false),
              child: const Text('返回'),
            )
          : null,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
    ),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.lightYellow, CupertinoColors.white],
        ),
      ),
      child: SafeArea(
        child: WebContentFrame(
          maxWidth: 560,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              controller: widget.scrollController,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        SystemSymbol(
                          _resetStep ? 'lock.rotation' : 'key.fill',
                          size: 60,
                          color: AppColors.orange,
                          fallback: CupertinoIcons.lock_fill,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _resetStep ? '設定新密碼' : '重置密碼',
                          style: const TextStyle(
                            fontSize: 24,
                            fontFamily: 'CupertinoSystemDisplay',
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _resetStep
                                ? '請輸入新的密碼並再次確認，送出後會返回登入主畫面'
                                : '請先輸入您的姓名與電子郵件，我們會帶您進入設定新密碼頁面',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              height: 1.2,
                              fontSize: 16,
                              color: AppColors.mediumBrown,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!_resetStep) ...[
                          AuthField('姓名', controller: _name),
                          const SizedBox(height: 20),
                          AuthField(
                            '電子郵件',
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ] else ...[
                          AuthField(
                            '新密碼',
                            controller: _password,
                            secure: true,
                            showStrength: true,
                          ),
                          const SizedBox(height: 20),
                          AuthField(
                            '確認新密碼',
                            controller: _confirm,
                            secure: true,
                          ),
                        ],
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        AuthAction(
                          _resetStep ? '完成重設' : '下一步',
                          busy: _busy,
                          onPressed: _canProceed ? _next : null,
                        ),
                        const Spacer(),
                        if (!_resetStep)
                          CupertinoButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('返回登入'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
