import Foundation
import SwiftUI

// MARK: - 表單驗證工具類
struct Validation {
    
    // MARK: - 電子郵件驗證
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - 密碼強度驗證
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= AuthConstants.Validation.minimumPasswordLength
    }
    
    // MARK: - 密碼強度詳細檢查
    static func passwordStrength(_ password: String) -> PasswordStrength {
        if password.count < AuthConstants.Validation.minimumPasswordLength {
            return .weak
        } else if password.count < 10 {
            return .medium
        } else if password.count >= 10 && containsSpecialCharacter(password) {
            return .strong
        } else {
            return .medium
        }
    }
    
    // MARK: - 檢查是否包含特殊字符
    private static func containsSpecialCharacter(_ string: String) -> Bool {
        let specialCharacterRegex = ".*[!@#$%^&*()_+\\-=\\[\\]{};':\"\\|,.<>\\?].*"
        let specialCharacterTest = NSPredicate(format: "SELF MATCHES %@", specialCharacterRegex)
        return specialCharacterTest.evaluate(with: string)
    }
    
    // MARK: - 姓名驗證
    static func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count >= 1
    }
    
    // MARK: - 出生日期驗證
    static func isValidDateOfBirth(_ dateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = dateFormatter.date(from: dateString) else {
            return false
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // 檢查日期不能是未來的日期
        if date > now {
            return false
        }
        
        // 檢查日期不能太久遠 (例如超過150年前)
        if let maxPastDate = calendar.date(byAdding: .year, value: -150, to: now),
           date < maxPastDate {
            return false
        }
        
        return true
    }
    
    // MARK: - 綜合表單驗證
    static func validateRegistrationForm(
        email: String,
        password: String,
        confirmPassword: String,
        firstName: String,
        lastName: String,
        dateOfBirth: String,
        emergencyContacts: [EmergencyContactPayload],
        gender: String,
        educationLevel: Int,
        supportContactName: String?,
        supportContactInfo: String?,
        familyContactName: String?,
        familyContactInfo: String?,
        mostImportantReasons: String
    ) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // 驗證電子郵件
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyField("電子郵件"))
        } else if !isValidEmail(email) {
            errors.append(.invalidEmail)
        }
        
        // 驗證密碼
        if password.isEmpty {
            errors.append(.emptyField("密碼"))
        } else if !isValidPassword(password) {
            errors.append(.weakPassword)
        }
        
        // 驗證確認密碼
        if password != confirmPassword {
            errors.append(.passwordMismatch)
        }
        
        // 驗證姓名（任一有值即可）
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedFirst.isEmpty && trimmedLast.isEmpty {
            errors.append(.emptyField("姓名"))
        }
        
        // 驗證出生日期
        if dateOfBirth.isEmpty {
            errors.append(.emptyField("出生日期"))
        } else if !isValidDateOfBirth(dateOfBirth) {
            errors.append(.invalidDateOfBirth)
        }

        // 性別
        if gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyField("性別"))
        }

        // 教育程度 (1~5)
        if educationLevel < 1 || educationLevel > 5 {
            errors.append(.emptyField("教育程度"))
        }

        // 緊急聯絡人（至少 1 位）
        let nonEmptyContacts = emergencyContacts.filter {
            !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !$0.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        if nonEmptyContacts.isEmpty {
            errors.append(.emptyField("緊急聯絡人"))
        } else {
            let hasIncomplete = nonEmptyContacts.contains {
                $0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                $0.relation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                $0.contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            if hasIncomplete {
                errors.append(.emptyField("緊急聯絡人資料"))
            }
        }

        if mostImportantReasons.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyField("對我很重要的一段話"))
        }
        
        return errors
    }
    
    // MARK: - 登入表單驗證
    static func validateLoginForm(email: String, password: String) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyField("電子郵件"))
        } else if !isValidEmail(email) {
            errors.append(.invalidEmail)
        }
        
        if password.isEmpty {
            errors.append(.emptyField("密碼"))
        }
        
        return errors
    }

    // MARK: - 忘記密碼身份驗證
    static func validateForgotPasswordIdentity(name: String, email: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyField("姓名"))
        }

        if email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append(.emptyField("電子郵件"))
        } else if !isValidEmail(email) {
            errors.append(.invalidEmail)
        }

        return errors
    }

    // MARK: - 新密碼驗證
    static func validatePasswordResetForm(password: String, confirmPassword: String) -> [ValidationError] {
        var errors: [ValidationError] = []

        if password.isEmpty {
            errors.append(.emptyField("新密碼"))
        } else if !isValidPassword(password) {
            errors.append(.weakPassword)
        }

        if confirmPassword.isEmpty {
            errors.append(.emptyField("確認密碼"))
        } else if password != confirmPassword {
            errors.append(.passwordMismatch)
        }

        return errors
    }
}

