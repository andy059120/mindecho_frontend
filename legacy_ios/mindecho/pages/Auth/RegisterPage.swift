import SwiftUI

// MARK: - 註冊頁面
struct RegisterPage: View {

    // MARK: - 環境和狀態
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AuthViewModel.shared
    @StateObject private var validator = FormValidator()

    // MARK: - 表單狀態
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var nickname = ""
    @State private var dateOfBirth = ""
    @State private var selectedDate = Date()
    @State private var emergencyContacts: [EmergencyContactInput] = [
        EmergencyContactInput()
    ]
    @State private var selectedGender: String = ""
    @State private var selectedEducationLevel: Int = 0
    @State private var showDatePicker = false
    @State private var acceptedStatements: Set<Int> = []
    @State private var showPrivacyPolicy = false
    private var agreeToTerms: Bool {
        PrivacyPolicyContent.consentStatements.indices.allSatisfy { acceptedStatements.contains($0) }
    }
    @State private var importantQuote = UserDefaults.standard.string(
        forKey: AuthConstants.UserDefaultsKeys.importantQuote
    ) ?? ""
    @State private var didEditImportantQuote = false

    // MARK: - 動畫和UI狀態
    @State private var animateContent = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var currentStep = 0 // 0: 基本信息, 1: 個人信息

    // MARK: - 焦點管理
    @FocusState private var focusedField: FormField?

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        // 頂部區域
                        headerSection
                            .frame(height: max(150, geometry.size.height * 0.25 - keyboardHeight * 0.2))

                        // 主要內容區域
                        mainContentSection
                            .frame(minHeight: geometry.size.height * 0.75)

                       
                    }
                }
                .scrollIndicators(.hidden)
                .background(backgroundGradient)
            }
            .navigationBarHidden(true)
            .loadingOverlay(
                isVisible: viewModel.isLoading,
                message: viewModel.loadingMessage.isEmpty ? "註冊中..." : viewModel.loadingMessage,
                style: .spinner
            )
            .onAppear {
                startAnimation()
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
                    resetFormToStart()
                    viewModel.successMessage = ""
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyStatementView()
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: $selectedDate,
                dateOfBirth: $dateOfBirth,
                isPresented: $showDatePicker
            )
        }
    }

    /// 成功後重置頁面狀態，回到第一步
    private func resetFormToStart() {
        currentStep = 0
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        firstName = ""
        lastName = ""
        nickname = ""
        dateOfBirth = ""
        selectedDate = Date()
        selectedGender = ""
        selectedEducationLevel = 0
        emergencyContacts = [EmergencyContactInput()]
        acceptedStatements = []
        importantQuote = ""
        didEditImportantQuote = false
        UserDefaults.standard.removeObject(forKey: AuthConstants.UserDefaultsKeys.importantQuote)
        focusedField = nil
    }

    // MARK: - 底部區域
    var bottomSection: some View {
        VStack(spacing: 16) {
            // 登入提示
            HStack(spacing: 4) {
                Text("已經有帳戶了？")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.mediumBrown)

                Button("立即登入") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.orange)
            }
            .opacity(animateContent ? 1 : 0)
        }
    }
}

private struct EmergencyContactInput: Identifiable {
    let id = UUID()
    var name: String = ""
    var relation: String = ""
    var contactInfo: String = ""
}

