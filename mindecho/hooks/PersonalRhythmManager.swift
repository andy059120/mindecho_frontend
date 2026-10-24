import Foundation
import SwiftUI
import Combine

// MARK: - PersonalRhythmManager.swift - 個人節律數據管理器（基於五項指標）
class PersonalRhythmManager: ObservableObject {
    static let shared = PersonalRhythmManager()
    private static let minRequiredDataPoints = 1
    
    // MARK: - Published 屬性
    @Published var currentResult: PersonalRhythmResult?
    @Published var isCalculating: Bool = false
    @Published var lastCalculationDate: Date?
    
    // MARK: - 計算屬性
    var hasData: Bool {
        guard let result = currentResult else { return false }
        return result.totalDataPoints >= Self.minRequiredDataPoints && !result.cycles.isEmpty
    }
    
    // MARK: - 私有屬性
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let personalRhythmKey = "personalRhythmResult"
    
    // MARK: - 初始化
    private init() {
        loadStoredResult()
        setupDataObserver()
    }
    
    // MARK: - 數據觀察
    private func setupDataObserver() {
        // 監聽 DailyCheckInManager 的數據變化
        DailyCheckInManager.shared.$weeklyScores
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] scores in
                if scores.count >= Self.minRequiredDataPoints {
                    self?.calculateRhythmsIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 主要計算方法
    func calculateRhythmsIfNeeded(force: Bool = false) {
        let scores = DailyCheckInManager.shared.weeklyScores
        
        guard scores.count >= Self.minRequiredDataPoints else {
            print("PersonalRhythm: 數據不足，需要至少\(Self.minRequiredDataPoints)筆記錄")
            return
        }
        
        // 每5筆新數據或強制更新時重新計算
        let shouldUpdate = force ||
                          (scores.count % 5 == 0) ||
                          (lastCalculationDate == nil) ||
                          (currentResult == nil)
        
        if shouldUpdate {
            performCalculation(with: scores)
        }
    }
    
    // MARK: - 執行計算
    private func performCalculation(with scores: [DailyCheckInScores]) {
        isCalculating = true
        
        print("PersonalRhythm: 開始計算個人節律，使用 \(scores.count) 筆數據")
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let result = PersonalRhythmCalculator.calculatePersonalRhythms(from: scores)
            
            DispatchQueue.main.async {
                self?.finishCalculation(with: result)
            }
        }
    }
    
    // MARK: - 完成計算
    private func finishCalculation(with result: PersonalRhythmResult) {
        currentResult = result
        lastCalculationDate = Date()
        isCalculating = false
        
        saveResult(result)
        
        print("PersonalRhythm: 計算完成，基於 \(result.totalDataPoints) 筆數據")
        for cycle in result.cycles {
            print("  - \(cycle.indicator.displayName): \(String(format: "%.0f", cycle.period))天")
        }
    }
    
    // MARK: - 本地存儲
    private func saveResult(_ result: PersonalRhythmResult) {
        do {
            let data = try JSONEncoder().encode(result)
            userDefaults.set(data, forKey: personalRhythmKey)
            print("PersonalRhythm: 已保存計算結果到本地")
        } catch {
            print("PersonalRhythm: 保存失敗 - \(error)")
        }
    }
    
    private func loadStoredResult() {
        guard let data = userDefaults.data(forKey: personalRhythmKey) else {
            print("PersonalRhythm: 沒有找到存儲的結果")
            return
        }
        
        do {
            let result = try JSONDecoder().decode(PersonalRhythmResult.self, from: data)
            
            // 檢查當前是否有足夠的實際數據支持這個結果
            let currentDataCount = DailyCheckInManager.shared.weeklyScores.count
            if currentDataCount < Self.minRequiredDataPoints {
                print("PersonalRhythm: 存儲結果無效（當前數據不足：\(currentDataCount)筆），已清除")
                clearStoredData()
                return
            }
            
            currentResult = result
            print("PersonalRhythm: 已載入存儲的結果，包含 \(result.totalDataPoints) 筆數據")
        } catch {
            print("PersonalRhythm: 載入失敗 - \(error)")
        }
    }
    
