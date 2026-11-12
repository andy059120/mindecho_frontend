import SwiftUI

// MARK: - 治療模式選擇卡片
struct TherapyModeSelectionCard: View {
    let mode: TherapyMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 模式圖標
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(mode.shortName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(mode.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(mode.color)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? mode.color : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 模式切換確認視圖
struct ModeChangeConfirmationView: View {
    let currentMode: TherapyMode
    let targetMode: TherapyMode
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath.circle")
                    .font(.system(size: 48))
                    .foregroundColor(targetMode.color)
                
                Text("切換對話模式")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                
                Text("您想要從 \(currentMode.displayName) 切換到 \(targetMode.displayName) 嗎？")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    // 當前模式
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(currentMode.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Text(currentMode.shortName)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(currentMode.color)
                        }
                        
                        Text(currentMode.displayName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Image(systemName: "arrow.right")
                        .font(.title3)
                        .foregroundColor(.gray)
                    
                    // 目標模式
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(targetMode.color.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Text(targetMode.shortName)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(targetMode.color)
                        }
                        
                        Text(targetMode.displayName)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(targetMode.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            HStack(spacing: 12) {
                Button("取消", action: onCancel)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                Button("確認切換", action: onConfirm)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(targetMode.color)
                    .cornerRadius(8)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 10)
    }
}

// MARK: - 治療模式選擇器（用於 Header）
struct TherapyModeSelector: View {
    @Binding var selectedMode: TherapyMode
    let onModeChange: (TherapyMode) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(TherapyMode.selectableCases, id: \.self) { mode in
                Button(action: {
                    if selectedMode != mode {
                        onModeChange(mode)
                    }
                }) {
                    Text(mode.shortName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedMode == mode ? .white : mode.color)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedMode == mode ? mode.color : Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(mode.color, lineWidth: 1)
                                )
                        )
                }
                .scaleEffect(selectedMode == mode ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: selectedMode)
            }
        }
    }
}

// MARK: - 模式簡介視圖
struct ModeIntroductionView: View {
    let mode: TherapyMode
    
    var features: [String] {
        switch mode {
        case .chatMode:
            return [
                "輕鬆自然的對話方式",
                "適合日常心情分享",
                "友善溫暖的交流氛圍"
            ]
        case .cbtMode:
            return [
                "識別負面思維模式",
                "挑戰不合理的想法",
                "建立積極的認知習慣"
            ]
        case .dbtMode:
            return [
                "先穩定強烈情緒與衝動",
                "練習在壓力下撐過當下",
                "整理需求與界線，改善互動"
            ]
        case .mbtMode:
            return [
                "增強情感覺察能力",
                "改善人際關係理解",
                "提升心智化水平"
            ]
        case .mbctMode:
            return [
                "觀察想法與情緒的起伏",
                "把想法當作事件來看",
                "必要時做簡短的呼吸安定"
            ]
        case .initial:
            return [
                "溫暖接住與建立安全感",
                "讓對話自然開始",
                "不做評估或制式提問"
            ]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(mode.shortName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(mode.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text(mode.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("特色功能：")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.titleColor)
                
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(mode.color)
                            .frame(width: 6, height: 6)
                        
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        TherapyModeSelectionCard(
            mode: .chatMode,
            isSelected: true,
            onSelect: {}
        )
        
        TherapyModeSelector(
            selectedMode: .constant(.cbtMode),
            onModeChange: { _ in }
        )
        
        ModeIntroductionView(mode: .mbtMode)
        
        ModeChangeConfirmationView(
            currentMode: .chatMode,
            targetMode: .cbtMode,
            onConfirm: {},
            onCancel: {}
        )
    }
    .padding()
    .background(AppColors.chatBackground)
}
