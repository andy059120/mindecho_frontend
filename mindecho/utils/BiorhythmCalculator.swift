import Foundation

// MARK: - 生理節律計算器
struct BiorhythmCalculator {
    
    // MARK: - 標準生理節律計算
    static func calculateStandardBiorhythm(birthDate: Date, currentDate: Date = Date()) -> BiorhythmData {
        let daysSinceBirth = daysBetween(from: birthDate, to: currentDate)
        
        // 使用標準公式計算
        let physical = 100.0 * sin(2 * .pi * Double(daysSinceBirth) / Double(HomeConstants.Biorhythm.physicalCycle))
        let emotional = 100.0 * sin(2 * .pi * Double(daysSinceBirth) / Double(HomeConstants.Biorhythm.emotionalCycle))
        let intellectual = 100.0 * sin(2 * .pi * Double(daysSinceBirth) / Double(HomeConstants.Biorhythm.intellectualCycle))
        
        return BiorhythmData(
            physical: physical,
            emotional: emotional,
            intellectual: intellectual,
            sleep: nil,
            appetite: nil,
            mode: .standard
        )
    }
    
    // MARK: - 個人生理節律計算
    static func calculatePersonalBiorhythm(weeklyScores: [DailyCheckInScores], currentDate: Date = Date()) -> BiorhythmData? {
        guard weeklyScores.count >= HomeConstants.Biorhythm.minimumDataDays else {
            return nil
        }
        
        // 按日期排序，最新的在前
        let sortedScores = weeklyScores.sorted { $0.date > $1.date }
        
        // 計算最近30天的平均值和趨勢
        let recentScores = Array(sortedScores.prefix(30))
        
        let physical = calculatePersonalCycle(data: recentScores.map { Double($0.physical) })
        let emotional = calculatePersonalCycle(data: recentScores.map { Double($0.emotional) })
        let intellectual = calculatePersonalCycle(data: recentScores.map { Double($0.mental) })
        let sleep = calculatePersonalCycle(data: recentScores.map { Double($0.sleep) })
        let appetite = calculatePersonalCycle(data: recentScores.map { Double($0.appetite) })
        
        return BiorhythmData(
            physical: physical,
            emotional: emotional,
            intellectual: intellectual,
            sleep: sleep,
            appetite: appetite,
            mode: .personal
        )
    }
    
    // MARK: - 個人週期計算
    private static func calculatePersonalCycle(data: [Double]) -> Double {
        guard !data.isEmpty else { return 0 }
        
        // 計算當前趨勢（最近7天 vs 前7天的平均值）
        let recentData = Array(data.prefix(7))
        let previousData = data.count > 7 ? Array(data[7..<min(14, data.count)]) : []
        
        let recentAverage = recentData.reduce(0, +) / Double(recentData.count)
        let previousAverage = previousData.isEmpty ? recentAverage : previousData.reduce(0, +) / Double(previousData.count)
        
        // 將 1-5 的範圍轉換為 -100 到 100 的生理節律範圍
        let normalizedCurrent = (recentAverage - 3) * 50
        let trend = recentAverage - previousAverage
        
        // 加入趨勢影響，讓數值更動態
        return max(-100, min(100, normalizedCurrent + trend * 10))
    }
    
    // MARK: - 輔助方法
    
