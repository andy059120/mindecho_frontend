import SwiftUI

struct GAD7ResultView: View {
    let score: Int
    @Binding var isPresented: Bool
    @State private var showComfortSheet = false
    
    var anxietyLevel: String {
        switch score {
        case 0...4: return "輕微焦慮"
        case 5...9: return "輕度焦慮"
        case 10...14: return "中度焦慮"
        case 15...21: return "重度焦慮"
        default: return "重度焦慮"
        }
    }
    
    var recommendation: String {
        switch score {
        case 0...4: return "您的焦慮程度很低，請保持良好的生活習慣。"
        case 5...9: return "您有輕度焦慮，建議學習放鬆技巧和壓力管理。"
        case 10...14: return "您有中度焦慮，建議尋求專業心理諮詢。"
        case 15...21: return "您有重度焦慮，強烈建議尋求專業醫療協助。"
        default: return "請尋求專業醫療協助。"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(AppColors.titleColor)
            
            Text("GAD-7 測試完成")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)
            
            VStack(spacing: 12) {
                Text("您的焦慮指數")
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                
                Text("\(score)/21")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.orange)
                
                Text(anxietyLevel)
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
                    Text("您的測試結果顯示可能有較嚴重的焦慮症狀，建議尋求專業醫療協助。")
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
            
            Text("分數偏高時，代表你近期焦慮感較強。先停下來深呼吸，提醒自己並不孤單，必要時尋求專業協助。")
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

private struct SupportReasonQuick: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

#Preview {
    GAD7ResultView(score: 8, isPresented: .constant(true))
}
