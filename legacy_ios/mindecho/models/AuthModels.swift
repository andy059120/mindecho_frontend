import Foundation
import SwiftUI

// MARK: - 用戶數據模型
struct User: Codable, Identifiable {
    /// 部分回傳有 `id` 和 `userId`，留兩個欄位避免解析失敗
    let id: String?
    let userId: String?
    let email: String
    let name: String?
    let firstName: String?
    let lastName: String?
    let nickname: String?
    let avatar: String?
    let dateOfBirth: String?
    let birthYear: Int?
    let birthMonth: Int?
    let gender: String?
    let educationLevel: Int?
    let emergencyContactName: String?
    let emergencyContactPhone: String?
    let supportContactName: String?
    let supportContactInfo: String?
    let familyContactName: String?
    let familyContactInfo: String?
    let isActive: Bool?
    let lastLoginAt: String?
    let preferences: [String: String]?
    let emergencyContacts: [EmergencyContact]?
    let createdAt: String?
    let updatedAt: String?
    let continuousLoginDays: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case email
        case name
        case firstName
        case lastName
        case nickname
        case avatar
        case dateOfBirth
        case birthYear
        case birthMonth
        case gender
        case educationLevel
        case emergencyContactName
        case emergencyContactPhone
        case supportContactName
        case supportContactInfo
        case familyContactName
        case familyContactInfo
        case isActive
        case lastLoginAt
        case preferences
        case emergencyContacts
        case createdAt
        case updatedAt
        case continuousLoginDays
    }

    /// 取後端的 userId 為主，若沒有則使用 id
    var primaryId: String {
        return userId ?? id ?? ""
    }
    
    var fullName: String {
        if let name, !name.isEmpty {
            return name
        }
        let first = firstName ?? ""
        let last = lastName ?? ""
        return "\(last) \(first)".trimmingCharacters(in: .whitespaces)
    }
    
    var initials: String {
        let firstInitial = firstName?.first?.uppercased() ?? ""
        let lastInitial = lastName?.first?.uppercased() ?? ""
        return "\(firstInitial)\(lastInitial)"
    }
}

struct EmergencyContact: Codable, Identifiable {
    let id: String
    let name: String
    let relation: String
    let contactInfo: String
    let sortOrder: Int?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - 註冊請求數據模型
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
    let dateOfBirth: String
    let birthYear: Int?
    let birthMonth: Int?
    let nickname: String?
    let emergencyContacts: [EmergencyContactPayload]
    let gender: String
    let educationLevel: Int
    let dataAnalysisConsent: Bool
    let supportContactName: String?
    let supportContactInfo: String?
    let familyContactName: String?
    let familyContactInfo: String?
    let mostImportantReasons: String
    
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "password": password,
            "name": name,
            "dateOfBirth": dateOfBirth,
            "birthYear": birthYear as Any,
            "birthMonth": birthMonth as Any,
            "nickname": nickname as Any,
            "emergencyContacts": emergencyContacts.map { $0.toDictionary() },
            "gender": gender,
            "educationLevel": educationLevel,
            "dataAnalysisConsent": dataAnalysisConsent,
            "supportContactName": supportContactName as Any,
            "supportContactInfo": supportContactInfo as Any,
            "familyContactName": familyContactName as Any,
            "familyContactInfo": familyContactInfo as Any,
            "mostImportantReasons": mostImportantReasons
        ]
    }
}

struct EmergencyContactPayload: Codable {
    let name: String
    let relation: String
    let contactInfo: String
    
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "relation": relation,
            "contactInfo": contactInfo
        ]
    }
}

// MARK: - 登入請求數據模型
struct LoginRequest: Codable {
    let email: String
    let password: String
    
    func toDictionary() -> [String: Any] {
        return [
            "email": email,
            "password": password
        ]
    }
}

struct ResetPasswordRequest: Codable {
    let name: String
    let email: String
    let newPassword: String

    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "email": email,
            "newPassword": newPassword
        ]
    }
}

// MARK: - 認證回應數據模型
struct AuthResponse: Codable {
    let success: Bool?
    let message: String?
    let user: User?
    let token: String?
    let refreshToken: String?
    
    // 後端有時回傳 userData 或 accessToken
    private enum AdditionalKeys: String, CodingKey {
        case userData
        case accessToken
    }
    
