import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../shared/system_symbol.dart';

const authGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.lightYellow, CupertinoColors.white],
);

class AuthBrand extends StatelessWidget {
  const AuthBrand({this.size = 32, this.iconSize = 28, super.key});
  final double size;
  final double iconSize;
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SystemSymbol(
          'brain.head.profile',
          size: iconSize,
          weight: 'bold',
          color: AppColors.orange,
          fallback: CupertinoIcons.person_crop_circle,
        ),
        const SizedBox(width: 8),
        Text(
          'PsychEcho',
          style: TextStyle(
            fontSize: size,
            fontFamily: 'CupertinoSystemDisplay',
            fontWeight: FontWeight.bold,
            color: AppColors.darkBrown,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
      ],
    ),
  );
}

class AuthAction extends StatelessWidget {
  const AuthAction(
    this.title, {
    required this.onPressed,
    this.height = 56,
    this.fontSize = 18,
    this.textOnly = false,
    this.secondary = false,
    this.busy = false,
    super.key,
  });
  final String title;
  final VoidCallback? onPressed;
  final double height;
  final double fontSize;
  final bool textOnly;
  final bool secondary;
  final bool busy;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: secondary
            ? Border.all(color: AppColors.orange, width: 2)
            : null,
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        borderRadius: BorderRadius.circular(12),
        color: textOnly
            ? null
            : secondary
            ? CupertinoColors.white
            : AppColors.orange,
        disabledColor: CupertinoColors.systemGrey.withValues(alpha: 0.18),
        onPressed: busy || onPressed == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onPressed!();
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (busy) ...[
              const CupertinoActivityIndicator(color: CupertinoColors.white),
              const SizedBox(width: 8),
            ],
            Text(
              busy ? '載入中...' : title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: onPressed == null && !busy
                    ? CupertinoColors.systemGrey
                    : textOnly || secondary
                    ? AppColors.orange
                    : CupertinoColors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AuthField extends StatefulWidget {
  const AuthField(
    this.label, {
    required this.controller,
    this.secure = false,
    this.keyboardType,
    this.focusNode,
    this.onSubmitted,
    this.enabled = true,
    this.error,
    this.showStrength = false,
    this.autofillHints,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final bool secure;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final String? error;
  final bool showStrength;
  final Iterable<String>? autofillHints;
  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late final _ownFocus = FocusNode();
  bool _visible = false;
  FocusNode get _focus => widget.focusNode ?? _ownFocus;
  @override
  void initState() {
    super.initState();
    _focus.addListener(_changed);
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_changed);
    widget.controller.removeListener(_changed);
    _ownFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final password = widget.controller.text;
    final strength = password.length < 8
        ? 0
        : password.length >= 10 &&
              password.contains(
                RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"|,.<>?]'''),
              )
        ? 2
        : 1;
    final strengthColor = [
      CupertinoColors.systemRed,
      AppColors.orange,
      CupertinoColors.systemGreen,
    ][strength];
    final error = widget.error;
    final color = error != null
        ? CupertinoColors.systemRed
        : _focus.hasFocus
        ? AppColors.orange
        : AppColors.darkBrown;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (widget.showStrength && widget.controller.text.isNotEmpty)
              Row(
                children: [
                  Text(
                    ['弱', '中等', '強'][strength],
                    style: TextStyle(
                      height: 1.2,
                      fontSize: 12,
                      color: strengthColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  for (var index = 0; index < 3; index++)
                    Container(
                      width: 12,
                      height: 3,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: index <= strength
                            ? strengthColor
                            : CupertinoColors.systemGrey.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          strutStyle: const StrutStyle(
            fontFamily: 'CupertinoSystemText',
            fontSize: 16,
            height: 1.2,
            forceStrutHeight: true,
          ),
          controller: widget.controller,
          focusNode: _focus,
          placeholder: widget.label,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          obscureText: widget.secure && !_visible,
          autocorrect: false,
          enableSuggestions: !widget.secure,
          textCapitalization: TextCapitalization.none,
          autofillHints: widget.autofillHints,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.darkBrown,
            height: 1.2,
          ),
          placeholderStyle: TextStyle(
            height: 1.2,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textInputAction: widget.onSubmitted == null
              ? TextInputAction.done
              : TextInputAction.next,
          onSubmitted: widget.onSubmitted,
          decoration: BoxDecoration(
            color: _focus.hasFocus
                ? AppColors.lightYellow
                : CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: error != null
                  ? CupertinoColors.systemRed
                  : _focus.hasFocus
                  ? AppColors.orange
                  : AppColors.lightBrown.withValues(alpha: 0.5),
              width: _focus.hasFocus ? 2 : 1,
            ),
          ),
          suffix: widget.secure
              ? CupertinoButton(
                  padding: const EdgeInsets.only(right: 16),
                  minimumSize: Size.zero,
                  onPressed: () => setState(() => _visible = !_visible),
                  child: Semantics(
                    label: '顯示或隱藏密碼',
                    child: SystemSymbol(
                      _visible ? 'eye.slash.fill' : 'eye.fill',
                      size: 16,
                      weight: 'medium',
                      color: AppColors.mediumBrown,
                      fallback: CupertinoIcons.eye,
                    ),
                  ),
                )
              : null,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error,
              style: const TextStyle(
                height: 1.2,
                fontSize: 12,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
      ],
    );
  }
}

class AuthClose extends StatelessWidget {
  const AuthClose({super.key});
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () => Navigator.of(context).pop(),
    child: Semantics(
      label: '關閉',
      child: SystemSymbol(
        'xmark.circle.fill',
        size: 30,
        color: AppColors.mediumBrown.withValues(alpha: 0.6),
        fallback: CupertinoIcons.xmark_circle_fill,
      ),
    ),
  );
}

class AuthCard extends StatelessWidget {
  const AuthCard({required this.child, this.registration = false, super.key});
  final Widget child;
  final bool registration;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: registration
          ? const Color.fromRGBO(255, 247, 240, 1)
          : CupertinoColors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.darkBrown.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

bool isEmail(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
