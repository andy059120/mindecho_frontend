import SwiftUI

// MARK: - 登入頁面
struct LoginPage: View {
    
    // MARK: - 環境和狀態
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel.shared
    
    // MARK: - 表單狀態
    @State private var email = ""
    @State private var password = ""
    @State private var rememberAccount = false
    @State private var showRegisterPage = false
    @State private var showForgotPassword = false
    @State private var showPrivacyPolicy = false
    
    // MARK: - 動畫狀態
    @State private var animateContent = false
    @State private var keyboardHeight: CGFloat = 0
    
    // MARK: - 焦點管理
    @FocusState private var focusedField: FormField?
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // 頂部區域
                        headerSection
                            .frame(height: max(200, geometry.size.height * 0.3 - keyboardHeight * 0.3))
                        
                        // 主要內容區域
                        mainContentSection
                            .frame(minHeight: geometry.size.height * 0.7)
                    }
                }
                .scrollIndicators(.hidden)
                .background(backgroundGradient)
            }
            .navigationBarHidden(true)
            .loadingOverlay(
                isVisible: viewModel.isLoading,
                message: viewModel.loadingMessage.isEmpty ? "登入中..." : viewModel.loadingMessage,
                style: .spinner
            )
            .onAppear {
                startAnimation()
                loadRememberedCredentials()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation(.easeOut(duration: 0.3)) {
                        keyboardHeight = keyboardFrame.height
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    keyboardHeight = 0
                }
            }
            .onChange(of: viewModel.authState) { _, state in
                if case .authenticated = state {
                    persistRememberedCredentials()
                    dismiss()
                }
            }
        }
        .fullScreenCover(isPresented: $showRegisterPage) {
            RegisterPage()
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordPage()
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyStatementView()
        }
    }
}

// MARK: - 視圖組件
private extension LoginPage {
    
    // 背景漸變
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                AppColors.lightYellow,
                Color.white
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    // 頂部區域
    var headerSection: some View {
        VStack(spacing: 16) {
            // 關閉按鈕
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.mediumBrown.opacity(0.6))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Logo 和標題
            VStack(spacing: 12) {
                // PsychEcho Logo
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.orange)
                    
                    Text("PsychEcho")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppColors.darkBrown)
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                
                Text("歡迎回來")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .opacity(animateContent ? 1 : 0)
                
