import SwiftUI

struct AppColors {
    // MARK: - 主要品牌色
    static let orange = Color(red: 0.89, green: 0.49, blue: 0.20) // #E37D33
    static let lightYellow = Color(red: 0.98, green: 0.94, blue: 0.87) // #FAF0DE
    static let darkBrown = Color(red: 0.40, green: 0.26, blue: 0.13) // #664321
    static let mediumBrown = Color(red: 0.55, green: 0.35, blue: 0.20) // #8C5932
    static let lightBrown = Color(red: 0.70, green: 0.55, blue: 0.40) // #B38C66
    
    // MARK: - 心理健康資源和測驗專用色彩
    static let resourceCardOrange = Color(red: 0.95, green: 0.65, blue: 0.35) // 心理健康資源卡片橘色
    static let resourceCardYellow = Color(red: 0.98, green: 0.90, blue: 0.70) // 心理健康資源卡片黃色
    static let testCardYellow = Color(red: 0.95, green: 0.88, blue: 0.55) // 心理測驗卡片黃色
    static let testCardLightYellow = Color(red: 0.98, green: 0.94, blue: 0.80) // 心理測驗卡片淺黃色
    
    // MARK: - 聊天功能專用色彩
    // 治療模式顏色
    static let chatModeColor = Color(red: 0.8, green: 0.4, blue: 0.1)     // 聊天模式橘色
    static let cbtModeColor = Color(red: 0.4, green: 0.2, blue: 0.1)      // CBT模式深棕色
    static let dbtModeColor = Color(red: 0.67, green: 0.33, blue: 0.16)   // DBT模式陶土棕
    static let mbtModeColor = Color(red: 0.6, green: 0.3, blue: 0.1)      // MBT模式中棕色
    
    // 聊天界面背景
    static let chatBackground = Color(red: 0.996, green: 0.953, blue: 0.780) // 聊天頁面背景色
    
    // 聊天氣泡顏色
    static let userBubbleColor = Color(red: 0.8, green: 0.4, blue: 0.1)    // 使用者訊息氣泡
    static let aiBubbleColor = Color.white                                   // AI 訊息氣泡
    static let bubbleTextColor = Color(red: 0.4, green: 0.2, blue: 0.1)    // AI 訊息文字顏色
    
    // 標題和文字顏色
    static let titleColor = Color(red: 0.4, green: 0.2, blue: 0.1)         // 主標題顏色
    static let subtitleColor = Color.gray                                    // 副標題顏色
    
    // MARK: - 向後兼容的顏色別名
    static let cardBackground = Color.white
    static let lightOrange = orange.opacity(0.3)
    static let reminderGradient = LinearGradient(
        gradient: Gradient(colors: [lightYellow, orange.opacity(0.3)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - 治療模式顏色映射（供 TherapyMode 使用）
    static func colorForMode(_ mode: TherapyMode) -> Color {
        switch mode {
        case .chatMode: return chatModeColor
        case .cbtMode: return cbtModeColor
        case .dbtMode: return dbtModeColor
        case .mbtMode: return mbtModeColor
        case .mbctMode: return cbtModeColor
        case .initial: return chatModeColor
        }
    }
}
