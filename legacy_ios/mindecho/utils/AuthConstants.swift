import Foundation

// MARK: - 認證相關常數
struct AuthConstants {
    
    // MARK: - API 端點
    struct API {
        // 基礎 URL - 請替換為你的實際 API URL
        static let baseURL = "https://mindechoserver.com:8443/api"
        
        // 認證端點
        static let register = "/api/auth/register"
        static let login = "/api/auth/login"
        static let logout = "/api/auth/logout"
        static let refresh = "/api/auth/refresh"
        static let resetPassword = "/api/auth/reset-password"
    }
    
    // MARK: - 本地存儲鍵值
    struct UserDefaultsKeys {
        static let authToken = "mindecho_auth_token"
        static let refreshToken = "mindecho_refresh_token"
        static let userData = "mindecho_user_data"
        static let isFirstLaunch = "mindecho_is_first_launch"
        static let loginDate = "mindecho_login_date"
        static let importantQuote = "mindecho_important_quote"
        static let rememberedEmail = "mindecho_remembered_email"
        static let shouldRememberAccount = "mindecho_should_remember_account"
    }
    
    // MARK: - 表單驗證規則
    struct Validation {
        static let minimumPasswordLength = 8
        static let maximumPasswordLength = 128
        static let maximumNameLength = 50
        static let maximumAgeYears = 150
    }
    
    // MARK: - 網路設定
    struct Network {
        static let requestTimeout: TimeInterval = 30.0
        static let maxRetryAttempts = 3
    }
    
    // MARK: - 錯誤訊息
    struct ErrorMessages {
        static let networkError = "網路連接失敗，請檢查網路設定"
        static let serverError = "服務器錯誤，請稍後再試"
        static let invalidCredentials = "電子郵件或密碼錯誤"
        static let emailAlreadyExists = "此電子郵件已被註冊"
        static let passwordTooWeak = "密碼強度不足，請選擇更強的密碼"
        static let invalidEmail = "請輸入有效的電子郵件地址"
        static let requiredField = "此欄位為必填"
        static let passwordMismatch = "密碼不一致"
        static let invalidDateOfBirth = "請選擇有效的出生日期"
    }
    
    // MARK: - 成功訊息
    struct SuccessMessages {
        static let registrationSuccess = "註冊成功！歡迎加入 PsychEcho！"
        static let loginSuccess = "登入成功！"
        static let logoutSuccess = "已安全登出"
        static let passwordResetSent = "密碼重置連結已發送到您的電子郵件"
    }
    
    // MARK: - 動畫設定
    struct Animation {
        static let defaultDuration: Double = 0.3
        static let springResponse: Double = 0.6
        static let springDamping: Double = 0.8
        static let loadingMinimumDuration: Double = 1.0 // 最少顯示載入動畫的時間
    }
}

// MARK: - 環境配置
enum AppEnvironment {
    case development
    case staging
    case production
    
    // 當前環境 - 可根據 Build Configuration 自動切換
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    // 根據環境返回對應的 API URL
    var apiBaseURL: String {
        switch self {
        case .development:
            return "https://mindechoserver.com:8443/api"
        case .staging:
            return "https://mindechoserver.com:8443/api"
        case .production:
            return "https://mindechoserver.com:8443/api"
        }
    }
    
    // 是否顯示調試信息
    var isDebugMode: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}

// MARK: - 認證狀態常數
extension AuthState {
    var description: String {
        switch self {
        case .idle:
            return "閒置"
        case .loading:
            return "載入中"
        case .authenticated:
            return "已認證"
        case .unauthenticated:
            return "未認證"
        case .error(let message):
            return "錯誤: \(message)"
        }
    }
}

// MARK: - HTTP 狀態碼
struct HTTPStatusCode {
    static let ok = 200
    static let created = 201
    static let badRequest = 400
    static let unauthorized = 401
    static let forbidden = 403
    static let notFound = 404
    static let conflict = 409
    static let internalServerError = 500
}

// MARK: - 日期格式常數
struct DateFormats {
    static let dateOfBirth = "yyyy-MM-dd"
    static let timestamp = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    static let displayDate = "yyyy年MM月dd日"
    static let displayDateTime = "yyyy年MM月dd日 HH:mm"
}
