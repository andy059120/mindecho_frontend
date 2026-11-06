import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../core/network/api_client.dart';
import '../../shared/system_symbol.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';
import 'privacy_page.dart';
import 'privacy_consent.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.auth, super.key});
  final AuthController auth;
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _Contact {
  final name = TextEditingController();
  final relation = TextEditingController();
  final info = TextEditingController();
  bool get empty =>
      name.text.trim().isEmpty &&
      relation.text.trim().isEmpty &&
      info.text.trim().isEmpty;
  bool get valid =>
      name.text.trim().isNotEmpty &&
      relation.text.trim().isNotEmpty &&
      info.text.trim().isNotEmpty;
  Map<String, String> get json => {
    'name': name.text.trim(),
    'relation': relation.text.trim(),
    'contactInfo': info.text.trim(),
  };
  void dispose() {
    name.dispose();
    relation.dispose();
    info.dispose();
  }
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _quote = TextEditingController();
  final _contacts = [_Contact()];
  final _scroll = ScrollController();
  final _retired = <_Contact>[];
  String _gender = '';
  int _education = 0;
  DateTime? _birth;
  int _step = 0;
  final _agreements = List<bool>.filled(privacyConsentStatements.length, false);
  bool get _agree => _agreements.every((accepted) => accepted);
  bool _busy = false;
  String? _error;
  bool get _basicValid =>
      isEmail(_email.text) &&
      _password.text.trim().length >= 8 &&
      _password.text == _confirm.text;
  bool get _personalValid =>
      _name.text.trim().isNotEmpty &&
      _birth != null &&
      _gender.isNotEmpty &&
      _education > 0 &&
      _quote.text.trim().isNotEmpty &&
      _contacts.any((c) => c.valid) &&
      _contacts.every((c) => c.empty || c.valid);
  @override
  void initState() {
    super.initState();
    for (final controller in [
      _email,
      _password,
      _confirm,
      _name,
      _nickname,
      _quote,
    ]) {
      controller.addListener(_changed);
    }
    _listenContact(_contacts.first);
  }

  void _listenContact(_Contact contact) {
    for (final c in [contact.name, contact.relation, contact.info]) {
      c.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_email, _password, _confirm, _name, _nickname, _quote]) {
      c.dispose();
    }
    for (final c in [..._contacts, ..._retired]) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _changeStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _error = null;
    });
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    if (!_personalValid || !_agree || _busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final contacts = _contacts
        .where((c) => !c.empty)
        .map((c) => c.json)
        .toList();
    final body = <String, dynamic>{
      'email': _email.text.trim(),
      'password': _password.text,
      'name': _name.text.trim(),
      'dateOfBirth':
          '${_birth!.year}-${_birth!.month.toString().padLeft(2, '0')}-01',
      'birthYear': _birth!.year,
      'birthMonth': _birth!.month,
      if (_nickname.text.trim().isNotEmpty) 'nickname': _nickname.text.trim(),
      'emergencyContacts': contacts,
      'gender': _gender,
      'educationLevel': _education,
      'dataAnalysisConsent': false,
      'supportContactName': contacts.first['name'],
      'supportContactInfo': contacts.first['contactInfo'],
      'mostImportantReasons': _quote.text.trim(),
    };
    try {
      await widget.auth.register(body);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on PlatformException {
      if (mounted) setState(() => _error = '無法儲存登入資訊，請重新嘗試');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickBirth() async {
    final selected = await showCupertinoSheet<DateTime>(
      context: context,
      scrollableBuilder: (_, _) => _BirthPicker(initial: _birth),
    );
    if (mounted && selected != null) setState(() => _birth = selected);
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: authGradient),
      child: SafeArea(
        child: WebContentFrame(
          maxWidth: 560,
          child: LayoutBuilder(
            builder: (context, constraints) => SizedBox(
              height: constraints.maxHeight,
              child: SingleChildScrollView(
                controller: _scroll,
                child: Column(
                  children: [
                    SizedBox(
                      height: math.max(180.0, constraints.maxHeight * 0.25),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Row(
                              children: [
                                const AuthClose(),
                                const Spacer(),
                                for (var i = 0; i < 2; i++)
                                  Container(
                                    width: 30,
                                    height: 4,
                                    margin: EdgeInsets.only(
                                      left: i == 0 ? 0 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(2),
                                      color: i <= _step
                                          ? AppColors.orange
                                          : AppColors.lightBrown.withValues(
                                              alpha: 0.3,
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const AuthBrand(),
                          const SizedBox(height: 8),
                          Text(
                            _step == 0 ? '創建您的帳戶' : '完善個人信息',
                            style: const TextStyle(
                              fontSize: 20,
                              fontFamily: 'CupertinoSystemDisplay',
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkBrown,
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AuthCard(
                        registration: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _step == 0 ? '基本信息' : '個人信息',
                              style: const TextStyle(
                                fontSize: 24,
                                fontFamily: 'CupertinoSystemDisplay',
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBrown,
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_step == 0) ...[
                              AuthField(
                                '電子郵件',
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 20),
                              AuthField(
                                '密碼',
                                controller: _password,
                                secure: true,
                                showStrength: true,
                              ),
                              const SizedBox(height: 20),
                              AuthField(
                                '確認密碼',
                                controller: _confirm,
                                secure: true,
                                error:
                                    _confirm.text.isNotEmpty &&
                                        _password.text != _confirm.text
                                    ? '密碼不一致'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              AuthAction(
                                '下一步',
                                onPressed: _basicValid
                                    ? () => _changeStep(1)
                                    : null,
                              ),
                            ] else ...[
                              AuthField('姓名', controller: _name),
                              const SizedBox(height: 20),
                              AuthField('暱稱（選填）', controller: _nickname),
                              const SizedBox(height: 20),
                              _label('生理性別'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  for (final gender in ['男', '女', '其他'])
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: _choice(
                                          gender,
                                          _gender == gender,
                                          () =>
                                              setState(() => _gender = gender),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _label('教育程度'),
                              const SizedBox(height: 8),
                              for (var i = 0; i < _educationOptions.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _choice(
                                    _educationOptions[i],
                                    _education == i + 1,
                                    () => setState(() => _education = i + 1),
                                  ),
                                ),
                              const SizedBox(height: 10),
                              _label('出生年月'),
                              const SizedBox(height: 8),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                onPressed: _pickBirth,
                                child: Row(
                                  children: [
                                    Text(
                                      _birth == null
                                          ? '選擇出生年月'
                                          : '${_birth!.year}-${_birth!.month.toString().padLeft(2, '0')}',
                                      style: const TextStyle(
                                        height: 1.2,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.mediumBrown,
                                      ),
                                    ),
                                    const Spacer(),
                                    const SystemSymbol(
                                      'calendar',
                                      size: 16,
                                      color: AppColors.orange,
                                      fallback: CupertinoIcons.calendar,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                '緊急聯絡人',
                                style: TextStyle(
                                  height: 1.2,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                              const SizedBox(height: 14),
                              for (var i = 0; i < _contacts.length; i++) ...[
                                _label('聯絡人 ${i + 1}'),
                                const SizedBox(height: 10),
                                AuthField('姓名', controller: _contacts[i].name),
                                const SizedBox(height: 10),
                                AuthField(
                                  '關係',
                                  controller: _contacts[i].relation,
                                ),
                                const SizedBox(height: 10),
                                AuthField(
                                  '聯絡方式',
                                  controller: _contacts[i].info,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 14),
                              ],
                              Wrap(
                                spacing: 8,
                                children: [
                                  CupertinoButton(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    color: AppColors.orange.withValues(
                                      alpha: 0.2,
                                    ),
                                    minimumSize: Size.zero,
                                    onPressed: _contacts.length >= 3
                                        ? null
                                        : () => setState(() {
                                            final contact = _Contact();
                                            _listenContact(contact);
                                            _contacts.add(contact);
                                          }),
                                    child: const Text(
                                      '⊕ 新增聯絡人',
                                      style: TextStyle(
                                        height: 1.2,
                                        fontSize: 12,
                                        color: AppColors.title,
                                      ),
                                    ),
                                  ),
                                  if (_contacts.length > 1)
                                    CupertinoButton(
                                      padding: const EdgeInsets.all(8),
                                      minimumSize: Size.zero,
                                      onPressed: () => setState(
                                        () => _retired.add(
                                          _contacts.removeLast(),
                                        ),
                                      ),
                                      child: const Text(
                                        '⊖ 移除最後一位',
                                        style: TextStyle(
                                          height: 1.2,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '至少填寫 1 位緊急聯絡人，可增加至最多 3 位。',
                                style: TextStyle(
                                  height: 1.2,
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                              const SizedBox(height: 20),
                              _label('對我很重要的一段話'),
                              const SizedBox(height: 8),
                              CupertinoTextField(
                                controller: _quote,
                                minLines: 5,
                                maxLines: 5,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.white,
                                  border: Border.all(
                                    color: AppColors.lightBrown.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _label('附錄 A：使用聲明（簡要重點）'),
                              const SizedBox(height: 8),
                              const Text('請逐項閱讀並勾選，全部同意後即可建立帳號。'),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                onPressed: () => showPrivacy(context),
                                child: const Text('查看隱私權保護政策與使用聲明'),
                              ),
                              for (
                                var i = 0;
                                i < privacyConsentStatements.length;
                                i++
                              )
                                Semantics(
                                  checked: _agreements[i],
                                  child: CupertinoButton(
                                    key: ValueKey('privacy-consent-$i'),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    onPressed: _busy
                                        ? null
                                        : () => setState(() {
                                            _agreements[i] = !_agreements[i];
                                          }),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          _agreements[i]
                                              ? CupertinoIcons
                                                    .checkmark_square_fill
                                              : CupertinoIcons.square,
                                          color: AppColors.orange,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            privacyConsentStatements[i],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              height: 1.5,
                                              color: AppColors.mediumBrown,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 24),
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: CupertinoColors.systemRed,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              AuthAction(
                                '創建帳戶',
                                busy: _busy,
                                onPressed: _personalValid && _agree
                                    ? _submit
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              AuthAction(
                                '返回上一步',
                                onPressed: _busy ? null : () => _changeStep(0),
                                secondary: true,
                                height: 48,
                                fontSize: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 34),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '已經有帳戶了？',
                            style: TextStyle(
                              height: 1.2,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.mediumBrown,
                            ),
                          ),
                          CupertinoButton(
                            padding: const EdgeInsets.only(left: 4),
                            minimumSize: Size.zero,
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              '立即登入',
                              style: TextStyle(
                                height: 1.2,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
    ),
  );
  Widget _label(String label) => Text(
    label,
    style: const TextStyle(
      height: 1.2,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.darkBrown,
    ),
  );
  Widget _choice(String label, bool selected, VoidCallback onPressed) =>
      Container(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lightYellow.withValues(alpha: 0.7)
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.lightBrown.withValues(alpha: 0.5),
          ),
        ),
        child: CupertinoButton(
          onPressed: onPressed,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: Size.zero,
          child: Row(
            children: [
              SystemSymbol(
                selected ? 'largecircle.fill.circle' : 'circle',
                size: 16,
                color: selected ? AppColors.orange : AppColors.mediumBrown,
                fallback: selected
                    ? CupertinoIcons.largecircle_fill_circle
                    : CupertinoIcons.circle,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    height: 1.2,
                    fontSize: 14,
                    color: AppColors.darkBrown,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

const _educationOptions = [
  '小學(或同等學歷)或以下',
  '初級中學或初級職業學校(或同等學歷)',
  '高級中學或高級職業學校(或同等學歷)',
  '大學或專科、技術學院(或同等學歷)',
  '研究所或以上(碩博士)',
];

class _BirthPicker extends StatefulWidget {
  const _BirthPicker({this.initial});
  final DateTime? initial;
  @override
  State<_BirthPicker> createState() => _BirthPickerState();
}

class _BirthPickerState extends State<_BirthPicker> {
  late int _year = widget.initial?.year ?? DateTime.now().year;
  late int _month = widget.initial?.month ?? DateTime.now().month;
  late final _years = FixedExtentScrollController(initialItem: _year - 1900);
  late final _months = FixedExtentScrollController(initialItem: _month - 1);
  @override
  void dispose() {
    _years.dispose();
    _months.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
    ),
    child: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              '選擇您的出生年月',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'CupertinoSystemDisplay',
                fontWeight: FontWeight.w600,
                color: AppColors.darkBrown,
              ),
            ),
          ),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _years,
                    itemExtent: 32,
                    onSelectedItemChanged: (i) =>
                        setState(() => _year = 1900 + i),
                    children: List.generate(
                      DateTime.now().year - 1899,
                      (i) => Text('${1900 + i}年'),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _months,
                    itemExtent: 32,
                    onSelectedItemChanged: (i) =>
                        setState(() => _month = i + 1),
                    children: List.generate(12, (i) => Text('${i + 1}月')),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: AuthAction(
              '確認',
              onPressed: () {
                final now = DateTime.now();
                Navigator.pop(
                  context,
                  DateTime(
                    _year,
                    _year == now.year && _month > now.month
                        ? now.month
                        : _month,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
