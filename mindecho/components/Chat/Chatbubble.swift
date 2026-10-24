import SwiftUI
import UIKit

// MARK: - 聊天氣泡
struct ChatBubbleView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(Font.subheadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(AppColors.userBubbleColor)
                        .cornerRadius(20, corners: [.topLeft, .topRight, .bottomLeft])
                        .contextMenu {
                            Button("複製") {
                                UIPasteboard.general.string = message.content
                            }
                        }
                    
                    Text(formatTime(message.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    // AI 模式圖標
                    ZStack {
                        Circle()
                            .fill(message.mode.color.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(message.mode.shortName)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(message.mode.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(message.content)
                            .font(.subheadline)
                            .foregroundColor(AppColors.bubbleTextColor)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(AppColors.aiBubbleColor)
                            .cornerRadius(20, corners: [.topLeft, .topRight, .bottomRight])
                        
                        Text(formatTime(message.timestamp))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.leading, 4)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack(spacing: 20) {
        ChatBubbleView(message: ChatMessage(
            content: "這是一條測試訊息",
            isFromUser: true,
            mode: .chatMode
        ))
        
        ChatBubbleView(message: ChatMessage(
            content: "這是AI的回覆訊息，內容比較長一些，用來測試氣泡的顯示效果。",
            isFromUser: false,
            mode: .cbtMode
        ))
    }
    .padding()
    .background(AppColors.chatBackground)
}