    /// 計算兩個日期之間的天數
    static func daysBetween(from startDate: Date, to endDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: startDate, to: endDate)
        return components.day ?? 0
    }
    
    /// 獲取當前日期在年度中的角度位置
    static func getCurrentYearAngle(date: Date = Date()) -> Double {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        let totalDaysInYear = isLeapYear(year) ? 366 : 365
        return 360.0 / Double(totalDaysInYear) * Double(dayOfYear - 1)
    }
    
    /// 檢查是否為閏年
    static func isLeapYear(_ year: Int) -> Bool {
        return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }
    
    /// 根據數值獲取生理節律狀態
    static func getBiorhythmState(value: Double) -> BiorhythmState {
        switch value {
        case 20...100:
            return .high
        case -20...20:
            return .critical
        default:
            return .low
        }
    }
    
    /// 獲取指定指標在特定日期的角度
    static func getIndicatorAngle(indicator: BiorhythmIndicator, birthDate: Date, currentDate: Date = Date()) -> Double {
        let daysSinceBirth = daysBetween(from: birthDate, to: currentDate)
        let cycle = Double(indicator.standardCycle)
        
        // 計算在週期中的位置 (0-1)
        let cyclePosition = (Double(daysSinceBirth).truncatingRemainder(dividingBy: cycle)) / cycle
        
        // 轉換為角度 (0-360度)
        return cyclePosition * 360.0
    }
    
    /// 為個人模式計算指標角度
    static func getPersonalIndicatorAngle(value: Double) -> Double {
        // 將 -100 到 100 的範圍映射到 0-360 度
        let normalizedValue = (value + 100) / 200.0  // 轉換為 0-1
        return normalizedValue * 360.0
    }
    
    static func getBiorhythmDescription(indicator: BiorhythmIndicator, value: Double) -> String {
        let state = getBiorhythmState(value: value)
        let percentage = Int((value + 100) / 2)  // 轉換為 0-100 的百分比

        switch indicator {

        // MARK: - Physical
        case .physical:
            switch state {
            case .high:
                return """
                你的身體節律處於高峰期，通常代表精力充沛、體力耐力良好，是進行運動、旅行或高需求活動的良機。這是一段自然的上升期，身體代謝與神經肌肉反應較佳。

                不過，若近期睡眠不足或承受壓力，這種高峰體驗也可能被打折。建議把握狀態好時完成重要任務，也別忽略休息，避免過度消耗。
                """
            case .critical:
                return """
                目前你的身體節律接近臨界點，意味著體力狀態正在轉換。你可能感覺正常、但對外在刺激反應略慢，或稍有疲憊感。

                這段過渡期容易受飲食、活動量、壓力等因素影響體感落差，建議你保留彈性安排，避免身體長時間高負荷運作。
                """
            case .low:
                return """
                你的體力節律目前處於週期低點。這段期間可能感覺疲倦、動力不足，是身體自然調節修復的時期。

                不代表有健康問題，而是節律週期使然。建議你透過多補眠、均衡飲食與減少激烈活動，協助身體恢復。
                """
            }

        // MARK: - Emotional
        case .emotional:
            switch state {
            case .high:
                return """
                你的情緒節律處於高峰期，心情通常較為愉悅、情緒穩定，並且更有餘裕應對人際互動與情感表達。

                這是一段適合社交、創作與表達情緒的時機。不過，若近期經歷壓力或內在衝突，可能仍會有反覆波動。
                """
            case .critical:
                return """
                情緒節律正處於波動轉換點，可能會經歷內在衝突、思緒雜亂或突然的情緒波動。這是一段較容易受外界影響的時間。

                建議你留心自身情緒起伏，透過寫日記、散步或靜心活動幫助梳理感受，並避免做出重大決定。
                """
            case .low:
                return """
                目前情緒節律處於低點，可能會感到焦躁、低落或易怒。這是自然的情緒低谷，並非心理異常。

                建議你給自己更多休息與獨處空間，可透過音樂、冥想或運動協助情緒釋放與調節。
                """
            }

        // MARK: - Intellectual
        case .intellectual:
            switch state {
            case .high:
                return """
                智力節律處於高峰期，表示你的思考速度、記憶力與解題能力相對較佳。這是進行學習、創新或分析工作的理想時機。

                把握這段清晰高效的時期完成高專注任務。不過，仍要注意資訊過載與腦疲勞的風險，建議適度安排休息。
                """
            case .critical:
                return """
                智力節律接近轉換點，可能出現注意力短暫分散或思考反應變慢。這是週期中較難保持穩定專注的階段。

                建議你優先處理較熟悉的任務，並適當運用結構化工具（如清單、番茄鐘）輔助認知表現。
                """
            case .low:
                return """
                智力節律處於低點，代表你的思考效率可能較低，學習與記憶負擔感上升。

                可安排例行性、重複性任務，減少創造性壓力，同時保持適度刺激（如閱讀或輕鬆學習）以維持認知彈性。
                """
            }

        // MARK: - Sleep
        case .sleep:
            switch state {
            case .high:
                return """
                睡眠節律良好，代表近期可能獲得充足且高品質的睡眠，身體恢復狀況佳，精神相對飽滿。

                建議持續維持良好作息與睡前習慣（如減少藍光、避免重食），鞏固這段優勢期。
                """
            case .critical:
                return """
                睡眠節律處於轉換點，可能出現入睡困難、淺眠或作息不穩等情況。這是身體調整內部節奏的表現。

                建議減少刺激性飲品，睡前遠離螢幕與焦慮資訊，建立穩定的入睡儀式。
                """
            case .low:
                return """
                睡眠節律偏低，可能出現睡眠中斷、早醒或睡不飽的主觀感。此階段易受生活壓力、飲食、情緒等影響放大失眠感。

                建議優先調整作息，減少午後咖啡因攝取，並嘗試冥想或放鬆練習以提升入睡品質。
                """
            }

        // MARK: - Appetite
        case .appetite:
            switch state {
            case .high:
                return """
                食慾節律處於活躍期，可能感覺胃口大增、消化快速，這是代謝相對旺盛的時期。

                建議均衡飲食、避免暴飲暴食，並搭配運動使能量轉化為肌肉或活力，而非轉化為囤積。
                """
            case .critical:
                return """
                食慾節律正處於波動期，可能會出現忽餓忽飽、難以控制進食節奏的狀況。

                建議進行定時定量的飲食安排，避免因節律不穩造成攝取過多或過少的極端反應。
                """
            case .low:
                return """
                食慾節律偏低，可能感到胃口不佳、對食物興趣降低，這是內部調節過程的一部分。

                建議選擇清爽易消化的食物，適量補充蛋白質與水分，避免強迫進食或過度節食，尊重身體的節奏。
                """
            }
        }
    }

}