                Text("登入您的帳戶繼續使用")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mediumBrown)
                    .opacity(animateContent ? 0.8 : 0)
            }
            
            Spacer()
        }
    }
    
    // 主要內容區域
    var mainContentSection: some View {
        VStack(spacing: 0) {
            // 登入表單卡片
            loginFormCard
                .padding(.horizontal, 24)
                .offset(y: animateContent ? 0 : 50)
                .opacity(animateContent ? 1 : 0)
            
            Spacer(minLength: 20)
            
            // 底部區域
            bottomSection
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
        }
    }
    
    // 登入表單卡片
    var loginFormCard: some View {
        VStack(spacing: 24) {
            // 表單標題
            Text("登入")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 表單字段
            VStack(spacing: 20) {
                // 電子郵件輸入框
                AuthTextField(
                    field: .email,
                    text: $email,
                    isValid: true,
                    errorMessage: "",
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .email
                        }
                    },
                    onCommit: {
                        focusedField = .password
                    },
                    showValidationIcon: false
                )
                .focused($focusedField, equals: .email)
                
                // 密碼輸入框
                AuthTextField(
                    field: .password,
                    text: $password,
                    isValid: true,
                    errorMessage: "",
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .password
                        }
                    },
                    onCommit: {
                        performLogin()
                    },
                    showValidationIcon: false,
                    showPasswordStrength: false
                )
                .focused($focusedField, equals: .password)
            }

            rememberOptions
            
            // 忘記密碼鏈接
            HStack {
                Spacer()
                Button("忘記密碼？") {
                    showForgotPassword = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.orange)
            }
            
            // 錯誤和成功訊息
            if !viewModel.errorMessage.isEmpty {
                errorMessageView
            }
            
            if !viewModel.successMessage.isEmpty {
                successMessageView
            }
            
            // 登入按鈕
            LoadingButton(
                title: "登入",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.isLoading
            ) {
                performLogin()
            }

            privacyConsentSection
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: AppColors.darkBrown.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }

    var privacyConsentSection: some View {
        VStack(spacing: 10) {
            Text("登入即表示您已閱讀並同意 PsychEcho 隱私權保護政策與使用聲明。")
                .font(.system(size: 12))
                .foregroundColor(AppColors.mediumBrown.opacity(0.8))
                .multilineTextAlignment(.center)

            Button("查看隱私權保護政策與使用聲明") {
                showPrivacyPolicy = true
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(AppColors.orange)
        }
    }

    var rememberOptions: some View {
        Button {
            rememberAccount.toggle()
        } label: {
            rememberRow(
                title: "記住帳號",
                isSelected: rememberAccount
            )
        }
        .buttonStyle(.plain)
    }

    func rememberRow(title: String, isSelected: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 18))
                .foregroundColor(isSelected ? AppColors.orange : AppColors.mediumBrown.opacity(0.7))
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.darkBrown)
            Spacer()
        }
    }
    
    // 底部區域
    var bottomSection: some View {
        VStack(spacing: 16) {
            // 註冊提示
            HStack(spacing: 4) {
                Text("還沒有帳戶？")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mediumBrown)
                
                Button("立即註冊") {
                    showRegisterPage = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.orange)
            }
            .opacity(animateContent ? 1 : 0)
            
            // 服務條款
            VStack(spacing: 6) {
                Text("繼續即表示您同意我們的服務條款和隱私政策")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.mediumBrown.opacity(0.7))
                    .multilineTextAlignment(.center)

                Button("查看隱私權保護政策與使用聲明") {
                    showPrivacyPolicy = true
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.orange)
            }
            .opacity(animateContent ? 0.7 : 0)
        }
    }
    
    // 錯誤訊息視圖
    var errorMessageView: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.red)
            
            Text(viewModel.errorMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // 成功訊息視圖
    var successMessageView: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            Text(viewModel.successMessage)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - 方法
private extension LoginPage {
    
    func startAnimation() {
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            animateContent = true
        }
    }
    
    func performLogin() {
        // 隱藏鍵盤
        focusedField = nil
        
        // 🎯 真實 API 登入
        viewModel.login(email: email, password: password)
    }

    func loadRememberedCredentials() {
        let defaults = UserDefaults.standard
        rememberAccount = defaults.bool(forKey: AuthConstants.UserDefaultsKeys.shouldRememberAccount)

        if rememberAccount {
            email = defaults.string(forKey: AuthConstants.UserDefaultsKeys.rememberedEmail) ?? ""
        }
    }

    func persistRememberedCredentials() {
        let defaults = UserDefaults.standard
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        defaults.set(rememberAccount, forKey: AuthConstants.UserDefaultsKeys.shouldRememberAccount)

        if rememberAccount, !trimmedEmail.isEmpty {
            defaults.set(trimmedEmail, forKey: AuthConstants.UserDefaultsKeys.rememberedEmail)
        } else {
            defaults.removeObject(forKey: AuthConstants.UserDefaultsKeys.rememberedEmail)
        }
    }
}

