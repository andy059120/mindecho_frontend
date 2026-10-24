import SwiftUI

// MARK: - PersonalBiorhythmCard.swift - 個人節律卡片組件
struct PersonalBiorhythmCard: View {
    let animationProgress: Double
    let onDetailTapped: () -> Void
    @StateObject private var rhythmManager = PersonalRhythmManager.shared
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }
    
    // 獲取個人週期長度，如果無法檢測則顯示"未檢測"
    private func getCycleDays(for indicator: HealthIndicatorType) -> String {
        if let cycle = rhythmManager.currentResult?.cycles.first(where: { $0.indicator == indicator }) {
            return "\(Int(cycle.period))天"
        }
        return "未檢測"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 標題
            HStack {
                Text("個人節律")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                
                Spacer()
            }
    
            
            // 週期資訊列表
            VStack(spacing: 0) {
                cycleInfoRow(indicator: .physical, title: "生理週期", color: AppColors.orange)
                Divider().background(Color.gray.opacity(0.3))
                
                cycleInfoRow(indicator: .mental, title: "智力週期", color: AppColors.mediumBrown)
                Divider().background(Color.gray.opacity(0.3))
                
                cycleInfoRow(indicator: .emotional, title: "情緒週期", color: AppColors.lightBrown)
                Divider().background(Color.gray.opacity(0.3))
                
                cycleInfoRow(indicator: .sleep, title: "睡眠週期", color: AppColors.testCardYellow)
                Divider().background(Color.gray.opacity(0.3))
                
                cycleInfoRow(indicator: .appetite, title: "食慾週期", color: AppColors.resourceCardOrange)
            }
            
            // 底部資訊
            HStack {
                Text("基於 \(rhythmManager.currentResult?.totalDataPoints ?? 0) 天記錄分析")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if rhythmManager.isCalculating {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
        .onAppear {
            rhythmManager.calculateRhythmsIfNeeded()
        }
    }
    
    // MARK: - 週期資訊行
    private func cycleInfoRow(indicator: HealthIndicatorType, title: String, color: Color) -> some View {
        HStack(spacing: 12) {
            // 指標色塊
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            // 指標名稱
            Text(title)
                .font(.system(size: 13, weight: .semibold))  // 改為與標準卡片一致
                .foregroundColor(AppColors.titleColor)
            
            Spacer()
            
            // 週期天數
            Text(getCycleDays(for: indicator))
                .font(.system(size: 12, weight: .semibold))  // 改為與標準卡片一致
                .foregroundColor(getCycleDays(for: indicator) == "未檢測" ? .gray : color)
                .padding(.horizontal, 8)  // 減少水平padding
                .padding(.vertical, 3)    // 減少垂直padding
                .background((getCycleDays(for: indicator) == "未檢測" ? Color.gray : color).opacity(0.1))
                .cornerRadius(10)         // 改為與標準卡片一致
        }
        .padding(.vertical, 12)
        .opacity(animationProgress)
        .animation(.easeInOut(duration: 0.6).delay(Double(getIndicatorIndex(indicator)) * 0.1), value: animationProgress)
    }
    
    // MARK: - 獲取指標索引（用於動畫延遲）
    private func getIndicatorIndex(_ indicator: HealthIndicatorType) -> Int {
        switch indicator {
        case .physical: return 0
        case .mental: return 1
        case .emotional: return 2
        case .sleep: return 3
        case .appetite: return 4
        case .overall: return 5
        }
    }
}

// MARK: - 預覽
struct PersonalBiorhythmCard_Previews: PreviewProvider {
    static var previews: some View {
        PersonalBiorhythmCard(
            animationProgress: 1.0,
            onDetailTapped: {}
        )
        .padding()
        .background(AppColors.lightYellow)
    }
}
