import SwiftUI
import Foundation

// MARK: - 治療模式
enum TherapyMode: String, CaseIterable, Codable {
    case chatMode = "chatMode"
    case cbtMode = "CBT"
    case dbtMode = "DBT"
    case mbtMode = "MBT"
    case mbctMode = "MBCT"
    case initial = "INITIAL"

    static var selectableCases: [TherapyMode] {
        return [.initial, .mbtMode, .cbtMode, .dbtMode, .mbctMode]
    }
    
    var displayName: String {
        switch self {
        case .chatMode: return "聊天模式"
        case .cbtMode: return "CBT模式"
        case .dbtMode: return "DBT模式"
        case .mbtMode: return "MBT模式"
        case .mbctMode: return "MBCT模式"
        case .initial: return "初始模式"
        }
    }
    
    var shortName: String {
        switch self {
        case .chatMode: return "聊天"
        case .cbtMode: return "CBT"
        case .dbtMode: return "DBT"
        case .mbtMode: return "MBT"
        case .mbctMode: return "MBCT"
        case .initial: return "初始"
        }
    }
    
    var description: String {
        switch self {
        case .chatMode: return "輕鬆自在的日常對話"
        case .cbtMode: return "溫柔引導探索想法－情緒－行為的連結，不糾正也不辯論"
        case .dbtMode: return "聚焦情緒調節、壓力耐受與人際界線，幫助當下穩住自己"
        case .mbtMode: return "培養對自己與他人內在狀態的好奇，放慢互動中的思考"
        case .mbctMode: return "正念取向，觀察想法與情緒的起伏，需要時做簡短安定練習"
        case .initial: return "初次對談，溫暖接住與建立安全感，讓對話自然開始"
        }
    }
    
    var color: Color {
        switch self {
        case .chatMode: return AppColors.chatModeColor
        case .cbtMode: return AppColors.cbtModeColor
        case .dbtMode: return AppColors.dbtModeColor
        case .mbtMode: return AppColors.mbtModeColor
        case .mbctMode: return AppColors.cbtModeColor
        case .initial: return AppColors.chatModeColor
        }
    }
    
    var welcomeMessage: String {
        switch self {
        case .chatMode:
            return "您好！我是您的聊天夥伴 ☺️\n\n在這裡，我們可以輕鬆聊聊日常生活、心情感受，或任何您想分享的話題。我會用溫暖、自然的方式與您對話，就像和朋友聊天一樣。\n\n有什麼想聊的嗎？"
        case .cbtMode:
            return "您好！我是您的CBT助手 🧠\n\n認知行為療法(CBT)可以幫助您：\n• 識別負面的思維模式\n• 挑戰不合理的想法\n• 建立更積極健康的認知習慣\n\n您可以分享任何讓您困擾的想法或情緒，我們一起來分析和處理。"
        case .dbtMode:
            return "您好！我是您的DBT助手 🌿\n\n辯證行為治療(DBT)常用來幫助您：\n• 穩定強烈情緒與衝動\n• 提升壓力下的自我安頓能力\n• 練習更清楚地表達需求與界線\n\n如果你現在情緒很滿、很亂，或不知道怎麼撐過眼前這一刻，我可以陪你一步一步整理。"
        case .mbtMode:
            return "您好！我是您的MBT助手 🤝\n\n心智化療法(MBT)專注於：\n• 增強情感覺察能力\n• 改善人際關係理解\n• 提升心智化水平\n\n無論是人際困擾、情緒混亂，還是想更好地理解自己和他人，我都可以陪伴您一起探索。"
        case .mbctMode:
            return "您好！我是您的MBCT助手 🧘\n\n正念認知療法(MBCT)結合正念覺察與認知行為技巧，幫助您：\n• 更清楚地覺察念頭與情緒\n• 降低自動化的負面反應\n• 建立更穩定的身心狀態\n\n想從今天的感受開始聊聊嗎？"
        case .initial:
            return "您好！我是您的對話助手。\n\n我們可以從任何您想分享的事情開始。我會一步步陪您整理感受、釐清想法。\n\n現在最想聊的是什麼呢？"
        }
    }
}

extension TherapyMode {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        switch rawValue {
        case "chatMode": self = .chatMode
        case "CBT": self = .cbtMode
        case "DBT": self = .dbtMode
        case "MBT": self = .mbtMode
        case "MBCT": self = .mbctMode
        case "INITIAL": self = .initial
        default: self = .chatMode
        }
    }
}

// MARK: - 聊天訊息
struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let backendId: String?
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let mode: TherapyMode
    
    init(id: UUID = UUID(), backendId: String? = nil, content: String, isFromUser: Bool, timestamp: Date = Date(), mode: TherapyMode) {
        self.id = id
        self.backendId = backendId
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.mode = mode
    }
}

// MARK: - 聊天會話
struct ChatSession: Identifiable, Codable {
    let id: UUID
    let backendId: String?
    var title: String
    var therapyMode: TherapyMode
    var lastMessage: String
    var lastUpdated: Date
    var tags: [String]
    var messageCount: Int
    
    init(id: UUID = UUID(), backendId: String? = nil, title: String, therapyMode: TherapyMode, lastMessage: String = "", lastUpdated: Date = Date(), tags: [String] = [], messageCount: Int = 0) {
        self.id = id
        self.backendId = backendId
        self.title = title
        self.therapyMode = therapyMode
        self.lastMessage = lastMessage
        self.lastUpdated = lastUpdated
        self.tags = tags
        self.messageCount = messageCount
    }
}