struct PrivacyPolicyStatementView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                legalBackground

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        headerCard
                        summaryStrip
                        section(title: "一、前言", body: PrivacyPolicyContent.introduction, accent: .regular)
                        warningSection
                        section(title: "三、蒐集之個人資料類別", body: PrivacyPolicyContent.dataCategories, accent: .regular)
                        section(title: "四、蒐集目的與利用方式", body: PrivacyPolicyContent.purposes, accent: .regular)
                        commitmentSection
                        section(title: "五、資料之委外與第三方處理", body: PrivacyPolicyContent.thirdPartyProcessing, accent: .regular)
                        retentionSection
                        rightsSection
                        section(title: "八、未成年人保護", body: PrivacyPolicyContent.minors, accent: .regular)
                        section(title: "九、資訊安全措施", body: PrivacyPolicyContent.security, accent: .regular)
                        section(title: "十、Cookie 之使用", body: PrivacyPolicyContent.cookies, accent: .regular)
                        section(title: "十一、政策修訂", body: PrivacyPolicyContent.revisions, accent: .regular)
                        section(title: "十二、準據法與管轄", body: PrivacyPolicyContent.governingLaw, accent: .regular)
                        appendixSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("隱私政策與聲明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.orange)
                }
            }
        }
    }

    private var legalBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.99, green: 0.95, blue: 0.89),
                    Color(red: 0.98, green: 0.96, blue: 0.92),
                    Color.white
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(AppColors.orange.opacity(0.10))
                    .frame(height: 220)
                    .blur(radius: 6)
                    .offset(y: -70)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PsychEcho")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColors.orange)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.22))
                        )

                    Text("隱私權保護政策\n與使用聲明")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(5)
                }

                Spacer()

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }

            Text("當您註冊、登入或使用本服務之任何功能，即視為您已閱讀、瞭解並同意本政策之全部內容。若您不同意本政策之任何部分，請立即停止使用本服務。")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.92))
                .lineSpacing(5)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    AppColors.orange,
                    Color(red: 0.74, green: 0.42, blue: 0.18)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: AppColors.orange.opacity(0.22), radius: 18, x: 0, y: 10)
    }

    private var summaryStrip: some View {
        HStack(spacing: 10) {
            summaryPill(icon: "lock.fill", title: "個資保護")
            summaryPill(icon: "brain.head.profile", title: "AI 使用")
            summaryPill(icon: "globe", title: "跨境傳輸")
        }
    }

    private func summaryPill(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(AppColors.darkBrown)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.88))
                .overlay(
                    Capsule()
                        .stroke(AppColors.lightBrown.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var warningSection: some View {
        section(title: "二、重要警語與免責聲明（請務必詳閱）", body: PrivacyPolicyContent.warningSection, accent: .warning)
    }

    private var commitmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("我們承諾", accent: .success)

            VStack(alignment: .leading, spacing: 8) {
                Text("❌ 不會將您可識別之個人資料出售、出租或交換予任何第三方")
                Text("❌ 不會用於廣告投放或行銷分析")
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppColors.darkBrown)
            .padding(18)
            .modifier(LegalCardStyle())
        }
    }

    private var retentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("六、資料保存期限", accent: .regular)

            VStack(alignment: .leading, spacing: 12) {
                retentionRow(title: "帳號基本資料", period: "帳號存續期間", disposal: "帳號刪除後 120 日內永久刪除")
                retentionRow(title: "對話內容", period: "帳號存續期間或您主動刪除為止", disposal: "軟刪除後 120 日永久清除")
                retentionRow(title: "技術日誌", period: "90 日", disposal: "自動覆寫")
                retentionRow(title: "已去識別化之統計資料", period: "不限期", disposal: "不可還原")
            }
            .padding(18)
            .modifier(LegalCardStyle())
        }
    }

    private func retentionRow(title: String, period: String, disposal: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.darkBrown)
            Text("保存期限：\(period)")
                .font(.system(size: 14))
                .foregroundColor(AppColors.mediumBrown)
            Text("銷毀方式：\(disposal)")
                .font(.system(size: 14))
                .foregroundColor(AppColors.mediumBrown)
        }
        .padding(.bottom, 2)
    }

    private var rightsSection: some View {
        section(title: "七、您的權利（個資法第 3 條）", body: PrivacyPolicyContent.rightsSection, accent: .regular)
    }

    private var appendixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("附錄 A：使用聲明（簡要重點）", accent: .success)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(PrivacyPolicyContent.consentStatements.indices, id: \.self) { index in
                    Text(PrivacyPolicyContent.consentStatements[index])
                }
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(AppColors.darkBrown)
            .lineSpacing(4)
            .padding(18)
            .modifier(LegalCardStyle(highlight: AppColors.orange.opacity(0.12)))
        }
    }

    private func section(title: String, body: String, accent: LegalSectionAccent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(title, accent: accent)
            Text(body)
                .font(.system(size: 14))
                .foregroundColor(AppColors.mediumBrown)
                .lineSpacing(5)
                .padding(18)
                .modifier(LegalCardStyle())
        }
    }

    private func sectionTitle(_ title: String, accent: LegalSectionAccent) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent.color)
                .frame(width: 10, height: 10)

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
        }
    }
}

