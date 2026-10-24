import Foundation

enum AppConfig {
    static var skipStoredAuth: Bool {
        // DEBUG: 每次都要求重新登入（暫時用來測試登入流程）
        // 改回保留登入狀態：return false
        return false
    }
}
