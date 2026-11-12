import SwiftUI

struct PHQ9ResultView: View {
    let score: Int
    @Binding var isPresented: Bool
    @State private var showComfortSheet = false
    
    var depressionLevel: String {
        switch score {
        case 0...4: return "無明顯憂鬱"
        case 5...9: return "輕度憂鬱"
        case 10...14: return "中度憂鬱"
        case 15...19: return "中重度憂鬱"
        case 20...27: return "重度憂鬱"
        default: return "重度憂鬱"
        }
    }
    
    var recommendation: String {
        switch score {
        case 0...4: return "您的憂鬱症狀很少或沒有，請保持良好的心理健康習慣。"
        case 5...9: return "您有輕度憂鬱症狀，建議注意情緒變化，適度放鬆。"
        case 10...14: return "您有中度憂鬱症狀，建議尋求專業心理諮詢。"
        case 15...19: return "您有中重度憂鬱症狀，強烈建議尋求專業醫療協助。"
        default: return "您有重度憂鬱症狀，請立即尋求專業醫療協助。"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.titleColor)
            
            Text("PHQ-9 測試完成")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)
            
            VStack(spacing: 12) {
                Text("您的憂鬱指數")
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                
                Text("\(score)/27")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.orange)
                
                Text(depressionLevel)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.titleColor)
            }
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4)
            
            Text(recommendation)
                .font(.body)
                .foregroundColor(AppColors.titleColor)
                .multilineTextAlignment(.center)
                .padding()
                .background(AppColors.cardBackground)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 2)
            
            if score >= 10 {
                VStack(spacing: 8) {
                    Text("⚠️ 重要提醒")
                        .font(.headline)
                        .foregroundColor(.red)
                    Text("您的測試結果顯示有較明顯的憂鬱症狀，建議尋求專業協助。")
                        .font(.body)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: { isPresented = false }) {
                Text("完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.darkBrown)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.lightYellow)
        .navigationTitle("測試結果")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if score >= 10 {
                showComfortSheet = true
            }
        }
        .sheet(isPresented: $showComfortSheet) {
            ComfortSupportView {
                showComfortSheet = false
                isPresented = false
            }
        }
    }
}

private struct ComfortSupportView: View {
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("給自己一點溫柔")
                .font(.title3.weight(.bold))
                .foregroundColor(AppColors.titleColor)
            
            Text("分數偏高時，代表你最近承受了不少情緒壓力。先深呼吸，給自己一點空間，必要時請尋求專業協助。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button(action: onClose) {
                Text("收到，回到頁面")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.darkBrown)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(AppColors.lightYellow)
        .presentationDetents([.fraction(0.75)])
    }
}

#Preview {
    PHQ9ResultView(score: 12, isPresented: .constant(true))
}
