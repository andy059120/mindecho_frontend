import SwiftUI

struct EmotionBoxCard: View {
    let title: String
    let description: String
    let buttonTitle: String
    let color: Color
    let onButtonTap: () -> Void
    
    init(
        title: String,
        description: String,
        buttonTitle: String,
        color: Color,
        onButtonTap: @escaping () -> Void = {}
    ) {
        self.title = title
        self.description = description
        self.buttonTitle = buttonTitle
        self.color = color
        self.onButtonTap = onButtonTap
    }
    
    private var headerGradient: LinearGradient {
        LinearGradient(
            colors: [
                color.opacity(0.95),
                color.opacity(0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - 上半部（標題區）
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.18))
                    .frame(height: 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(headerGradient)
            
            // MARK: - 下半部（內容 + 按鈕）
            VStack(alignment: .leading, spacing: 10) {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.primary.opacity(0.8))
                    .multilineTextAlignment(.leading)
                    .lineSpacing(3)
                    .lineLimit(3)
                    .minimumScaleFactor(0.92)

                Spacer(minLength: 0)

                Button(action: onButtonTap) {
                    HStack {
                        Text(buttonTitle)
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.12))
                    .foregroundColor(color)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        Color.white,
                        Color.white.opacity(0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .frame(width: 170, height: 160)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                .shadow(color: color.opacity(0.15), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    EmotionBoxCard(
        title: "支撐我的片刻",
        description: "記下那些讓你有動力繼續向前行的理由。",
        buttonTitle: "查看我的理由",
        color: Color.orange.opacity(0.9)
    )
    .padding()
    .background(Color.yellow.opacity(0.1))
}
