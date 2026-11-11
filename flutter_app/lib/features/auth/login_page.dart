import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../shared/system_symbol.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';
import 'forgot_password_page.dart';
import 'privacy_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.auth, super.key});
  final AuthController auth;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _remember = false;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final email = await widget.auth.store.readRememberedEmail();
      if (mounted && _email.text.isEmpty && email != null) {
        setState(() {
          _email.text = email;
          _remember = true;
        });
      }
    } on PlatformException {
      /* 記住帳號失敗不影響手動登入。 */
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    if (!isEmail(_email.text) || _password.text.isEmpty) {
      setState(() => _error = '請輸入有效的電子郵件與密碼');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.login(
        _email.text.trim(),
        _password.text,
        remember: _remember,
      );
      TextInput.finishAutofillContext();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on PlatformException {
      if (mounted) setState(() => _error = '無法儲存登入資訊，請重新嘗試');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _register() => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RegisterPage(auth: widget.auth),
    ),
  );
  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: authGradient),
      child: SafeArea(
        child: ContentFrame(
          maxWidth: 560,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxHeight;
              final header = math.max(
                224.0,
                height * 0.3 - MediaQuery.viewInsetsOf(context).bottom * 0.3,
              );
              return SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: header,
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Row(children: [AuthClose()]),
                          ),
                          const SizedBox(height: 16),
                          const Spacer(),
                          const SizedBox(height: 16),
                          const Column(
                            children: [
                              AuthBrand(size: 36, iconSize: 32),
                              SizedBox(height: 12),
                              Text(
                                '歡迎回來',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontFamily: 'CupertinoSystemDisplay',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkBrown,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                '登入您的帳戶繼續使用',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.mediumBrown,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Spacer(),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height * 0.7),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: AuthCard(
                              child: AutofillGroup(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      '登入',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontFamily: 'CupertinoSystemDisplay',
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkBrown,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    AuthField(
                                      '電子郵件',
                                      controller: _email,
                                      enabled: !_busy,
                                      keyboardType: TextInputType.emailAddress,
                                      autofillHints: const [
                                        AutofillHints.username,
                                      ],
                                      onSubmitted: (_) =>
                                          _passwordFocus.requestFocus(),
                                    ),
                                    const SizedBox(height: 20),
                                    AuthField(
                                      '密碼',
                                      controller: _password,
                                      secure: true,
                                      enabled: !_busy,
                                      focusNode: _passwordFocus,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onSubmitted: (_) => _login(),
                                    ),
                                    const SizedBox(height: 24),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      onPressed: _busy
                                          ? null
                                          : () => setState(
                                              () => _remember = !_remember,
                                            ),
                                      child: Row(
                                        children: [
                                          SystemSymbol(
                                            _remember
                                                ? 'checkmark.square.fill'
                                                : 'square',
                                            size: 18,
                                            color: _remember
                                                ? AppColors.orange
                                                : AppColors.mediumBrown
                                                      .withValues(alpha: 0.7),
                                            fallback: _remember
                                                ? CupertinoIcons
                                                      .checkmark_square_fill
                                                : CupertinoIcons.square,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            '記住帳號',
                                            style: TextStyle(
                                              height: 1.2,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.darkBrown,
                                            ),
                                          ),
                                          const Spacer(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        onPressed: () =>
                                            showCupertinoSheet<void>(
                                              context: context,
                                              scrollableBuilder:
                                                  (_, controller) =>
                                                      ForgotPasswordPage(
                                                        auth: widget.auth,
                                                        scrollController:
                                                            controller,
                                                      ),
                                            ),
                                        child: const Text(
                                          '忘記密碼？',
                                          style: TextStyle(
                                            height: 1.2,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_error != null) ...[
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemRed
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          _error!,
                                          style: const TextStyle(
                                            height: 1.2,
                                            fontSize: 14,
                                            color: CupertinoColors.systemRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                    AuthAction(
                                      '登入',
                                      onPressed: _login,
                                      busy: _busy,
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      '登入即表示您已閱讀並同意 PsychEcho 隱私權保護政策與使用聲明。',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.2,
                                        color: AppColors.mediumBrown.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _privacy(13),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 34),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      '還沒有帳戶？',
                                      style: TextStyle(
                                        height: 1.2,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.mediumBrown,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      onPressed: _register,
                                      child: const Text(
                                        '立即註冊',
                                        style: TextStyle(
                                          height: 1.2,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Opacity(
                                  opacity: 0.7,
                                  child: Column(
                                    children: [
                                      Text(
                                        '繼續即表示您同意我們的服務條款和隱私政策',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          height: 1.2,
                                          fontSize: 12,
                                          color: AppColors.mediumBrown
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _privacy(12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
  Widget _privacy(double fontSize) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () => showPrivacy(context),
    child: Text(
      '查看隱私權保護政策與使用聲明',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
    ),
  );
}
