import SwiftUI

struct TechniquesDetailView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("情緒管理小技巧")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                    
                    VStack(spacing: 16) {
                        TechniqueCard(
                            title: "深呼吸練習",
                            description: "先觀察自己的呼吸，再慢慢把吐氣拉長",
                            steps: [
                                "先感受自己吸氣、吐氣的比例",
                                "嘗試把呼吸的比例調整成 1：1",
                                "接著再慢慢試著把吸氣、吐氣的比例約為 1：2",
                                "例如吸氣 4 秒，吐氣 6～8 秒",
                                "持續練習 5 分鐘"
                            ],
                            icon: "lungs.fill"
                        )
                        
                        TechniqueCard(
                            title: "正念冥想",
                            description: "專注當下，觀察思緒和感受",
                            steps: ["找安靜環境", "閉眼專注呼吸", "觀察念頭飄過", "持續5-10分鐘"],
                            icon: "brain.head.profile"
                        )
                        
                        TechniqueCard(
                            title: "肌肉放鬆",
                            description: "漸進式肌肉放鬆技巧",
                            steps: ["繃緊肌肉5秒", "突然放鬆", "感受對比", "從腳到頭依序進行"],
                            icon: "figure.flexibility"
                        )
                        
                        TechniqueCard(
                            title: "情緒日記",
                            description: "記錄和分析情緒變化",
                            steps: ["記錄觸發事件", "描述情緒感受", "分析思維模式", "尋找應對方式"],
                            icon: "book.fill"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("💡 使用建議")
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 選擇適合自己的技巧定期練習")
                            Text("• 在情緒平穩時先學習技巧")
                            Text("• 持續練習才能見到效果")
                            Text("• 結合多種技巧效果更佳")
                        }
                        .font(.body)
                        .foregroundColor(AppColors.titleColor)
                    }
                    .padding()
                    .background(AppColors.cardBackground)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2)
                }
                .padding()
            }
            .background(AppColors.lightYellow)
            .navigationTitle("情緒管理小技巧")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("關閉") { isPresented = false })
        }
    }
}

struct TechniqueCard: View {
    let title: String
    let description: String
    let steps: [String]
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(AppColors.titleColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("步驟：")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.titleColor)
                
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 8) {
                        Text("\(index + 1).")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(AppColors.orange)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(step)
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor)
                    }
                }
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

#Preview {
    TechniquesDetailView(isPresented: .constant(true))
}