private enum LegalSectionAccent {
    case regular
    case warning
    case success

    var color: Color {
        switch self {
        case .regular:
            return AppColors.orange
        case .warning:
            return Color(red: 0.82, green: 0.38, blue: 0.18)
        case .success:
            return Color(red: 0.49, green: 0.42, blue: 0.18)
        }
    }
}

private struct LegalCardStyle: ViewModifier {
    var highlight: Color = Color.white.opacity(0.94)

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(highlight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppColors.lightBrown.opacity(0.18), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
    }
}

enum PrivacyPolicyContent {
    static let consentStatements = [
        "我已年滿 18 歲，或已取得法定代理人同意。",
        "我了解本服務由 AI 提供回應，並非醫療行為。",
        "我了解本服務無法處理緊急精神危機，遇危機時將撥打 1925 / 1995 等專線或就醫。",
        "我同意對話內容會傳送至雲端 LLM 供應商進行推論運算。",
        "我同意本政策所述之蒐集、處理、利用方式。",
        "我了解我得隨時行使查詢、更正、停止與刪除等個資權利。",
    ]

    static let appendixSection = """
✅ 我已年滿 18 歲，或已取得法定代理人同意。

✅ 我了解本服務由 AI 提供回應，並非醫療行為。

✅ 我了解本服務無法處理緊急精神危機，遇危機時將撥打 1925 / 1995 等專線或就醫。

✅ 我同意對話內容會傳送至雲端 LLM 供應商進行推論運算。

✅ 我同意本政策所述之蒐集、處理、利用方式。

✅ 我了解我得隨時行使查詢、更正、停止與刪除等個資權利。
"""

    static let rightsSection = """
您就本服務蒐集之個人資料，得行使下列權利：

查詢或請求閱覽：透過帳號設定查看您的個人資料與對話紀錄

請求對話文本：申請匯出您的全部對話紀錄（JSON / TXT 格式）

請求補充或更正：修改錯誤或過時之資料

請求停止蒐集、處理或利用：暫停 AI 互動但保留歷史紀錄

請求刪除：永久刪除帳號及所有對話資料（不可復原）

行使方式：

帳號設定頁面內之自助操作

來信至：pywu@nccu.edu.tw

本服務將於收到請求後 7 日內回覆並處理。
"""

    static let retentionSection = """
帳號基本資料：

保存期限：帳號存續期間

銷毀方式：帳號刪除後 120 日內永久刪除

對話內容：

保存期限：帳號存續期間或您主動刪除為止

銷毀方式：軟刪除後 120 日永久清除

技術日誌：

保存期限：90 日

銷毀方式：自動覆寫

已去識別化之統計資料：

保存期限：不限期

銷毀方式：不可還原
"""

    static let commitmentSection = """
❌ 不會將您可識別之個人資料出售、出租或交換予任何第三方

❌ 不會用於廣告投放或行銷分析
"""

