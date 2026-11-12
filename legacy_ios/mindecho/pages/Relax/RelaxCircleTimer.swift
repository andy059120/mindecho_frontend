//
//  RelaxCircleTimer.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/10/21.
//

import SwiftUI

struct RelaxCircleTimer: View {
    @ObservedObject var viewModel: RelaxTimerViewModel
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.chatModeColor.opacity(0.25),
                            AppColors.chatModeColor.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 160)
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
            
            VStack(spacing: 10) {
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(AppColors.titleColor)
                Text("請選擇上方模式，從下方清單播放影片")
                    .font(.subheadline)
                    .foregroundColor(AppColors.titleColor)
                Text("呼吸 / 冥想影片會在 YouTube 開啟")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    RelaxCircleTimer(viewModel: RelaxTimerViewModel())
}
