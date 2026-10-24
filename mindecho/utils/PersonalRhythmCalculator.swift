import Foundation

// MARK: - PersonalRhythmCalculator.swift - 個人節律計算邏輯（基於五項指標）

class PersonalRhythmCalculator {
    
    // MARK: - 配置參數
    private struct Config {
        static let minDataPoints = 1     // 最少 1 筆就顯示結果
        static let updateInterval = 5    // 每5筆新數據更新
        static let minPeriod: Double = 7
        static let maxPeriod: Double = 45
        static let minConfidence = 0.25  // 提高信心度門檻
        
        // 不使用預設週期，無法檢測時返回nil
    }
    
    // MARK: - 主要計算方法
    static func calculatePersonalRhythms(from scores: [DailyCheckInScores]) -> PersonalRhythmResult {
        guard scores.count >= Config.minDataPoints else {
            return PersonalRhythmResult(
                cycles: [],  // 空陣列表示無法檢測
                totalDataPoints: scores.count
            )
        }
        
        let sortedScores = scores.sorted { $0.date < $1.date }
        var cycles: [PersonalCycle] = []
        
        print("PersonalRhythm: 開始分析 \(sortedScores.count) 筆五項指標數據")
        
        // 為每個指標嘗試計算個人化週期
        for indicator in HealthIndicatorType.allCases {
            if indicator == .overall { continue } // 跳過整體指標
            
            if let period = calculatePeriodForIndicator(indicator, scores: sortedScores) {
                let cycle = PersonalCycle(
                    indicator: indicator,
                    period: period,
                    lastUpdated: Date(),
                    dataPointsUsed: sortedScores.count
                )
                cycles.append(cycle)
                print("  - \(indicator.displayName): \(String(format: "%.1f", period)) 天")
            } else {
                print("  - \(indicator.displayName): 無法檢測有效週期")
            }
        }
        
        return PersonalRhythmResult(
            cycles: cycles,
            totalDataPoints: scores.count
        )
    }
    
    // MARK: - 單指標週期計算（返回可選值）
    private static func calculatePeriodForIndicator(
        _ indicator: HealthIndicatorType,
        scores: [DailyCheckInScores]
    ) -> Double? {
        
        let values = extractValues(for: indicator, from: scores)
        guard values.count >= Config.minDataPoints else {
            return nil
        }
        
        print("    分析 \(indicator.displayName) - 數據點: \(values.count)")
        
        // 使用改進的週期檢測算法
        return findOptimalPeriodImproved(values: values, indicator: indicator)
    }
    
    // MARK: - 改進的週期檢測算法（返回可選值）
    private static func findOptimalPeriodImproved(values: [Double], indicator: HealthIndicatorType) -> Double? {
        var bestPeriod: Double?
        var maxScore = 0.0
        
        print("      搜索週期範圍: \(Config.minPeriod) - \(Config.maxPeriod) 天")
        
        // 以0.5天為步長搜索
        let searchRange = stride(from: Config.minPeriod, through: Config.maxPeriod, by: 0.5)
        
        for testPeriod in searchRange {
            let score = calculatePeriodScore(values: values, period: testPeriod)
            
            print("        測試 \(String(format: "%.1f", testPeriod)) 天: 評分 \(String(format: "%.3f", score))")
            
            if score > maxScore {
                maxScore = score
                bestPeriod = testPeriod
            }
        }
        
        // 檢查信心度
        if maxScore < Config.minConfidence {
            print("      \(indicator.displayName) 最高評分 \(String(format: "%.3f", maxScore)) 低於門檻 \(Config.minConfidence)，無法檢測")
            return nil
        }
        
        guard let period = bestPeriod else {
            print("      未找到有效週期")
            return nil
        }
        
        print("      \(indicator.displayName) 檢測到週期: \(String(format: "%.1f", period)) 天 (信心度: \(String(format: "%.3f", maxScore)))")
        return period
    }
    
    // MARK: - 週期評分函數（結合多種指標）
    private static func calculatePeriodScore(values: [Double], period: Double) -> Double {
        let intPeriod = Int(period.rounded())
        guard intPeriod > 0 && intPeriod < values.count else { return 0.0 }
        
        // 1. 自相關性評分
        let autocorrelation = calculateAutocorrelation(values: values, lag: intPeriod)
        
        // 2. 週期一致性評分
        let consistency = calculatePeriodConsistency(values: values, period: period)
        
        // 3. 振幅穩定性評分
        let amplitudeStability = calculateAmplitudeStability(values: values, period: period)
        
        // 綜合評分（加權平均）
        let combinedScore = (autocorrelation * 0.5) + (consistency * 0.3) + (amplitudeStability * 0.2)
        
        return combinedScore
    }
    