// 緊急聯絡人
extension RegisterPage {
    var emergencyContactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("緊急聯絡人")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.darkBrown)
            
            ForEach(Array(emergencyContacts.enumerated()), id: \.element.id) { index, _ in
                contactGroup(
                    title: "聯絡人 \(index + 1)",
                    contact: $emergencyContacts[index]
                )
            }
            
            HStack(spacing: 8) {
                Button {
                    addEmergencyContact()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("新增聯絡人")
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppColors.orange.opacity(0.2))
                    .foregroundColor(AppColors.titleColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(emergencyContacts.count >= 3)
                
                if emergencyContacts.count > 1 {
                    Button {
                        removeEmergencyContact()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "minus.circle.fill")
                            Text("移除最後一位")
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.15))
                        .foregroundColor(AppColors.titleColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text("至少填寫 1 位緊急聯絡人，可增加至最多 3 位。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private extension RegisterPage {
    var genderSelector: some View {
        let options = ["男", "女", "其他"]
        return HStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button {
                    selectedGender = option
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selectedGender == option ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(selectedGender == option ? AppColors.orange : AppColors.mediumBrown)
                        Text(option)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.darkBrown)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(selectedGender == option ? AppColors.lightYellow.opacity(0.7) : Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColors.lightBrown.opacity(0.6), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var educationSelector: some View {
        let options: [(Int, String)] = [
            (1, "小學(或同等學歷)或以下"),
            (2, "初級中學或初級職業學校(或同等學歷)"),
            (3, "高級中學或高級職業學校(或同等學歷)"),
            (4, "大學或專科、技術學院(或同等學歷)"),
            (5, "研究所或以上(碩博士)")
        ]
        return VStack(alignment: .leading, spacing: 10) {
            ForEach(options, id: \.0) { level, title in
                Button {
                    selectedEducationLevel = level
                } label: {
                    HStack {
                        Image(systemName: selectedEducationLevel == level ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(selectedEducationLevel == level ? AppColors.orange : AppColors.mediumBrown.opacity(0.7))
                        Text(title)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.darkBrown)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColors.lightBrown.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    func contactGroup(title: String,
                      contact: Binding<EmergencyContactInput>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.darkBrown)
            
            AuthTextField(
                field: .supportContactName,
                text: contact.name,
                isValid: contact.wrappedValue.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    contact.wrappedValue.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    contact.wrappedValue.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? true
                    : !contact.wrappedValue.name.isEmpty,
                errorMessage: contact.wrappedValue.name.isEmpty &&
                    (contact.wrappedValue.relation.isEmpty == false || contact.wrappedValue.contactInfo.isEmpty == false)
                    ? "請填寫姓名"
                    : "",
                onEditingChanged: { isFocused in
                    if isFocused {
                        focusedField = .supportContactName
                    }
                },
                onCommit: {
                    focusedField = .supportContactInfo
                },
                placeholderOverride: "姓名"
            )
            .focused($focusedField, equals: .supportContactName)
            
            AuthTextField(
                field: .emergencyRelation,
                text: contact.relation,
                isValid: contact.wrappedValue.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    contact.wrappedValue.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    contact.wrappedValue.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? true
                    : !contact.wrappedValue.relation.isEmpty,
                errorMessage: contact.wrappedValue.relation.isEmpty &&
                    (contact.wrappedValue.name.isEmpty == false || contact.wrappedValue.contactInfo.isEmpty == false)
                    ? "請填寫關係"
                    : "",
                onEditingChanged: { isFocused in
                    if isFocused {
                        focusedField = .supportContactInfo
                    }
                },
                onCommit: {
                    focusedField = .familyContactInfo
                },
                placeholderOverride: "關係"
            )
            .focused($focusedField, equals: .supportContactInfo)
            
            AuthTextField(
                field: .familyContactInfo,
                text: contact.contactInfo,
                isValid: contact.wrappedValue.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    contact.wrappedValue.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                    contact.wrappedValue.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? true
                    : !contact.wrappedValue.contactInfo.isEmpty,
                errorMessage: contact.wrappedValue.contactInfo.isEmpty &&
                    (contact.wrappedValue.name.isEmpty == false || contact.wrappedValue.relation.isEmpty == false)
                    ? "請填寫聯絡方式"
                    : "",
                onEditingChanged: { isFocused in
                    if isFocused {
                        focusedField = .familyContactInfo
                    }
                },
                onCommit: {},
                placeholderOverride: "聯絡方式"
            )
            .focused($focusedField, equals: .familyContactInfo)
            .onChange(of: contact.wrappedValue.contactInfo) { _, newValue in
                let filtered = newValue.filter { $0.isNumber }
                if filtered != newValue {
                    contact.wrappedValue.contactInfo = filtered
                }
            }
        }
    }

    func addEmergencyContact() {
        guard emergencyContacts.count < 3 else { return }
        emergencyContacts.append(EmergencyContactInput())
    }
    
    func removeEmergencyContact() {
        guard emergencyContacts.count > 1 else { return }
        emergencyContacts.removeLast()
    }
}

// MARK: - 視圖組件
private extension RegisterPage {
    
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
            // 關閉按鈕和進度條
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(AppColors.mediumBrown.opacity(0.6))
                }
                
                Spacer()
                
                // 步驟進度條
                progressIndicator
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Spacer()
            
            // Logo 和標題
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.orange)
                    
                    Text("PsychEcho")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.darkBrown)
                }
                .scaleEffect(animateContent ? 1 : 0.8)
                
                Text(currentStep == 0 ? "創建您的帳戶" : "完善個人信息")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .opacity(animateContent ? 1 : 0)
            }
            
            Spacer()
        }
    }
    
    // 進度指示器
    var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<2, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 30, height: 4)
                    .foregroundColor(
                        index <= currentStep ? AppColors.orange : AppColors.lightBrown.opacity(0.3)
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
    
    // 主要內容區域
    var mainContentSection: some View {
        VStack(spacing: 0) {
            // 註冊表單卡片
            registerFormCard
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
    
    // 註冊表單卡片
    var registerFormCard: some View {
        VStack(spacing: 24) {
            // 表單內容
            if currentStep == 0 {
                basicInfoForm
            } else {
                personalInfoForm
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 1.0, green: 0.97, blue: 0.94))
                .shadow(color: AppColors.darkBrown.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    // 基本信息表單 (步驟 1)
    var basicInfoForm: some View {
        VStack(spacing: 24) {
            // 表單標題
            Text("基本信息")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 表單字段
            VStack(spacing: 20) {
                // 電子郵件
                AuthTextField(
                    field: .email,
                    text: $email,
                    isValid: !viewModel.hasError(for: .email),
                    errorMessage: viewModel.getErrorMessage(for: .email),
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .email
                        }
                        if !isFocused && !email.isEmpty {
                            viewModel.validateFieldRealTime(field: .email, value: email)
                        }
                    },
                    onCommit: {
                        focusedField = .password
                    }
                )
                .focused($focusedField, equals: .email)
                .onChange(of: email) { _, newValue in
                    viewModel.validateFieldRealTime(field: .email, value: newValue)
                }
                
                // 密碼
                AuthTextField(
                    field: .password,
                    text: $password,
                    isValid: Validation.isValidPassword(password),
                    errorMessage: password.count < AuthConstants.Validation.minimumPasswordLength ? "密碼至少需要8個字符" : viewModel.getErrorMessage(for: .password),
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .password
                        }
                        if !isFocused && !password.isEmpty {
                            viewModel.validateFieldRealTime(field: .password, value: password)
                        }
                    },
                    onCommit: {
                        focusedField = .confirmPassword
                    }
                )
                .focused($focusedField, equals: .password)
                .onChange(of: password) { _, newValue in
                    viewModel.validateFieldRealTime(field: .password, value: newValue)
                }
                
                // 確認密碼
                AuthTextField(
                    field: .confirmPassword,
                    text: $confirmPassword,
                    isValid: confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines) == password.trimmingCharacters(in: .whitespacesAndNewlines),
                    errorMessage: confirmPassword.isEmpty ? "" : viewModel.formValidator.confirmPasswordState.errorMessage,
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .confirmPassword
                        }
                        if !isFocused && !confirmPassword.isEmpty {
                            viewModel.validateFieldRealTime(field: .confirmPassword, value: confirmPassword)
                        }
                    },
                    onCommit: {
                        if isBasicInfoValid {
                            nextStep()
                        }
                    }
                )
                .focused($focusedField, equals: .confirmPassword)
                .onChange(of: confirmPassword) { _, newValue in
                    viewModel.validateFieldRealTime(field: .confirmPassword, value: newValue.trimmingCharacters(in: .whitespacesAndNewlines))
                }

                
            }
            
            // 錯誤和成功訊息
            if !viewModel.successMessage.isEmpty {
                successMessageView
            }
            
            if !viewModel.errorMessage.isEmpty {
                errorMessageView
            }
            
           
            
            // 下一步按鈕
            AuthButton.primary(
                title: "下一步",
                size: .large,
                isDisabled: !isBasicInfoValid
            ) {
                nextStep()
            }
        }
    }
    
    // 個人信息表單 (步驟 2)
    var personalInfoForm: some View {
        VStack(spacing: 24) {
            // 表單標題
            Text("個人信息")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.darkBrown)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 表單字段
            VStack(spacing: 20) {
                // 名字
                AuthTextField(
                    field: .firstName,
                    text: $fullName,
                    isValid: !viewModel.hasError(for: .firstName),
                    errorMessage: viewModel.getErrorMessage(for: .firstName),
                    onEditingChanged: { isFocused in
                        if isFocused {
                            focusedField = .firstName
                        }
                        if !isFocused && !fullName.isEmpty {
                            let parts = splitFullName(fullName)
                            let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                            viewModel.validateFieldRealTime(field: .firstName, value: trimmed)
                            viewModel.validateFieldRealTime(field: .lastName, value: parts.lastName)
                        }
                    },
                    onCommit: {
                        openBirthPicker()
                    },
                    placeholderOverride: "姓名"
                )
                .focused($focusedField, equals: .firstName)
                .onChange(of: fullName) { _, newValue in
                    let parts = splitFullName(newValue)
                    firstName = parts.firstName
                    lastName = parts.lastName
                    let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    viewModel.validateFieldRealTime(field: .firstName, value: trimmed)
                    viewModel.validateFieldRealTime(field: .lastName, value: parts.lastName)
                }

                AuthTextField(
                    field: .firstName,
                    text: $nickname,
                    isValid: true,
                    errorMessage: "",
                    onEditingChanged: { _ in },
                    onCommit: {
                        openBirthPicker()
                    },
                    placeholderOverride: "暱稱（選填）",
                    showValidationIcon: false
                )

                // 性別
                VStack(alignment: .leading, spacing: 8) {
                    Text("生理性別")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.darkBrown)
                    genderSelector
                }

                // 教育程度
                VStack(alignment: .leading, spacing: 8) {
                    Text("教育程度")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.darkBrown)
                    educationSelector
                }
                
                // 出生日期選擇器
                dateOfBirthField
                
                // 緊急聯絡人
                emergencyContactSection

                // 對我很重要的一段話（必填）
                VStack(alignment: .leading, spacing: 8) {
                    Text("對我很重要的一段話")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.darkBrown)

                    TextEditor(text: $importantQuote)
                        .frame(height: 110)
                        .padding(10)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    didEditImportantQuote && importantQuoteTrimmed.isEmpty
                                        ? Color.red
                                        : AppColors.lightBrown.opacity(0.5),
                                    lineWidth: 1
                                )
                        )
                        .onChange(of: importantQuote) { _, newValue in
                            didEditImportantQuote = true
                            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty {
                                UserDefaults.standard.removeObject(
                                    forKey: AuthConstants.UserDefaultsKeys.importantQuote
                                )
                            } else {
                                UserDefaults.standard.set(
                                    trimmed,
                                    forKey: AuthConstants.UserDefaultsKeys.importantQuote
                                )
                            }
                        }

                    if didEditImportantQuote && importantQuoteTrimmed.isEmpty {
                        Text("此欄位為必填")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
                
            }
            
            // 服務條款同意
            termsAgreementSection
            
            // 錯誤和成功訊息
            if !viewModel.errorMessage.isEmpty {
                errorMessageView
            }
            
            if !viewModel.successMessage.isEmpty {
                successMessageView
            }
            
            // 按鈕組
            VStack(spacing: 12) {
                // 註冊按鈕
                LoadingButton(
                    title: "創建帳戶",
                    isLoading: viewModel.isLoading,
                    isDisabled: !isPersonalInfoValid || !agreeToTerms
                ) {
                    performRegistration()
                }
                
                // 返回按鈕
                AuthButton.secondary(
                    title: "返回上一步",
                    size: .medium
                ) {
                    previousStep()
                }
            }
        }
    }
    
    // 出生日期字段
    var dateOfBirthField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("出生年月")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.darkBrown)
            
            Button(action: {
                openBirthPicker()
            }) {
                HStack {
                    Text(dateOfBirth.isEmpty ? "選擇出生年月" : birthMonthDisplay)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(dateOfBirth.isEmpty ? AppColors.mediumBrown.opacity(0.6) : AppColors.darkBrown)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            viewModel.hasError(for: .dateOfBirth) && !dateOfBirth.isEmpty
                                ? Color.red
                                : AppColors.lightBrown.opacity(0.5),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // 錯誤訊息
            if viewModel.hasError(for: .dateOfBirth) && !dateOfBirth.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                    
                    Text(viewModel.getErrorMessage(for: .dateOfBirth))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.red)
                    
                    Spacer()
                }
            }
        }
    }
    
    // 服務條款同意區域
    var termsAgreementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("附錄 A：使用聲明（簡要重點）")
                .font(.system(size: 16, weight: .semibold))
            Text("請逐項閱讀並勾選，全部同意後即可建立帳號。")
                .font(.system(size: 14))
            Button("查看隱私權保護政策與使用聲明") {
                showPrivacyPolicy = true
            }
            .foregroundColor(AppColors.orange)
            ForEach(PrivacyPolicyContent.consentStatements.indices, id: \.self) { index in
                Button {
                    if acceptedStatements.contains(index) {
                        acceptedStatements.remove(index)
                    } else {
                        acceptedStatements.insert(index)
                    }
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: acceptedStatements.contains(index) ? "checkmark.square.fill" : "square")
                            .font(.system(size: 22))
                            .foregroundColor(AppColors.orange)
                        Text(PrivacyPolicyContent.consentStatements[index])
                            .font(.system(size: 14))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .accessibilityIdentifier("privacy-consent-\(index)")
                .accessibilityValue(acceptedStatements.contains(index) ? "已勾選" : "未勾選")
            }
        }
        .foregroundColor(AppColors.mediumBrown)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppColors.lightYellow.opacity(0.5)))
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

