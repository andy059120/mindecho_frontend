import Foundation
import SwiftUI
import Combine
import UserNotifications

// MARK: - 認證視圖模型
class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    // MARK: - Published 屬性 (自動觸發 UI 更新)
    @Published var authState: AuthState = .idle
    @Published var errorMessage: String = ""
    @Published var successMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var loadingMessage: String = ""
    @Published var shouldShowDailyCheckIn: Bool = false
    
    // MARK: - 表單驗證器
    @Published var formValidator = FormValidator()
    
    // MARK: - 依賴注入
    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()
    private var forceDailyCheckInOnAuth = false
    private var hasAttemptedAutoLogin = false
    
    // MARK: - 初始化
    init(authService: AuthService = AuthService.shared) {
        self.authService = authService
        setupBindings()
    }
    
    // MARK: - 設置數據綁定
    private func setupBindings() {
        // 監聽認證服務的狀態變化
        authService.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                guard let self else { return }
                if isAuthenticated {
                    self.authState = .authenticated
                    if self.forceDailyCheckInOnAuth {
                        self.shouldShowDailyCheckIn = true
                        self.forceDailyCheckInOnAuth = false
                    } else {
                        self.updateDailyCheckInVisibility()
                    }
                } else {
                    self.authState = .unauthenticated
                    self.shouldShowDailyCheckIn = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 註冊功能
    func register(
        email: String,
        password: String,
        confirmPassword: String,
        firstName: String,
        lastName: String,
        dateOfBirth: String,
        nickname: String?,
        emergencyContacts: [EmergencyContactPayload],
        gender: String,
        educationLevel: Int,
        mostImportantReasons: String,
        supportContactName: String? = nil,
        supportContactInfo: String? = nil,
        familyContactName: String? = nil,
        familyContactInfo: String? = nil
    ) {
        // 清除之前的訊息
        clearMessages()
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 驗證表單
        let validationErrors = Validation.validateRegistrationForm(
            email: trimmedEmail,
            password: password,
            confirmPassword: confirmPassword,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            emergencyContacts: emergencyContacts,
            gender: gender,
            educationLevel: educationLevel,
            supportContactName: supportContactName,
            supportContactInfo: supportContactInfo,
            familyContactName: familyContactName,
            familyContactInfo: familyContactInfo,
            mostImportantReasons: mostImportantReasons
        )
        
        if !validationErrors.isEmpty {
            showError(validationErrors.first?.localizedDescription ?? "表單驗證失敗")
            return
        }
        
        // 開始載入狀態
        loadingMessage = "註冊中..."
        setLoading(true)
        
        // 建立註冊請求
        let request = RegisterRequest(
            email: trimmedEmail,
            password: password,
            name: buildName(firstName: firstName, lastName: lastName),
            dateOfBirth: dateOfBirth.trimmingCharacters(in: .whitespacesAndNewlines),
            birthYear: parseBirthYear(dateOfBirth),
            birthMonth: parseBirthMonth(dateOfBirth),
            nickname: nickname?.trimmingCharacters(in: .whitespacesAndNewlines),
            emergencyContacts: emergencyContacts,
            gender: gender,
            educationLevel: educationLevel,
            dataAnalysisConsent: false,
            supportContactName: supportContactName?.trimmingCharacters(in: .whitespacesAndNewlines),
            supportContactInfo: supportContactInfo?.trimmingCharacters(in: .whitespacesAndNewlines),
            familyContactName: familyContactName?.trimmingCharacters(in: .whitespacesAndNewlines),
            familyContactInfo: familyContactInfo?.trimmingCharacters(in: .whitespacesAndNewlines),
            mostImportantReasons: mostImportantReasons.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        // 發送註冊請求 (使用模擬 API) 真實改成Register
        authService.register(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.showError("註冊失敗: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success == true {
                        if let token = response.token,
                           let user = response.user {
                            self?.showSuccess(response.message ?? "註冊成功！歡迎加入 PsychEcho！")
                            self?.shouldShowDailyCheckIn = false
                            self?.sendRegistrationSuccessNotification(message: response.message ?? "註冊成功！")
                            self?.syncImportantQuoteAfterRegistration(
                                token: token,
                                userId: user.primaryId
                            )
                        } else {
                            self?.loadingMessage = "註冊成功，正在登入..."
                            self?.setLoading(true)
                            self?.loginAfterRegistration(
                                email: trimmedEmail,
                                password: password,
                                successMessage: response.message ?? "註冊成功！歡迎加入 PsychEcho！"
                            )
                        }
                    } else {
                        self?.showError(response.message ?? "註冊失敗，請重試")
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func loginAfterRegistration(email: String, password: String, successMessage: String) {
        authService.login(request: LoginRequest(email: email, password: password))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    if case .failure(let error) = completion {
                        self?.showError("註冊成功，但自動登入失敗：\(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success == true,
                       let token = response.token,
                       let user = response.user {
                        self?.showSuccess(successMessage)
                        self?.shouldShowDailyCheckIn = false
                        self?.sendRegistrationSuccessNotification(message: successMessage)
                        self?.syncImportantQuoteAfterRegistration(
                            token: token,
                            userId: user.primaryId
                        )
                    } else {
                        self?.showError(response.message ?? "註冊成功，但自動登入失敗，請手動登入")
                    }
                }
            )
            .store(in: &cancellables)
    }

    private func parseBirthYear(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: "-")
        guard let yearPart = parts.first, let year = Int(yearPart) else { return nil }
        return year
    }

    private func parseBirthMonth(_ value: String) -> Int? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let parts = trimmed.split(separator: "-")
        guard parts.count >= 2, let month = Int(parts[1]) else { return nil }
        return month
    }

    private func buildName(firstName: String, lastName: String) -> String {
        let first = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = last + first
        if containsCJK(combined) {
            return combined
        }
        return [first, last].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func containsCJK(_ value: String) -> Bool {
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

    private func syncImportantQuoteAfterRegistration(token: String, userId: String) {
        let key = AuthConstants.UserDefaultsKeys.importantQuote
        let raw = UserDefaults.standard.string(forKey: key) ?? ""
        let quote = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !quote.isEmpty else {
            print("[ImportantQuote] Skip sync: empty quote")
            return
        }
        guard !token.isEmpty, !userId.isEmpty else {
            print("[ImportantQuote] Skip sync: missing token/userId in response")
            return
        }

        Task {
            do {
                print("[ImportantQuote] Sync start: userId=\(userId)")
                _ = try await APIService.shared.createReason(
                    title: "對我很重要的一段話",
                    content: quote,
                    date: Date(),
                    token: token
                )
                print("[ImportantQuote] Sync success")
                UserDefaults.standard.removeObject(forKey: key)
            } catch {
                // 保留本地資料，讓下次有機會再同步
                print("[ImportantQuote] Sync failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - 登入功能
    func login(email: String, password: String) {
        // 清除之前的訊息
        clearMessages()
        
        // 驗證表單
        let validationErrors = Validation.validateLoginForm(email: email, password: password)
        
        if !validationErrors.isEmpty {
            showError(validationErrors.first?.localizedDescription ?? "表單驗證失敗")
            return
        }
        
        // 開始載入狀態
        loadingMessage = "登入中..."
        setLoading(true)
        
        // 建立登入請求
        let request = LoginRequest(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        
        // 發送登入請求 (使用真實 API)
        authService.login(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.setLoading(false)
                    
                    switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self?.showError("登入失敗: \(error.localizedDescription)")
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success == true {
                        self?.showSuccess(response.message ?? "登入成功！")
                        self?.updateDailyCheckInVisibility()
                    } else {
                        self?.showError(response.message ?? "電子郵件或密碼錯誤")
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 登出功能
    func logout() {
        authService.logout()
        authState = .unauthenticated
        shouldShowDailyCheckIn = false
        forceDailyCheckInOnAuth = false
        clearMessages()
    }

    // MARK: - App 啟動自動登入
    func attemptAutoLoginOnLaunch() {
        guard !hasAttemptedAutoLogin else { return }
        hasAttemptedAutoLogin = true
        
        // AutoLogin（正式用）
        authService.refreshStoredAuthIfNeeded()
        guard authService.hasStoredAuth else {
            print("AutoLogin: no stored auth, logging out")
            authService.logout()
            return
        }
        guard authService.canRestoreStoredSession else {
            print("AutoLogin: stored auth is not recoverable, logging out")
            handleAutoLoginFailure()
            return
        }
        print("AutoLogin: restored local auth state")
        clearMessages()
    }
    
    // MARK: - 重置密碼功能
    func verifyResetIdentity(name: String, email: String, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let validationErrors = Validation.validateForgotPasswordIdentity(name: name, email: email)
        if !validationErrors.isEmpty {
            showError(validationErrors.first?.localizedDescription ?? "資料驗證失敗")
            completion(false)
            return
        }

        completion(true)
    }

    func completePasswordReset(
        name: String,
        email: String,
        password: String,
        confirmPassword: String,
        completion: @escaping (Bool) -> Void
    ) {
        clearMessages()

        let identityErrors = Validation.validateForgotPasswordIdentity(name: name, email: email)
        if !identityErrors.isEmpty {
            showError(identityErrors.first?.localizedDescription ?? "資料驗證失敗")
            completion(false)
            return
        }

        let validationErrors = Validation.validatePasswordResetForm(password: password, confirmPassword: confirmPassword)
        if !validationErrors.isEmpty {
            showError(validationErrors.first?.localizedDescription ?? "密碼驗證失敗")
            completion(false)
            return
        }

        setLoading(true)

        let request = ResetPasswordRequest(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            newPassword: password
        )

        authService.resetPassword(request: request)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.setLoading(false)

                    if case .failure(let error) = result {
                        self?.showError("重設密碼失敗: \(error.localizedDescription)")
                        completion(false)
                    }
                },
                receiveValue: { [weak self] response in
                    if response.success == true {
                        self?.showSuccess(response.message ?? "密碼已更新")
                        completion(true)
                    } else {
                        self?.showError(response.message ?? "重設密碼失敗")
                        completion(false)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - 輔助方法
    private func setLoading(_ loading: Bool) {
        isLoading = loading
        if loading {
            authState = .loading
        } else {
            loadingMessage = ""
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        successMessage = ""
        authState = .error(message)
        
        // 3秒後自動清除錯誤訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.errorMessage == message {
                self.clearMessages()
            }
        }
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        errorMessage = ""
        
        // 3秒後自動清除成功訊息
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.successMessage == message {
                self.clearMessages()
            }
        }
    }
    
    private func clearMessages() {
        errorMessage = ""
        successMessage = ""
        if case .loading = authState {
            authState = .idle
        }
    }

    private func handleAutoLoginFailure() {
        authService.logout()
        authState = .unauthenticated
        shouldShowDailyCheckIn = false
        forceDailyCheckInOnAuth = false
        clearMessages()
    }

    func showDailyCheckInAfterLogin() {
        forceDailyCheckInOnAuth = true
        shouldShowDailyCheckIn = true
    }

    func updateDailyCheckInVisibility() {
        shouldShowDailyCheckIn = !DailyCheckInManager.shared.hasCompletedToday
    }
    
    // MARK: - 實時表單驗證
    func validateFieldRealTime(field: FormField, value: String) {
        switch field {
        case .email:
            formValidator.emailState.text = value
            formValidator.validateEmail()
        case .password:
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            formValidator.passwordState.text = trimmed
            formValidator.validatePassword()
            // 如果確認密碼已經輸入，也要重新驗證
            if !formValidator.confirmPasswordState.text.isEmpty {
                formValidator.validateConfirmPassword(confirmPassword: formValidator.confirmPasswordState.text, password: formValidator.passwordState.text)
            }
        case .confirmPassword:
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            formValidator.confirmPasswordState.text = trimmed
            formValidator.validateConfirmPassword(confirmPassword: formValidator.confirmPasswordState.text, password: formValidator.passwordState.text)
        case .firstName:
            formValidator.firstNameState.text = value
            formValidator.validateFirstName()
        case .lastName:
            formValidator.lastNameState.text = value
            formValidator.validateLastName()
        case .dateOfBirth:
            formValidator.dateOfBirthState.text = value
            formValidator.validateDateOfBirth()
        case .emergencyName:
            formValidator.emergencyNameState.text = value
            formValidator.validateEmergencyName()
        case .emergencyRelation:
            break
        case .emergencyPhone:
            formValidator.emergencyPhoneState.text = value
            formValidator.validateEmergencyPhone()
        case .supportContactName, .supportContactInfo, .familyContactName, .familyContactInfo:
            // 目前不做即時驗證，僅供焦點用
            break
        }
    }
    
    // MARK: - 獲取當前用戶
    var currentUser: User? {
        return authService.currentUser
    }
    
    // MARK: - 檢查是否已認證
    var isAuthenticated: Bool {
        return authService.isAuthenticated
    }
    
    // MARK: - 檢查表單是否有效
    var isRegistrationFormValid: Bool {
        return formValidator.isRegistrationFormValid
    }
    
    var isLoginFormValid: Bool {
        return formValidator.isLoginFormValid
    }
    
    // MARK: - 簡易本地通知
    private func sendRegistrationSuccessNotification(message: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知授權錯誤: \(error.localizedDescription)")
                return
            }
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "註冊成功"
            content.body = message
            content.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            center.add(request) { error in
                if let error = error {
                    print("通知排程失敗: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - 視圖模型擴展 - 便利方法
extension AuthViewModel {
    
    // 獲取密碼強度
    func getPasswordStrength(_ password: String) -> PasswordStrength {
        return Validation.passwordStrength(password)
    }
    
    // 格式化出生日期
    func formatDateOfBirth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return "\(formatter.string(from: date))-01"
    }
    
    // 檢查字段是否有錯誤
    func hasError(for field: FormField) -> Bool {
        switch field {
        case .email:
            return !formValidator.emailState.isValid && !formValidator.emailState.text.isEmpty
        case .password:
            return !formValidator.passwordState.isValid && !formValidator.passwordState.text.isEmpty
        case .confirmPassword:
            return !formValidator.confirmPasswordState.isValid && !formValidator.confirmPasswordState.text.isEmpty
        case .firstName:
            return !formValidator.firstNameState.isValid && !formValidator.firstNameState.text.isEmpty
        case .lastName:
            return !formValidator.lastNameState.isValid && !formValidator.lastNameState.text.isEmpty
        case .dateOfBirth:
            return !formValidator.dateOfBirthState.isValid && !formValidator.dateOfBirthState.text.isEmpty
        case .emergencyName:
            return !formValidator.emergencyNameState.isValid && !formValidator.emergencyNameState.text.isEmpty
        case .emergencyRelation:
            return false
        case .emergencyPhone:
            return !formValidator.emergencyPhoneState.isValid && !formValidator.emergencyPhoneState.text.isEmpty
        case .supportContactName, .supportContactInfo, .familyContactName, .familyContactInfo:
            return false
        }
    }
    
    // 獲取字段錯誤訊息
    func getErrorMessage(for field: FormField) -> String {
        switch field {
        case .email:
            return formValidator.emailState.errorMessage
        case .password:
            return formValidator.passwordState.errorMessage
        case .confirmPassword:
            return formValidator.confirmPasswordState.errorMessage
        case .firstName:
            return formValidator.firstNameState.errorMessage
        case .lastName:
            return formValidator.lastNameState.errorMessage
        case .dateOfBirth:
            return formValidator.dateOfBirthState.errorMessage
        case .emergencyName:
            return formValidator.emergencyNameState.errorMessage
        case .emergencyRelation:
            return ""
        case .emergencyPhone:
            return formValidator.emergencyPhoneState.errorMessage
        case .supportContactName, .supportContactInfo, .familyContactName, .familyContactInfo:
            return ""
        }
    }
}
