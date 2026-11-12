import SwiftUI

struct GuideDetailView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "book.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("心理健康指南")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                    
                    VStack(spacing: 16) {
                        GuideCard(
                            title: "認識憂鬱症",
                            description: "了解憂鬱症的症狀、成因與治療方式",
                            icon: "heart.circle"
                        )
                        
                        GuideCard(
                            title: "焦慮症指南",
                            description: "學習識別和管理焦慮症狀",
                            icon: "brain.head.profile"
                        )
                        
                        GuideCard(
                            title: "壓力管理",
                            description: "有效的壓力調節技巧和方法",
                            icon: "leaf.circle"
                        )
                        
                        GuideCard(
                            title: "睡眠健康",
                            description: "改善睡眠品質的實用建議",
                            icon: "moon.circle"
                        )
                        
                        GuideCard(
                            title: "人際關係",
                            description: "建立健康的人際互動模式",
                            icon: "person.2.circle"
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📚 使用說明")
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• 本指南提供基礎心理健康知識")
                            Text("• 內容僅供參考，不能替代專業醫療建議")
                            Text("• 如有嚴重症狀，請尋求專業協助")
                            Text("• 定期閱讀有助於提升心理健康意識")
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
            .navigationTitle("心理健康指南")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("關閉") { isPresented = false })
        }
    }
}

struct GuideCard: View {
    let title: String
    let description: String
    let icon: String
    
    var body: some View {
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
            
            Button(action: {
                // 這裡可以導航到具體的指南頁面
            }) {
                Text("查看")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(AppColors.darkBrown)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2)
    }
}

#Preview {
    GuideDetailView(isPresented: .constant(true))
}