    // MARK: - 自相關計算（改進版）
    private static func calculateAutocorrelation(values: [Double], lag: Int) -> Double {
        guard lag < values.count / 2 else { return 0.0 }
        
        let n = values.count - lag
        guard n > 0 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        var numerator = 0.0
        var denominator1 = 0.0
        var denominator2 = 0.0
        
        for i in 0..<n {
            let x = values[i] - mean
            let y = values[i + lag] - mean
            numerator += x * y
            denominator1 += x * x
            denominator2 += y * y
        }
        
        let denominator = sqrt(denominator1 * denominator2)
        return denominator > 0 ? abs(numerator / denominator) : 0.0
    }
    
    // MARK: - 週期一致性計算
    private static func calculatePeriodConsistency(values: [Double], period: Double) -> Double {
        let intPeriod = Int(period.rounded())
        guard intPeriod > 0 else { return 0.0 }
        
        var cycles: [[Double]] = []
        
        // 將數據分割為週期段
        for startIndex in stride(from: 0, to: values.count - intPeriod, by: intPeriod) {
            let endIndex = min(startIndex + intPeriod, values.count)
            let cycle = Array(values[startIndex..<endIndex])
            if cycle.count == intPeriod {
                cycles.append(cycle)
            }
        }
        
        guard cycles.count >= 2 else { return 0.0 }
        
        // 計算週期間的相關性
        var correlations: [Double] = []
        
        for i in 0..<cycles.count-1 {
            for j in (i+1)..<cycles.count {
                let correlation = calculateCorrelation(cycles[i], cycles[j])
                correlations.append(correlation)
            }
        }
        
        return correlations.isEmpty ? 0.0 : correlations.reduce(0, +) / Double(correlations.count)
    }
    
    // MARK: - 振幅穩定性計算
    private static func calculateAmplitudeStability(values: [Double], period: Double) -> Double {
        let intPeriod = Int(period.rounded())
        guard intPeriod > 0 && values.count > intPeriod * 2 else { return 0.0 }
        
        var amplitudes: [Double] = []
        
        // 計算每個週期的振幅
        for startIndex in stride(from: 0, to: values.count - intPeriod, by: intPeriod) {
            let endIndex = min(startIndex + intPeriod, values.count)
            let cycle = Array(values[startIndex..<endIndex])
            
            if cycle.count == intPeriod {
                let maxVal = cycle.max() ?? 0.0
                let minVal = cycle.min() ?? 0.0
                amplitudes.append(maxVal - minVal)
            }
        }
        
        guard amplitudes.count >= 2 else { return 0.0 }
        
        // 計算振幅變異係數的倒數作為穩定性指標
        let mean = amplitudes.reduce(0, +) / Double(amplitudes.count)
        let variance = amplitudes.map { pow($0 - mean, 2) }.reduce(0, +) / Double(amplitudes.count)
        let stdDev = sqrt(variance)
        
        let coefficientOfVariation = mean > 0 ? stdDev / mean : 1.0
        return max(0.0, 1.0 - coefficientOfVariation)
    }
    
    // MARK: - 皮爾遜相關係數
    private static func calculateCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count == y.count && x.count > 1 else { return 0.0 }
        
        let n = Double(x.count)
        let sumX = x.reduce(0, +)
        let sumY = y.reduce(0, +)
        let sumXY = zip(x, y).map(*).reduce(0, +)
        let sumX2 = x.map { $0 * $0 }.reduce(0, +)
        let sumY2 = y.map { $0 * $0 }.reduce(0, +)
        
        let numerator = n * sumXY - sumX * sumY
        let denominator = sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))
        
        return denominator > 0 ? abs(numerator / denominator) : 0.0
    }
    
    // MARK: - 輔助方法
    private static func extractValues(for indicator: HealthIndicatorType, from scores: [DailyCheckInScores]) -> [Double] {
        return scores.compactMap { score in
            switch indicator {
            case .physical: return Double(score.physical)
            case .mental: return Double(score.mental)
            case .emotional: return Double(score.emotional)
            case .sleep: return Double(score.sleep)
            case .appetite: return Double(score.appetite)
            case .overall: return Double(score.overall)
            }
        }
    }
    
    // MARK: - 創建空週期列表（無預設值）
    static func createDefaultCycles() -> [PersonalCycle] {
        // 返回空陣列，不提供預設週期
        return []
    }
}

// 注意：PersonalRhythmResult 和 PersonalCycle 結構體定義在 HomeModels.swift 中
