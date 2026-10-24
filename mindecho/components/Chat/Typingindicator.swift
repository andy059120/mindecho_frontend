import SwiftUI

// MARK: - 打字指示器
struct TypingIndicatorView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationOffset == CGFloat(index) ? 1.2 : 0.8)
                    .opacity(animationOffset == CGFloat(index) ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationOffset
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
        .onAppear {
            withAnimation {
                animationOffset = 2
            }
        }
    }
}

// MARK: - 帶模式圖標的打字指示器
struct TypingIndicatorWithModeView: View {
    let mode: TherapyMode
    
    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: 8) {
                // AI 模式圖標
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Text(mode.shortName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(mode.color)
                }
                
                TypingIndicatorView()
                
                Spacer()
            }
            
            Spacer()
        }
    }
}




#Preview {
    VStack(spacing: 20) {
        // 基本打字指示器
        TypingIndicatorView()
        
        // 帶模式圖標的打字指示器
        TypingIndicatorWithModeView(mode: .chatMode)
        TypingIndicatorWithModeView(mode: .cbtMode)
        TypingIndicatorWithModeView(mode: .mbtMode)
        
        // 在聊天界面中的使用示例
        VStack(spacing: 16) {
            HStack {
                Text("使用者訊息")
                    .padding()
                    .background(AppColors.userBubbleColor)
                    .foregroundColor(.white)
                    .cornerRadius(20)
                Spacer()
            }
            
            TypingIndicatorWithModeView(mode: .chatMode)
        }
        .padding(.horizontal, 16)
    }
    .padding()
    .background(AppColors.chatBackground)
}