    // MARK: - 公開方法
    func forceRecalculation() {
        calculateRhythmsIfNeeded(force: true)
    }
    
    func clearStoredData() {
        // 清除UserDefaults中的存儲數據
        userDefaults.removeObject(forKey: personalRhythmKey)
        // 清除內存中的數據
        currentResult = nil
        lastCalculationDate = nil
        print("PersonalRhythm: 已清除所有存儲數據")
        
        // 立即保存空狀態到UserDefaults確保清除
        userDefaults.synchronize()
    }
    
    // MARK: - 測試數據生成器（基於五項指標）
    func generateTestData() {
        var testScores: [DailyCheckInScores] = []
        let calendar = Calendar.current
        
        print("PersonalRhythm: 開始生成測試數據...")
        
        for i in 0..<60 {  // 生成60天數據
            guard let date = calendar.date(byAdding: .day, value: -i, to: Date()) else { continue }
            
            // 基於真實五項指標的週期模式生成
            let physicalValue = generateCyclicValue(day: i, period: 25, baseline: 65)  // 生理週期
            let mentalValue = generateCyclicValue(day: i, period: 31, baseline: 60)    // 精神週期
            let emotionalValue = generateCyclicValue(day: i, period: 27, baseline: 62) // 情緒週期
            let sleepValue = generateCyclicValue(day: i, period: 23, baseline: 58)     // 睡眠週期
            let appetiteValue = generateCyclicValue(day: i, period: 29, baseline: 64)  // 食慾週期
            
            let score = DailyCheckInScores(
                physical: physicalValue,
                mental: mentalValue,
                emotional: emotionalValue,
                sleep: sleepValue,
                appetite: appetiteValue,
                date: date
            )
            
            testScores.append(score)
        }
        
        // 更新數據
        DailyCheckInManager.shared.weeklyScores = testScores
        
        print("PersonalRhythm: 已生成 \(testScores.count) 筆測試數據")
        
        // 強制重新計算
        forceRecalculation()
    }
    
    // MARK: - 改進的週期值生成（更真實的週期模式）
    private func generateCyclicValue(day: Int, period: Double, baseline: Double) -> Int {
        let angle = Double(day) / period * 2.0 * .pi
        let cycleValue = sin(angle) * 25 + baseline  // ±25的波動，圍繞基準值
        let noise = Double.random(in: -10...10)      // 隨機噪音
        let weekdayEffect = (day % 7 < 5) ? 3 : -2   // 工作日vs週末的微調
        
        let finalValue = cycleValue + noise + Double(weekdayEffect)
        
        return max(0, min(100, Int(finalValue.rounded())))
    }
    
    // MARK: - 調試方法
    func getDebugInfo() -> String {
        guard let result = currentResult else { return "無計算結果" }
        
        var info = "個人節律調試信息:\n"
        info += "基於五項指標數據分析\n"
        info += "總數據點: \(result.totalDataPoints)\n"
        info += "最後計算: \(lastCalculationDate?.formatted() ?? "未知")\n\n"
        
        for cycle in result.cycles {
            info += "\(cycle.indicator.displayName): \(String(format: "%.0f", cycle.period)) 天 "
            info += "(基於 \(cycle.dataPointsUsed) 筆數據)\n"
        }
        
        return info
    }
    
    // MARK: - 獲取特定指標的週期（修正版 - 無預設值）
    func getCycleDays(for indicator: HealthIndicatorType) -> Int? {
        guard let result = currentResult,
              let cycle = result.cycles.first(where: { $0.indicator == indicator }) else {
            return nil  // 沒有檢測到週期時返回 nil
        }
        return Int(cycle.period)
    }
}