    // 自訂初始化方法，處理後端回應格式
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.message = try container.decodeIfPresent(String.self, forKey: .message)
        // 嘗試解析 user 或 userData
        if let user = try container.decodeIfPresent(User.self, forKey: .user) {
            self.user = user
        } else {
            let additional = try decoder.container(keyedBy: AdditionalKeys.self)
            self.user = try additional.decodeIfPresent(User.self, forKey: .userData)
        }
        
        if let token = try container.decodeIfPresent(String.self, forKey: .token) {
            self.token = token
        } else {
            let additional = try decoder.container(keyedBy: AdditionalKeys.self)
            self.token = try additional.decodeIfPresent(String.self, forKey: .accessToken)
        }
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        
        // 如果後端沒有 success 字段，根據其他條件判斷
        if let success = try container.decodeIfPresent(Bool.self, forKey: .success) {
            self.success = success
        } else {
            // 如果有 user 或 token 就認為成功，否則根據 message 判斷
            if self.user != nil || self.token != nil {
                self.success = true
            } else if let message = self.message, message.lowercased().contains("success") {
                self.success = true
            } else {
                self.success = false
            }
        }
    }
    
    // 保留原始的初始化方法（用於手動創建）
    init(success: Bool?, message: String?, user: User?, token: String?, refreshToken: String?) {
        self.success = success
        self.message = message
        self.user = user
        self.token = token
        self.refreshToken = refreshToken
    }
    
    enum CodingKeys: String, CodingKey {
        case success, message, user, token, refreshToken
    }
}

// MARK: - 表單驗證錯誤類型
enum ValidationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emptyFirstName
    case emptyLastName
    case invalidDateOfBirth
    case passwordMismatch
    case emptyField(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "請輸入有效的電子郵件地址"
        case .weakPassword:
            return "密碼至少需要8個字符"
        case .emptyFirstName:
            return "請輸入名字"
        case .emptyLastName:
            return "請輸入姓氏"
        case .invalidDateOfBirth:
            return "請選擇有效的出生日期"
        case .passwordMismatch:
            return "密碼不一致"
        case .emptyField(let fieldName):
            return "\(fieldName)不能為空"
        }
    }
}

// MARK: - 認證狀態枚舉
enum AuthState: Equatable {
    case idle           // 初始狀態
    case loading        // 載入中
    case authenticated  // 已認證
    case unauthenticated // 未認證
    case error(String)  // 錯誤狀態
    
    // 實現 Equatable 協議
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.authenticated, .authenticated), (.unauthenticated, .unauthenticated):
            return true
        case let (.error(lhsMessage), .error(rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - 表單字段類型
enum FormField: CaseIterable {
    case email
    case password
    case confirmPassword
    case firstName
    case lastName
    case dateOfBirth
    case emergencyName
    case emergencyRelation
    case emergencyPhone
    case supportContactName
    case supportContactInfo
    case familyContactName
    case familyContactInfo
    
    var placeholder: String {
        switch self {
        case .email:
            return "電子郵件"
        case .password:
            return "密碼"
        case .confirmPassword:
            return "確認密碼"
        case .firstName:
            return "名字"
        case .lastName:
            return "姓氏"
        case .dateOfBirth:
            return "出生日期"
        case .emergencyName:
            return "緊急聯絡人姓名"
        case .emergencyRelation:
            return "緊急聯絡人關係"
        case .emergencyPhone:
            return "緊急聯絡人電話"
        case .supportContactName:
            return "朋友/支援者姓名"
        case .supportContactInfo:
            return "朋友/支援者電話"
        case .familyContactName:
            return "親人姓名"
        case .familyContactInfo:
            return "親人電話"
        }
    }
    
    var keyboardType: UIKeyboardType {
        switch self {
        case .email:
            return .emailAddress
        case .password, .confirmPassword:
            return .default
        case .firstName, .lastName:
            return .namePhonePad
        case .dateOfBirth:
            return .numbersAndPunctuation
        case .emergencyName, .emergencyRelation:
            return .namePhonePad
        case .emergencyPhone:
            return .phonePad
        case .supportContactName, .familyContactName:
            return .namePhonePad
        case .supportContactInfo, .familyContactInfo:
            return .phonePad
        }
    }
    
    var isSecure: Bool {
        switch self {
        case .password, .confirmPassword:
            return true
        default:
            return false
        }
    }
}
