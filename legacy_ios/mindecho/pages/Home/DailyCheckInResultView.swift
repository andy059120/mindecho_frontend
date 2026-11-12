import SwiftUI

struct DailyCheckInResultView: View {
    let scores: DailyCheckInScores
    @Binding var isPresented: Bool
    
    private var overallScore: Int {
        scores.overall
    }
    
    private var healthStatus: String {
        switch overallScore {
        case 5: return "極佳狀態"
        case 4: return "良好狀態"
        case 3: return "一般狀態"
        case 2: return "需要關注"
        default: return "需要調整"
        }
    }
    
    private var statusColor: Color {
        switch overallScore {
        case 4...5: return .green
        case 3: return AppColors.orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 標題
            VStack(spacing: 8) {
                Text("今日檢測完成！")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                
                Text("已記錄到您的健康檔案")
                    .font(.subheadline)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))
            }
            .padding(.top, 32)
            
            Spacer()
            
            // 結果卡片
            VStack(spacing: 24) {
                // 今日健康指數區塊
                VStack(spacing: 16) {
                    Text("今日健康指數")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.titleColor)
                    
                    VStack(spacing: 8) {
                        ForEach(getHealthIndicators(), id: \.name) { indicator in
                            HealthIndicatorRow(
                                name: indicator.name,
                                score: indicator.score
                            )
                        }
                    }
                }
                .padding(20)
                .background(AppColors.lightYellow)
                .cornerRadius(12)
                
                // 綜合健康指數
                VStack(spacing: 12) {
                    Text("綜合健康指數")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.titleColor)
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(overallScore) / 5)
                            .stroke(statusColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.0), value: overallScore)
                        
                        VStack(spacing: 4) {
                            Text("\(overallScore)")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(AppColors.titleColor)
                            
                            Text(healthStatus)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(statusColor)
                        }
                    }
                }
                .padding(.vertical, 16)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 24)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // 進入首頁按鈕
            Button(action: {
                isPresented = false
            }) {
                Text("進入首頁")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColors.orange)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .background(AppColors.lightYellow)
        .navigationBarHidden(true)
      
    }
    
    private func getHealthIndicators() -> [HealthIndicator] {
        return [
            HealthIndicator(name: "生理健康", score: scores.physical),
            HealthIndicator(name: "精神狀態", score: scores.mental),
            HealthIndicator(name: "情緒狀態", score: scores.emotional),
            HealthIndicator(name: "睡眠品質", score: scores.sleep),
            HealthIndicator(name: "飲食表現", score: scores.appetite)
        ]
    }
}

// MARK: - 健康指標行
struct HealthIndicatorRow: View {
    let name: String
    let score: Int
    
    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .foregroundColor(AppColors.titleColor)
            
            Spacer()
            
            Text("\(score)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.orange)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    DailyCheckInResultView(
        scores: DailyCheckInScores(
            physical: 80,
            mental: 80,
            emotional: 80,
            sleep: 80,
            appetite: 80,
            date: Date()
        ),
        isPresented: .constant(true)
    )
}