    static let warningSection = """
⚠️ 【非醫療與非專業心理服務聲明】

本服務提供 AI 情緒陪伴與自我探索對話，不提供醫療診斷、處方、心理衡鑑或專業心理治療，亦不能替代就醫、心理諮商或其他專業服務。

與您互動的 AI 並非醫師、臨床心理師或諮商心理師，不具備專業資格；其回應不構成專業診斷、個別化治療建議或處方。請勿僅依本服務內容自行判定病情、延誤就醫，或開始、停止及調整藥物與治療。

⚠️ 【AI 回應與使用成效限制】

AI 可能誤解您的描述、忽略重要資訊，或產生錯誤、不完整、不適切及不符合您需求的回應。本服務不保證回應的正確性、完整性或適用性，亦不保證能改善情緒、心理狀態、精神症狀或人際關係。

使用者應審慎判斷回應內容，避免僅依本服務作成涉及身心健康、安全或其他重大權益的決策。如回應使您感到不適、困惑或困擾加劇，請暫停使用，並視需要尋求合格專業人員協助。

⚠️ 【人工監看與機構通知限制】

除非本服務或合作機構已另行與您約定，或在使用前明確告知特定安排，本服務不提供人工即時監看，亦不會因您輸入特定內容而自動通知您所屬的學校、社區服務單位、醫療機構或其他機構。

即使您透過合作機構使用本服務，也不代表該機構的教師、心理師、醫療人員或其他工作人員正在閱讀您的對話，或會即時收到通知。請勿將傳送訊息至本服務，視為已向相關人員求助或完成危機通報。

若另有人工檢視、風險通知或機構聯繫機制，其適用範圍、處理時段、通知對象及資料利用方式，應於使用前另行說明。上述限制不影響相關人員在實際知悉特定情事後，依法應履行的通報或必要處置義務。

⚠️ 【緊急狀況與危機救援限制】

本服務不適合作為急性精神症狀、重大心理危機或緊急生命危險的主要處理工具，亦不能取代專業危機評估與處置。

本服務無法保證正確或及時辨識自殺、自傷、傷害他人或其他危機，也不保證能自動通報、聯繫緊急聯絡人、派遣救援或取得您所在位置。即使系統未顯示警示，也不代表您目前沒有風險；即使顯示求助提醒，也不代表已有專業人員接手處理。

若您出現自殺意念、自傷衝動、急性精神症狀或重大心理危機，請主動聯繫合格專業人員，或撥打衛生福利部安心專線：1925。

如有立即危險，請立即尋求當地緊急救援或前往就近醫療院所急診，並盡可能請可信任的人陪同；請勿等待本服務回覆或通知他人。

⚠️ 【輔助性質與責任限制】

本服務的輔助性質與上述限制，不代表將所有使用風險或損害責任轉由使用者承擔。本服務提供者仍應依法履行個人資料保護、資訊安全及其他應負義務。

本服務之責任應依適用法律及具體事實認定；本聲明不排除或限制本服務提供者因故意、重大過失，或其他依法不得免除或限制之事由所應負之責任，亦不影響使用者依法享有之權利。
"""

    static let introduction = """
歡迎使用 PsychEcho（以下簡稱「本服務」）。本服務是一套以人工智慧（AI）為基礎的情緒陪伴與自我探索輔助平台，透過對話引導，協助使用者在日常生活中進行自我覺察與情緒整理。

【重要定位告知】

本服務僅作為日常個人成長、情緒陪伴與自我探索的輔助工具，不提供醫療診斷、處方或專業心理治療，亦不能取代醫師、臨床心理師、諮商心理師或其他合格專業人員的評估與服務。

本服務的回應由 AI 自動生成，可能包含錯誤、不完整或不適切的內容，不保證適用於您的個別情況，亦不保證能改善心理狀態、緩解症狀或達成特定成效。

我們重視您的隱私，並理解對話可能涉及高度敏感的心理健康及其他個人資料，因此依據《個人資料保護法》（以下簡稱「個資法」）及相關法令制定本政策，說明個人資料的蒐集、處理與利用方式、服務限制，以及您所享有的權利。
"""

    static let dataCategories = """
依個資法第 2 條第 1 款及第 6 條規定，本服務可能蒐集下列資料：

3.1 帳號基本資料

電子郵件信箱、帳號密碼、使用者暱稱（選填）

3.2 互動內容（屬個資法第 6 條「特種個資」範疇）

您與 AI 對話之完整文字內容

您所選擇之引導模式（CBT / MBT / MBCT / DBT / INITIAL 初診分流）

對話時間戳記、系統回覆內容及所引用之參考摘要

心理測驗、量表、自我評估等以及分析結果

3.3 裝置與技術資料（一般 App 運作必要資料）

裝置型號、作業系統版本、IP 位址、網路連線狀態

登入與登出時間戳記、操作行為日誌（Logs）

崩潰報告（Crash Logs）與 API 錯誤紀錄

3.4 使用者自願提供資料

您於對話中主動分享之人際、生活或生理心理描述
"""