// MARK: - 計算屬性和方法
private extension RegisterPage {
    
    // 基本信息是否有效
    var isBasicInfoValid: Bool {
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !email.isEmpty &&
               !trimmedPass.isEmpty &&
               !trimmedConfirm.isEmpty &&
               Validation.isValidPassword(trimmedPass) &&
               trimmedPass == trimmedConfirm &&
               !viewModel.hasError(for: .email)
    }
    
    // 個人信息是否有效
    var isPersonalInfoValid: Bool {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty &&
               !dateOfBirth.isEmpty &&
               !selectedGender.isEmpty &&
               selectedEducationLevel != 0 &&
               isEmergencyContactsValid &&
               !importantQuoteTrimmed.isEmpty &&
               !viewModel.hasError(for: .firstName) &&
               !viewModel.hasError(for: .dateOfBirth)
    }

    var isEmergencyContactsValid: Bool {
        let nonEmpty = emergencyContacts.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        guard !nonEmpty.isEmpty else { return false }
        let hasIncomplete = nonEmpty.contains {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            $0.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            $0.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return !hasIncomplete
    }

    var importantQuoteTrimmed: String {
        importantQuote.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func startAnimation() {
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            animateContent = true
        }
    }
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 1
        }
        // 清除焦點
        focusedField = nil
    }
    
    func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 0
        }
    }
    
    func performRegistration() {
        guard agreeToTerms, !viewModel.isLoading else { return }
        // 隱藏鍵盤
        focusedField = nil
        viewModel.errorMessage = ""
        
        // 基本驗證（除基礎欄位外）
        guard !selectedGender.isEmpty else {
            viewModel.errorMessage = "請選擇性別"
            return
        }
        guard selectedEducationLevel != 0 else {
            viewModel.errorMessage = "請選擇教育程度"
            return
        }
        if !isEmergencyContactsValid {
            viewModel.errorMessage = "請至少填寫 1 位完整的緊急聯絡人（姓名、關係、聯絡方式）"
            return
        }
        guard !importantQuoteTrimmed.isEmpty else {
            viewModel.errorMessage = "請填寫對你很重要的一段話"
            return
        }

        // 🎯 使用開發模式註冊
        /*
        let parts = splitFullName(fullName)
        let emergencyPayloads = emergencyContacts.compactMap { contact -> EmergencyContactPayload? in
            let name = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let relation = contact.relation.trimmingCharacters(in: .whitespacesAndNewlines)
            let info = contact.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty && relation.isEmpty && info.isEmpty {
                return nil
            }
            return EmergencyContactPayload(name: name, relation: relation, contactInfo: info)
        }
        viewModel.registerDevelopmentMode(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: parts.firstName,
            lastName: parts.lastName,
            dateOfBirth: dateOfBirth,
            nickname: nickname.isEmpty ? nil : nickname,
            emergencyContacts: emergencyPayloads,
            gender: selectedGender,
            educationLevel: selectedEducationLevel,
            supportContactName: supportContactName,
            supportContactInfo: supportContactInfo,
            familyContactName: familyContactName,
            familyContactInfo: familyContactInfo
        )
         */
        // 🚫 真實 API 註冊
        let parts = splitFullName(fullName)
        let emergencyPayloads = emergencyContacts.compactMap { contact -> EmergencyContactPayload? in
            let name = contact.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let relation = contact.relation.trimmingCharacters(in: .whitespacesAndNewlines)
            let info = contact.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty && relation.isEmpty && info.isEmpty {
                return nil
            }
            return EmergencyContactPayload(name: name, relation: relation, contactInfo: info)
        }
        viewModel.register(
            email: email,
            password: password,
            confirmPassword: confirmPassword,
            firstName: parts.firstName,
            lastName: parts.lastName,
            dateOfBirth: dateOfBirth,
            nickname: nickname.isEmpty ? nil : nickname,
            emergencyContacts: emergencyPayloads,
            gender: selectedGender,
            educationLevel: selectedEducationLevel,
            mostImportantReasons: importantQuoteTrimmed,
            supportContactName: emergencyPayloads.first?.name,
            supportContactInfo: emergencyPayloads.first?.contactInfo
        )
        
    }

    var birthMonthDisplay: String {
        guard !dateOfBirth.isEmpty else { return "" }
        if dateOfBirth.count >= 7 {
            return String(dateOfBirth.prefix(7))
        }
        return dateOfBirth
    }
    
    func openBirthPicker() {
        if let parsed = parseBirthDate(dateOfBirth) {
            selectedDate = parsed
        }
        showDatePicker = true
    }
    
    func parseBirthDate(_ value: String) -> Date? {
        guard !value.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: value) {
            return date
        }
        if value.count >= 7 {
            let composed = "\(String(value.prefix(7)))-01"
            return formatter.date(from: composed)
        }
        return nil
    }
    
    func splitFullName(_ value: String) -> (firstName: String, lastName: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("", "")
        }
        
        if containsCJK(trimmed) {
            let compact = String(trimmed.filter { !$0.isWhitespace })
            guard let firstChar = compact.first else {
                return ("", "")
            }
            let lastName = String(firstChar)
            let firstName = String(compact.dropFirst())
            return (firstName, lastName)
        }
        
        let parts = trimmed.split(whereSeparator: { $0.isWhitespace })
        guard let firstPart = parts.first else {
            return ("", "")
        }
        let lastName = String(firstPart)
        let firstName = parts.dropFirst().joined(separator: " ")
        return (firstName, lastName)
    }
    
    func containsCJK(_ value: String) -> Bool {
        for scalar in value.unicodeScalars {
            switch scalar.value {
            case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0xF900...0xFAFF, 0x2F800...0x2FA1F:
                return true
            default:
                continue
            }
        }
        return false
    }
}

