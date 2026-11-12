import Foundation
import SwiftUI

// MARK: - 每日檢測分數模型
struct DailyCheckInScores: Codable, Identifiable {
    let id = UUID()
    let physical: Int      // 生理健康 (1-5)
    let mental: Int        // 精神狀態 (1-5)
    let emotional: Int     // 情緒狀態 (1-5)
    let sleep: Int         // 睡眠品質 (1-5)
    let appetite: Int      // 飲食表現 (1-5)
    let date: Date
    
    var overall: Int {
        (physical + mental + emotional + sleep + appetite) / 5
    }
}

// MARK: - 生理節律模式
enum BiorhythmMode: String, CaseIterable {
    case standard = "標準"
    case personal = "個人"
    
    var description: String {
        switch self {
        case .standard:
            return "基於出生日期的傳統生理節律"
        case .personal:
            return "基於個人檢測數據的規律分析"
        }
    }
}

// MARK: - 生理節律數據
struct BiorhythmData {
    let physical: Double    // 體力/生理健康 (-100 到 100)
    let emotional: Double   // 情緒狀態 (-100 到 100)
    let intellectual: Double // 智力/精神狀態 (-100 到 100)
    let sleep: Double?      // 睡眠品質 (僅個人模式)
    let appetite: Double?   // 飲食表現 (僅個人模式)
    let mode: BiorhythmMode
    
    // 獲取指定指標的數值
    func getValue(for indicator: BiorhythmIndicator) -> Double {
        switch indicator {
        case .physical: return physical
        case .emotional: return emotional
        case .intellectual: return intellectual
        case .sleep: return sleep ?? 0
        case .appetite: return appetite ?? 0
        }
    }
}

// MARK: - 生理節律指標
enum BiorhythmIndicator: String, CaseIterable {
    case physical = "體力"
    case emotional = "情緒"
    case intellectual = "智力"
    case sleep = "睡眠"
    case appetite = "食慾"
    
    var standardCycle: Int {
        switch self {
        case .physical: return 23
        case .emotional: return 28
        case .intellectual: return 33
        case .sleep: return 25      // 自定義週期
        case .appetite: return 30   // 自定義週期
        }
    }
    
    var color: Color {
        switch self {
        case .physical: return AppColors.orange
        case .emotional: return AppColors.mediumBrown
        case .intellectual: return AppColors.lightBrown
        case .sleep: return AppColors.darkBrown
        case .appetite: return AppColors.lightYellow
        }
    }
}

// MARK: - 生理節律狀態
enum BiorhythmState {
    case high       // 高漲期
    case critical   // 臨界期
    case low        // 低谷期
    
    var description: String {
        switch self {
        case .high: return "高漲期"
        case .critical: return "臨界期"
        case .low: return "低谷期"
        }
    }
    
    var color: Color {
        switch self {
        case .high: return .green
        case .critical: return .orange
        case .low: return .red
        }
    }
}

// MARK: - 心理健康資源
struct MentalHealthResource: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let buttonText: String
    let action: ResourceAction
}

enum ResourceAction {
    case hotline
    case guide
    case techniques
    case map
    case relax
}

// MARK: - 心理測驗
struct PsychologicalTest: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let duration: String
    let questions: String
    let action: TestAction
}

enum TestAction {
    case phq9
    case gad7
    case bsrs5
    case rfq8
    case cesd
    case sats
    case aq10
    case psycap
    case cdrisc
    case pansi
    case bss
}

// MARK: - 健康指標類型
enum HealthIndicatorType: Codable, Hashable {
    case physical   // 生理健康
    case mental     // 精神狀態
    case emotional  // 情緒狀態
    case sleep      // 睡眠品質
    case appetite   // 飲食表現
    case overall    // 綜合指標
    
    var title: String {
        switch self {
        case .physical: return "生理健康"
        case .mental: return "精神狀態"
        case .emotional: return "情緒狀態"
        case .sleep: return "睡眠品質"
        case .appetite: return "飲食表現"
        case .overall: return "綜合指標"
        }
    }
    
    var color: Color {
        switch self {
        case .physical: return .red
        case .mental: return .orange
        case .emotional: return .blue
        case .sleep: return .purple
        case .appetite: return .green
        case .overall: return AppColors.orange
        }
    }
}

// MARK: - 每日檢測問題
struct DailyCheckInQuestion {
    let title: String
    let subtitle: String
    let category: HealthCategory
}

enum HealthCategory {
    case physical, mental, emotional, sleep, appetite
}

// MARK: - 心情選項
struct MoodOption {
    let emoji: String
    let label: String
    let value: Int
}

struct MoodDefinition: Identifiable {
    let code: String
    let emoji: String
    let label: String
    let value: Int

    var id: String { code }
}

enum MoodCatalog {
    static let all: [MoodDefinition] = [
        MoodDefinition(code: "VERY_BAD", emoji: "😫", label: "很差", value: 1),
        MoodDefinition(code: "BAD", emoji: "😐", label: "不好", value: 2),
        MoodDefinition(code: "OKAY", emoji: "🙂", label: "一般", value: 3),
        MoodDefinition(code: "GOOD", emoji: "😃", label: "良好", value: 4),
        MoodDefinition(code: "HAPPY", emoji: "🤩", label: "極佳", value: 5)
    ]

    static let defaultCode = "OKAY"

    static func entry(for code: String?) -> MoodDefinition? {
        guard let code else { return nil }
        return all.first { $0.code == code }
    }
}

// MARK: - 健康指標
struct HealthIndicator {
    let name: String
    let score: Int
}

// MARK: - ==== 個人節律相關模型 ==== -

// MARK: - 個人週期數據結構（簡化版）
struct PersonalCycle: Codable {
    let indicator: HealthIndicatorType
    let period: Double // 週期天數
    let lastUpdated: Date
    let dataPointsUsed: Int
}

// MARK: - 個人節律分析結果（簡化版）
struct PersonalRhythmResult: Codable {
    let cycles: [PersonalCycle]
    let totalDataPoints: Int
    let analysisDate: Date
    
    init(cycles: [PersonalCycle], totalDataPoints: Int = 0) {
        self.cycles = cycles
        self.totalDataPoints = totalDataPoints
        self.analysisDate = Date()
    }
}

// MARK: - HealthIndicatorType CaseIterable 擴展
extension HealthIndicatorType: CaseIterable {
    public static var allCases: [HealthIndicatorType] {
        return [.physical, .mental, .emotional, .sleep, .appetite]
    }
}