    static let purposes = """
本服務蒐集與利用資料之目的如下：

提供對話服務：傳送訊息至大型語言模型（LLM）生成陪伴回應

維持上下文連貫性：暫存會話歷史以保持對話脈絡

輔助內容檢索：依對話主題索引公開參考資料輔助生成回覆

服務維運與除錯：排查閃退、異常請求，確保系統連線安全

服務改善：經完全去識別化（匿名化）處理後，進行品質評估與演算法優化

法令配合：於符合司法機關法定程序下配合調查
"""

    static let thirdPartyProcessing = """
為提供 AI 運算服務，您的對話文字會經由加密通道傳輸至合作之雲端推論供應商（如 Anthropic、Google 等）。

上述供應商均簽署企業級隱私保護協議，遵循不留存、不轉作公共模型訓練之原則；但運算節點可能位於境外，您使用本服務即代表同意資料之跨境安全傳輸。
"""

    static let minors = """
未滿 18 歲之使用者，須經法定代理人（家長或監護人）充分閱讀並同意本聲明後始得使用。

本服務不向未滿 12 歲之兒童提供服務。

若發現未成年人未取得同意註冊，本服務有權暫停帳號並刪除相關資料。
"""

    static let security = """
本服務實施下列安全控管機制：

全站傳輸採用 TLS/HTTPS 加密

資料庫對敏感性欄位施行加密儲存（Encryption at Rest）

內部存取嚴格遵循「最小授權原則（Least Privilege）」

系統定期執行漏洞修補、防護稽核與異常存取警告

【安全免責提醒】

儘管我們採取了業界標準之防護，網際網路環境仍無法保證絕對安全。請您妥善保管個人密碼，切勿將帳號借予他人或於公開環境儲存憑證。
"""

    static let cookies = """
本服務使用必要的本機存取機制（如 Local Storage / Session Token）以維持登入狀態與通訊安全。本服務絕不使用任何第三方跨站追蹤或廣告行銷之 Cookie。
"""

    static let revisions = """
本政策得配合法令修訂或產品功能演進適時調整。重大變更將於 App 內以顯著彈窗或公告提醒；若您在變更公告後繼續使用本服務，即代表您接受更新後之條款。
"""

    static let governingLaw = """
責任限制：在法律允許之最大範圍內，本服務對於因不可抗力、第三方雲端斷線、網路異常或使用者個人不當依賴所造成之損害，均不承擔連帶損害賠償責任。

準據法與管轄：本政策之解釋與適用均以中華民國法律為準據法，並以臺灣臺北地方法院為第一審管轄法院。
"""
}

// MARK: - 忘記密碼頁面
struct ForgotPasswordPage: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var name = ""
    @State private var email = ""
    @State private var showResetPasswordStep = false
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    @FocusState private var focusedField: ForgotPasswordField?
    
    var body: some View {
        NavigationStack {
            forgotPasswordIdentityView
                .navigationDestination(isPresented: $showResetPasswordStep) {
                    ResetPasswordFormPage(
                        viewModel: viewModel,
                        name: name,
                        email: email
                    ) {
                        dismiss()
                    }
                }
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            errorAlertMessage = trimmed
            showErrorAlert = true
        }
        .alert("重設密碼失敗", isPresented: $showErrorAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(errorAlertMessage)
        }
    }
}

