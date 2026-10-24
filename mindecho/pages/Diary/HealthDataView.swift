//
//  HealthDataView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//

import SwiftUI

struct HealthDataView: View {
    @StateObject private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                
                // 📊 數據總覽
                VStack(alignment: .leading, spacing: 6) {
                    Text("數據概覽")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.primary)
                    Text("追蹤你的身體節奏與日常狀態")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 四個數據卡片（兩行 Grid）
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    HealthDataCard(
                        title: "心率變異性 (HRV)",
                        subtitle: "心臟健康指標",
                        value: formatValue(healthKitManager.hrvMs, decimals: 0),
                        unit: healthKitManager.hrvMs == nil ? "" : "ms",
                        color: .orange,
                        icon: "waveform.path.ecg"
                    )
                    
                    HealthDataCard(
                        title: "睡眠質量",
                        subtitle: "深度睡眠時間",
                        value: formatValue(healthKitManager.sleepHours, decimals: 1),
                        unit: healthKitManager.sleepHours == nil ? "" : "小時",
                        color: .brown,
                        icon: "bed.double.fill"
                    )
                    
                    HealthDataCard(
                        title: "活動量",
                        subtitle: "每日步數",
                        value: formatValue(healthKitManager.steps, decimals: 0),
                        unit: healthKitManager.steps == nil ? "" : "步",
                        color: .teal,
                        icon: "figure.walk"
                    )
                    
                    HealthDataCard(
                        title: "體重",
                        subtitle: "體重變化趨勢",
                        value: formatValue(healthKitManager.weightKg, decimals: 1),
                        unit: healthKitManager.weightKg == nil ? "" : "公斤",
                        color: .blue,
                        icon: "scalemass"
                    )
                }
                .padding(.horizontal)

                if !hasMetrics {
                    Text("尚未連接apple運動")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 6)
                }
                
                // 💡 健康建議
                VStack(alignment: .leading, spacing: 14) {
                    Text("健康建議")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if !hasMetrics {
                        Text("無數據")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(staticAdviceItems) { item in
                            suggestionRow(
                                icon: item.icon,
                                iconColor: item.iconColor,
                                title: item.title,
                                detail: item.detail
                            )
                        }
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
                )
                .padding(.horizontal)
                
                Spacer(minLength: 20)
            }
            .padding(.top)
        }
        .background(AppColors.lightYellow)
        .onAppear {
            healthKitManager.refresh()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Text("健康追蹤")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(AppColors.titleColor)
                    .padding(.leading, 2)
            }
        }
    }
    
    private func formatValue(_ value: Double?, decimals: Int) -> String {
        guard let value else { return "無資料" }
        return String(format: "%.\(decimals)f", value)
    }

    private var hasMetrics: Bool {
        healthKitManager.hrvMs != nil ||
        (healthKitManager.sleepHours ?? 0) > 0 ||
        healthKitManager.steps != nil ||
        healthKitManager.weightKg != nil
    }
    
    private struct StaticAdviceItem: Identifiable {
        let id = UUID()
        let icon: String
        let iconColor: Color
        let title: String
        let detail: String
    }
    
    private var staticAdviceItems: [StaticAdviceItem] {
        var items: [StaticAdviceItem] = []
        
        if let hrv = healthKitManager.hrvMs, hrv < 35 {
            items.append(
                StaticAdviceItem(
                    icon: "bolt.fill",
                    iconColor: .yellow,
                    title: "提高 HRV",
                    detail: "HRV 偏低時，建議每天 10 分鐘深呼吸或冥想，幫助降低壓力。"
                )
            )
        }
        
        if let sleep = healthKitManager.sleepHours, sleep < 6 {
            items.append(
                StaticAdviceItem(
                    icon: "moon.fill",
                    iconColor: .purple,
                    title: "改善睡眠質量",
                    detail: "睡眠不足時，睡前一小時避免藍光，保持臥室 18–20°C。"
                )
            )
        }
        
        if let steps = healthKitManager.steps, steps < 5000 {
            items.append(
                StaticAdviceItem(
                    icon: "figure.walk",
                    iconColor: .teal,
                    title: "增加活動量",
                    detail: "今日活動量偏少，建議分段散步或拉伸，讓身體動起來。"
                )
            )
        }
        
        if let weight = healthKitManager.weightKg, weight > 0 {
            items.append(
                StaticAdviceItem(
                    icon: "scalemass",
                    iconColor: .blue,
                    title: "體重維持",
                    detail: "維持規律飲食與穩定運動，有助於長期體重管理。"
                )
            )
        }
        
        if items.isEmpty {
            items.append(
                StaticAdviceItem(
                    icon: "sparkles",
                    iconColor: .green,
                    title: "狀態良好",
                    detail: "目前指標落在穩定區間，持續保持規律作息與活動。"
                )
            )
        }
        
        return items
    }
    
    @ViewBuilder
    private func suggestionRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 15, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - 單一卡片元件
struct HealthDataCard: View {
    let title: String
    let subtitle: String
    let value: String
    let unit: String
    let color: Color
    let icon: String
    
    var body: some View {
        let gradient = LinearGradient(
            colors: [
                color.opacity(0.18),
                color.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 15, weight: .semibold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 4)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Decorative progress bar
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.12))
                    .frame(height: 10)
                Capsule()
                    .fill(gradient)
                    .frame(width: 110, height: 10)
            }
            .padding(.top, 2)
        }
        .padding(12)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
                .shadow(color: color.opacity(0.12), radius: 14, y: 10)
        )
    }
}


#Preview {
    HealthDataView()
}
