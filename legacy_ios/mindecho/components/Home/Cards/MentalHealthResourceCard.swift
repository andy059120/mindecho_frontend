import SwiftUI

// MARK: - 心理健康資源卡片
struct MentalHealthResourceCard: View {
    let resource: MentalHealthResource
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: resource.icon)
                    .font(.title2)
                    .foregroundColor(AppColors.darkBrown)
                Spacer()
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .multilineTextAlignment(.leading)
                
                Text(resource.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.darkBrown.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                Button(action: onTap) {
                    Text(resource.buttonText)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.darkBrown)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .frame(width: 160, height: 140)
        .background(
            LinearGradient(
                colors: [
                    AppColors.resourceCardYellow.opacity(0.6),
                    AppColors.resourceCardOrange.opacity(0.6),
                    AppColors.orange.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
    }
}

// MARK: - 心理測驗卡片
struct PsychologicalTestCard: View {
    let test: PsychologicalTest
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: test.icon)
                    .font(.title2)
                    .foregroundColor(AppColors.darkBrown)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(test.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.darkBrown)
                    .multilineTextAlignment(.leading)
                
                Text(test.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(AppColors.darkBrown.opacity(0.7))
                    .multilineTextAlignment(.leading)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.darkBrown.opacity(0.6))
                            
                            Text(test.duration)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppColors.darkBrown)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 8))
                                .foregroundColor(AppColors.darkBrown.opacity(0.6))
                            
                            Text(test.questions)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppColors.darkBrown)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 2)
                
                Button(action: onTap) {
                    Text("開始測驗")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(AppColors.orange)
                        .cornerRadius(8)
                }
                .padding(.top, 6)
            }
        }
        .padding(16)
        .frame(width: 160, height: 180)
        .background(
            LinearGradient(
                colors: [
                    AppColors.testCardLightYellow,
                    AppColors.testCardYellow,
                    AppColors.testCardYellow.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
    }
}

#Preview {
    // 建立一個示範的心理資源項目
    let sampleResource = MentalHealthResource(
        title: "心理支持專線",
        subtitle: "提供 24 小時心理諮詢服務",
        icon: "phone.fill",
        buttonText: "撥打電話",
        action: .hotline
    )
    
    // 顯示單一卡片
    MentalHealthResourceCard(
        resource: sampleResource,
        onTap: {
            print("使用者點擊了『撥打電話』按鈕")
        }
    )
    .previewLayout(.sizeThatFits)
    .padding()
    .background(Color.yellow.opacity(0.1))
}