private extension ForgotPasswordPage {
    var forgotPasswordIdentityView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.orange)

                Text("重置密碼")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.darkBrown)

                Text("請先輸入您的姓名與電子郵件，我們會帶您進入設定新密碼頁面")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mediumBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 40)

            VStack(spacing: 20) {
                AuthTextField(
                    field: .firstName,
                    text: $name,
                    isValid: isNameValid,
                    errorMessage: nameErrorMessage,
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .name
                        }
                    },
                    onCommit: {
                        focusedField = .email
                    },
                    placeholderOverride: "姓名",
                    showValidationIcon: false,
                    showPasswordStrength: false
                )
                .focused($focusedField, equals: .name)

                AuthTextField(
                    field: .email,
                    text: $email,
                    isValid: isEmailValid,
                    errorMessage: emailErrorMessage,
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .email
                        }
                    },
                    onCommit: {
                        handleIdentityVerification()
                    },
                    showValidationIcon: false,
                    showPasswordStrength: false
                )
                .focused($focusedField, equals: .email)

                forgotPasswordStatusMessage

                LoadingButton(
                    title: "下一步",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.isLoading || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    handleIdentityVerification()
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            Button("返回登入") {
                dismiss()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(AppColors.orange)
            .padding(.bottom, 40)
        }
        .background(pageBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("取消") {
                    dismiss()
                }
                .foregroundColor(AppColors.orange)
            }
        }
    }

    var isNameValid: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Validation.isValidName(name)
    }

    var nameErrorMessage: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "請輸入姓名"
    }

    var isEmailValid: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || Validation.isValidEmail(email)
    }

    var emailErrorMessage: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "請輸入有效的電子郵件地址"
    }

    var forgotPasswordStatusMessage: some View {
        Group {
            if !viewModel.successMessage.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(viewModel.successMessage)
                        .foregroundColor(.green)
                    Spacer()
                }
                .font(.system(size: 14, weight: .medium))
            }
        }
    }

    var pageBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [AppColors.lightYellow, Color.white]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func handleIdentityVerification() {
        viewModel.verifyResetIdentity(name: name, email: email) { success in
            if success {
                showResetPasswordStep = true
            }
        }
    }
}

private struct ResetPasswordFormPage: View {
    @ObservedObject var viewModel: AuthViewModel
    let name: String
    let email: String
    let onSuccess: () -> Void

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: ForgotPasswordField?

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.orange)

                Text("設定新密碼")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.darkBrown)

                Text("請輸入新的密碼並再次確認，送出後會返回登入主畫面")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.mediumBrown)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 40)

            VStack(spacing: 20) {
                AuthTextField(
                    field: .password,
                    text: $newPassword,
                    isValid: isPasswordValid,
                    errorMessage: passwordErrorMessage,
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .password
                        }
                    },
                    onCommit: {
                        focusedField = .confirmPassword
                    },
                    placeholderOverride: "新密碼",
                    showValidationIcon: false,
                    showPasswordStrength: true
                )
                .focused($focusedField, equals: .password)

                AuthTextField(
                    field: .confirmPassword,
                    text: $confirmPassword,
                    isValid: isConfirmPasswordValid,
                    errorMessage: confirmPasswordErrorMessage,
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .confirmPassword
                        }
                    },
                    onCommit: {
                        handlePasswordReset()
                    },
                    placeholderOverride: "確認新密碼",
                    showValidationIcon: false,
                    showPasswordStrength: false
                )
                .focused($focusedField, equals: .confirmPassword)

                resetPasswordStatusMessage

                LoadingButton(
                    title: "完成重設",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.isLoading || newPassword.isEmpty || confirmPassword.isEmpty
                ) {
                    handlePasswordReset()
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [AppColors.lightYellow, Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension ResetPasswordFormPage {
    var isPasswordValid: Bool {
        newPassword.isEmpty || Validation.isValidPassword(newPassword)
    }

    var passwordErrorMessage: String {
        newPassword.isEmpty ? "" : "密碼至少需要8個字符"
    }

    var isConfirmPasswordValid: Bool {
        confirmPassword.isEmpty || confirmPassword == newPassword
    }

    var confirmPasswordErrorMessage: String {
        confirmPassword.isEmpty ? "" : "密碼不一致"
    }

    var resetPasswordStatusMessage: some View {
        Group {
            if !viewModel.successMessage.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(viewModel.successMessage)
                        .foregroundColor(.green)
                    Spacer()
                }
                .font(.system(size: 14, weight: .medium))
            }
        }
    }

    func handlePasswordReset() {
        viewModel.completePasswordReset(
            name: name,
            email: email,
            password: newPassword,
            confirmPassword: confirmPassword
        ) { success in
            if success {
                onSuccess()
            }
        }
    }
}

private enum ForgotPasswordField: Hashable {
    case name
    case email
    case password
    case confirmPassword
}

// MARK: - 預覽
struct LoginPage_Previews: PreviewProvider {
    static var previews: some View {
        LoginPage()
            .previewDisplayName("登入頁面")
        
        ForgotPasswordPage()
            .previewDisplayName("忘記密碼頁面")
    }
}