// MARK: - 密碼強度枚舉
enum PasswordStrength: CaseIterable {
    case weak
    case medium
    case strong
    
    var description: String {
        switch self {
        case .weak:
            return "弱"
        case .medium:
            return "中等"
        case .strong:
            return "強"
        }
    }
    
    var color: Color {
        switch self {
        case .weak:
            return Color.red
        case .medium:
            return AppColors.orange
        case .strong:
            return Color.green
        }
    }
    
    var progress: Double {
        switch self {
        case .weak:
            return 0.33
        case .medium:
            return 0.66
        case .strong:
            return 1.0
        }
    }
}

// MARK: - 表單字段狀態
struct FieldState {
    var text: String = ""
    var isValid: Bool = false
    var errorMessage: String = ""
    var isFocused: Bool = false
    
    mutating func validate(using validator: (String) -> ValidationResult) {
        let result = validator(text)
        isValid = result.isValid
        errorMessage = result.errorMessage
    }
}

// MARK: - 驗證結果
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String
    
    static let valid = ValidationResult(isValid: true, errorMessage: "")
    
    static func invalid(_ message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - 實時驗證助手
class FormValidator: ObservableObject {
    @Published var emailState = FieldState()
    @Published var passwordState = FieldState()
    @Published var confirmPasswordState = FieldState()
    @Published var firstNameState = FieldState()
    @Published var lastNameState = FieldState()
    @Published var dateOfBirthState = FieldState()
    @Published var emergencyNameState = FieldState()
    @Published var emergencyPhoneState = FieldState()
    
    var isRegistrationFormValid: Bool {
        return emailState.isValid &&
               passwordState.isValid &&
               confirmPasswordState.isValid &&
               firstNameState.isValid &&
               lastNameState.isValid &&
               dateOfBirthState.isValid &&
               !emailState.text.isEmpty &&
               !passwordState.text.isEmpty &&
               (!firstNameState.text.isEmpty || !lastNameState.text.isEmpty) &&
               !dateOfBirthState.text.isEmpty
    }
    
    var isLoginFormValid: Bool {
        return !emailState.text.isEmpty &&
               Validation.isValidEmail(emailState.text) &&
               !passwordState.text.isEmpty
    }
    
    func validateEmail() {
        emailState.validate { email in
            if email.isEmpty {
                return .invalid("電子郵件不能為空")
            } else if !Validation.isValidEmail(email) {
                return .invalid("請輸入有效的電子郵件地址")
            }
            return .valid
        }
    }
    
    func validatePassword() {
        passwordState.validate { password in
            if password.isEmpty {
                return .invalid("密碼不能為空")
            } else if !Validation.isValidPassword(password) {
                return .invalid("密碼至少需要8個字符")
            }
            return .valid
        }
    }

    func validateConfirmPassword(confirmPassword: String, password: String) {
        let trimmedConfirm = confirmPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        confirmPasswordState.validate { _ in
            if trimmedConfirm == trimmedPassword {
                return .valid
            }
            return .invalid("密碼不一致")
        }
    }
    
    func validateFirstName() {
        firstNameState.validate { firstName in
            if firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .invalid("請輸入姓名")
            }
            return .valid
        }
    }
    
    func validateLastName() {
        lastNameState.validate { lastName in
            if lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .invalid("請輸入姓氏")
            }
            return .valid
        }
    }
    
    func validateDateOfBirth() {
        dateOfBirthState.validate { dateOfBirth in
            if dateOfBirth.isEmpty {
                return .invalid("請選擇出生日期")
            } else if !Validation.isValidDateOfBirth(dateOfBirth) {
                return .invalid("請選擇有效的出生日期")
            }
            return .valid
        }
    }
    
    func validateEmergencyName() {
        emergencyNameState.validate { name in
            // 緊急聯絡人可選填，填寫時不得為空
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return .valid
            }
            return Validation.isValidName(name) ? .valid : .invalid("請輸入有效的姓名")
        }
    }
    
    func validateEmergencyPhone() {
        emergencyPhoneState.validate { phone in
            // 可選填：若有填寫，至少6碼
            let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return .valid
            }
            return trimmed.count >= 6 ? .valid : .invalid("請輸入有效的電話")
        }
    }
    
//    func validateAllFields() {
//        validateEmail()
//        validatePassword()
//        validateConfirmPassword()
//        validateFirstName()
//        validateLastName()
//        validateDateOfBirth()
//    }
}
