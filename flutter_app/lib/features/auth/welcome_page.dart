import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../app/theme.dart';
import '../../shared/responsive_layout.dart';
import '../../shared/system_symbol.dart';
import 'auth_controller.dart';
import 'auth_widgets.dart';
import 'login_page.dart';
import 'privacy_page.dart';
import 'register_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({required this.auth, super.key});
  final AuthController auth;
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..forward();
  final _pager = PageController();
  int _page = 0;
  @override
  void dispose() {
    _animation.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _login() => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => LoginPage(auth: widget.auth),
    ),
  );
  void _register() => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => RegisterPage(auth: widget.auth),
    ),
  );

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lightYellow,
            Color.lerp(CupertinoColors.white, AppColors.lightYellow, 0.8)!,
            CupertinoColors.white,
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(16) > 19;
            final height = math.max(
              constraints.maxHeight,
              largeText ? 1000.0 : 720.0,
            );
            final body = SizedBox(
              height: height,
              child: Column(
                children: [
                  SizedBox(
                    height: height * 0.75,
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animation,
                        curve: const Interval(
                          0.125,
                          0.625,
                          curve: Curves.easeOut,
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 50, bottom: 20),
                            child: Column(
                              children: [
                                const AuthBrand(),
                                const SizedBox(height: 8),
                                Text(
                                  '心理健康的智慧夥伴',
                                  style: TextStyle(
                                    height: 1.2,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.mediumBrown.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PageView.builder(
                              controller: _pager,
                              itemCount: _pages.length,
                              onPageChanged: (index) =>
                                  setState(() => _page = index),
                              itemBuilder: (context, index) =>
                                  _WelcomeSlide(_pages[index]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                4,
                                (index) => Padding(
                                  padding: EdgeInsets.only(
                                    right: index == 3 ? 0 : 8,
                                  ),
                                  child: Semantics(
                                    label: '第 ${index + 1} 頁',
                                    selected: _page == index,
                                    button: true,
                                    child: GestureDetector(
                                      onTap: () => _pager.animateToPage(
                                        index,
                                        duration: const Duration(
                                          milliseconds: 500,
                                        ),
                                        curve: Curves.easeInOut,
                                      ),
                                      child: Transform.scale(
                                        scale: _page == index ? 1.2 : 1,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _page == index
                                                ? AppColors.orange
                                                : AppColors.lightBrown
                                                      .withValues(alpha: 0.5),
                                          ),
                                        ),
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
                  ),
                  SizedBox(
                    height: height * 0.25,
                    child: OverflowBox(
                      minHeight: 0,
                      maxHeight: double.infinity,
                      alignment: Alignment.center,
                      child: FadeTransition(
                        opacity: CurvedAnimation(
                          parent: _animation,
                          curve: const Interval(
                            0.625,
                            1,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: ContentFrame(
                          maxWidth: 560,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AuthAction('立即登入', onPressed: _login),
                                const SizedBox(height: 20),
                                AuthAction(
                                  '建立新帳號',
                                  onPressed: _register,
                                  textOnly: true,
                                  height: 48,
                                  fontSize: 16,
                                ),
                                const SizedBox(height: 20),
                                Opacity(
                                  opacity: 0.7,
                                  child: Column(
                                    children: [
                                      Text(
                                        '繼續即表示您同意我們的',
                                        style: TextStyle(
                                          height: 1.2,
                                          fontSize: 12,
                                          color: AppColors.mediumBrown
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          _legalButton(context, '服務條款'),
                                          const SizedBox(width: 16),
                                          Text(
                                            '和',
                                            style: TextStyle(
                                              height: 1.2,
                                              fontSize: 12,
                                              color: AppColors.mediumBrown
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          _legalButton(context, '隱私政策'),
                                        ],
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
                ],
              ),
            );
            if (ResponsiveLayout.useSidebar(context)) {
              return Row(
                children: [
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AuthBrand(size: 40, iconSize: 36),
                            const SizedBox(height: 32),
                            const Text(
                              '心理健康的智慧夥伴',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBrown,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '記錄心情、整理感受，\n用自己的步調，慢慢認識自己。',
                              style: TextStyle(
                                fontSize: 19,
                                height: 1.8,
                                color: AppColors.mediumBrown,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'AI 情緒陪伴與自我探索輔助工具。\n無法取代醫療診斷、心理諮商或緊急救援。',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.7,
                                color: AppColors.mediumBrown,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _legalButton(context, '隱私政策'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ContentFrame(
                      maxWidth: 520,
                      child: SingleChildScrollView(child: body),
                    ),
                  ),
                ],
              );
            }
            return ContentFrame(
              maxWidth: double.infinity,
              child: height > constraints.maxHeight
                  ? SingleChildScrollView(child: body)
                  : body,
            );
          },
        ),
      ),
    ),
  );

  Widget _legalButton(BuildContext context, String label) => CupertinoButton(
    padding: EdgeInsets.zero,
    minimumSize: Size.zero,
    onPressed: () => showPrivacy(context),
    child: Text(
      label,
      style: const TextStyle(
        height: 1.2,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _Slide {
  const _Slide(
    this.title,
    this.description,
    this.symbol,
    this.color,
    this.fallback,
  );
  final String title, description, symbol;
  final Color color;
  final IconData fallback;
}

const _pages = [
  _Slide(
    '專業心理支持',
    '基於認知行為療法(CBT)和正念療法(MBT)的專業對話，為您提供科學有效的心理健康指導',
    'heart.text.square',
    AppColors.orange,
    CupertinoIcons.doc_text,
  ),
  _Slide(
    '24/7 隨時陪伴',
    '無論何時何地，PsychEcho 都在這裡傾聽您的心聲，提供即時的情感支持和專業建議',
    'clock.arrow.circlepath',
    AppColors.mediumBrown,
    CupertinoIcons.clock,
  ),
  _Slide(
    '隱私安全保護',
    '對話透過加密通道傳送，並交由雲端 AI 供應商處理；資料利用與保存方式請詳閱隱私政策。',
    'lock.shield',
    AppColors.darkBrown,
    CupertinoIcons.shield,
  ),
  _Slide(
    '個性化體驗',
    'AI 會學習您的偏好和需求，為您量身定制最適合的諮商方案和對話風格',
    'person.circle.fill',
    AppColors.orange,
    CupertinoIcons.person_circle_fill,
  ),
];

class _WelcomeSlide extends StatelessWidget {
  const _WelcomeSlide(this.slide);
  final _Slide slide;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ResponsiveLayout.useSidebar(context) ? 180 : 240,
              height: ResponsiveLayout.useSidebar(context) ? 180 : 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  stops: const [50 / 120, 1],
                  colors: [
                    slide.color.withValues(alpha: 0.1),
                    slide.color.withValues(alpha: 0.05),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: SystemSymbol(
                slide.symbol,
                size: 80,
                weight: 'light',
                color: slide.color,
                fallback: slide.fallback,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontFamily: 'CupertinoSystemDisplay',
                fontWeight: FontWeight.bold,
                color: AppColors.darkBrown,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            ContentFrame(
              maxWidth: 720,
              child: Text(
                slide.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.mediumBrown,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