// MARK: - 日期選擇器 Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var dateOfBirth: String
    @Binding var isPresented: Bool
    
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    // 計算最小和最大日期
    private var minimumDate: Date {
        Calendar.current.date(byAdding: .year, value: -150, to: Date()) ?? Date()
    }
    
    private var maximumDate: Date {
        Date() // 今天
    }
    
    private var years: [Int] {
        let calendar = Calendar.current
        let minYear = calendar.component(.year, from: minimumDate)
        let maxYear = calendar.component(.year, from: maximumDate)
        return Array(minYear...maxYear).reversed()
    }
    
    private var months: [Int] {
        Array(1...12)
    }
    
    init(selectedDate: Binding<Date>, dateOfBirth: Binding<String>, isPresented: Binding<Bool>) {
        _selectedDate = selectedDate
        _dateOfBirth = dateOfBirth
        _isPresented = isPresented
        let calendar = Calendar.current
        let date = selectedDate.wrappedValue
        _selectedYear = State(initialValue: calendar.component(.year, from: date))
        _selectedMonth = State(initialValue: calendar.component(.month, from: date))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("選擇您的出生年月")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .padding(.top, 20)
                
                HStack(spacing: 0) {
                    Picker("年", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text("\(year)年").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    
                    Picker("月", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text("\(month)月").tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 180)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // 確認按鈕
                AuthButton.primary(
                    title: "確認",
                    size: .large
                ) {
                    let date = clampedDate()
                    selectedDate = date
                    dateOfBirth = apiBirthDateString(from: date)
                    isPresented = false
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [AppColors.lightYellow, Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        isPresented = false
                    }
                    .foregroundColor(AppColors.orange)
                }
            }
        }
        .onChange(of: selectedYear) { _, _ in
            selectedDate = clampedDate()
        }
        .onChange(of: selectedMonth) { _, _ in
            selectedDate = clampedDate()
        }
    }
    
    private func clampedDate() -> Date {
        let calendar = Calendar.current
        let maxYear = calendar.component(.year, from: maximumDate)
        let maxMonth = calendar.component(.month, from: maximumDate)
        let minYear = calendar.component(.year, from: minimumDate)
        let minMonth = calendar.component(.month, from: minimumDate)
        
        var year = selectedYear
        var month = selectedMonth
        
        if year > maxYear {
            year = maxYear
        } else if year == maxYear, month > maxMonth {
            month = maxMonth
        }
        
        if year < minYear {
            year = minYear
        } else if year == minYear, month < minMonth {
            month = minMonth
        }
        
        let components = DateComponents(year: year, month: month, day: 1)
        return calendar.date(from: components) ?? Date()
    }
    
    private func apiBirthDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "\(formatter.string(from: date))-01"
    }
}

// MARK: - 預覽
struct RegisterPage_Previews: PreviewProvider {
    static var previews: some View {
        RegisterPage()
            .previewDisplayName("註冊頁面")
        
        DatePickerSheet(
            selectedDate: .constant(Date()),
            dateOfBirth: .constant(""),
            isPresented: .constant(true)
        )
        .previewDisplayName("日期選擇器")
    }
}
