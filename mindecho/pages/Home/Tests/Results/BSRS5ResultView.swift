import SwiftUI

struct BSRS5ResultView: View {
    let score: Int
    @Binding var isPresented: Bool
    @State private var showComfortSheet = false
    
    var stressLevel: String {
        switch score {
        case 0...5: return "身心適應狀況良好"
        case 6...9: return "輕度情緒困擾"
        case 10...14: return "中度情緒困擾"
        case 15...20: return "重度情緒困擾"
        default: return "重度情緒困擾"
        }
    }
    
    var recommendation: String {
        switch score {
        case 0...5: return "您的身心適應狀況良好，請繼續保持。"
        case 6...9: return "您有輕度情緒困擾，建議適度休息與放鬆。"
        case 10...14: return "您有中度情緒困擾，建議尋求專業諮詢。"
        case 15...20: return "您有重度情緒困擾，強烈建議尋求專業協助。"
        default: return "請尋求專業協助。"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 60))
                .foregroundColor(AppColors.titleColor)
            
            Text("BSRS-5 測試完成")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)
            
            VStack(spacing: 12) {
                Text("您的心理症狀指數")
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                
                Text("\(score)/20")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(AppColors.orange)
                
                Text(stressLevel)
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
                    Text("您的測試結果顯示有較明顯的情緒困擾，建議尋求專業協助。")
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
            
            Text("分數偏高時，代表你近期可能感到吃力或情緒低落。先停下腳步，提醒自己被愛與被需要，也可以尋求專業協助。")
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
    BSRS5ResultView(score: 7, isPresented: .constant(true))
}
