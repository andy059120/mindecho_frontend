//
//  DiaryMainView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//
import SwiftUI

struct DiaryMainView: View {
    @State private var selectedTab = 0 // 預設顯示「五項指標追蹤」
    @State private var selectedTimePeriod = "本週"
    @StateObject private var scaleSessionManager = ScaleSessionManager.shared
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 頁面標題
            VStack(spacing: 4) {
                Text("追蹤")
                    .font(.title2.bold())
                    .foregroundColor(AppColors.titleColor)
                Text("查看你的健康數據與情緒變化")
                    .font(.subheadline)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))
            }
            .padding(.top)
            
            // 上方 Segmented Control
            Picker("選項", selection: $selectedTab) {
                Text("心情日記").tag(1)
                Text("量表追蹤").tag(2)
                Text("五項指標追蹤").tag(0)
            }
            .pickerStyle(SegmentedPickerStyle())
            .tint(AppColors.titleColor)
            .foregroundColor(AppColors.titleColor)
            .padding()
            
            // 對應的子頁面
            TabView(selection: $selectedTab) {
                NavigationView {
                    ScrollView {
                        VStack {
                            WeeklyStatusOverviewCard()
                                .padding(.horizontal, 16)
                                .padding(.top, 8)

                            FiveIndicatorsCard(selectedTimePeriod: $selectedTimePeriod)
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            DailyScoresTableCard(
                                scores: checkInManager.weeklyScores
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            
                            Spacer(minLength: 20)
                        }
                    }
                    .background(AppColors.lightYellow)
                }
                .tag(0)
                NavigationView { MoodDiaryView() }.tag(1)
                NavigationView {
                    ScrollView {
                        ScaleTrackingCard(manager: scaleSessionManager)
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                        Spacer(minLength: 20)
                    }
                    .background(AppColors.lightYellow)
                }
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .indexViewStyle(.page(backgroundDisplayMode: .never))
            .onChange(of: selectedTab) { _, value in
                if value == 2 {
                    scaleSessionManager.loadSessions()
                }
            }
        }
        .background(AppColors.lightYellow)
        .onAppear {
            scaleSessionManager.loadSessions()
            checkInManager.loadDataFromAPI()
        }
    }
}

#Preview {
    DiaryMainView()
}

private struct WeeklyStatusOverviewCard: View {
    @ObservedObject private var checkInManager = DailyCheckInManager.shared

    private struct IndicatorTile: Identifiable {
        let id = UUID()
        let type: HealthIndicatorType
        let title: String
        let emoji: String
    }

    private let tiles: [IndicatorTile] = [
        IndicatorTile(type: .physical, title: "生理", emoji: "💪"),
        IndicatorTile(type: .emotional, title: "心情", emoji: "🙂"),
        IndicatorTile(type: .sleep, title: "睡眠", emoji: "😴"),
        IndicatorTile(type: .mental, title: "精神", emoji: "⚡"),
        IndicatorTile(type: .appetite, title: "食慾", emoji: "🍽")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("本週整體狀態")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(AppColors.titleColor)

            HStack(spacing: 8) {
                ForEach(tiles) { tile in
                    let todayValue = todayScore(for: tile.type)
                    let weeklyAverage = weeklyAverage(for: tile.type)
                    let label = statusLabel(for: weeklyAverage)

                    VStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Text(tile.title)
                                .font(.caption)
                                .foregroundColor(AppColors.titleColor)
                            Text(tile.emoji)
                                .font(.caption)
                        }

                        Text(String(format: "%.1f", weeklyAverage))
                            .font(.title3.weight(.bold))
                            .foregroundColor(AppColors.titleColor)

                        Text(label)
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))

                        if let todayValue {
                            Text("今日 \(todayValue)")
                                .font(.caption2)
                                .foregroundColor(AppColors.titleColor.opacity(0.6))
                        } else {
                            Text("今日 -")
                                .font(.caption2)
                                .foregroundColor(AppColors.titleColor.opacity(0.4))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppColors.lightBrown.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: HomeConstants.Charts.cardCornerRadius)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.08), radius: HomeConstants.Charts.cardShadowRadius)
        )
    }

    private func todayScore(for type: HealthIndicatorType) -> Int? {
        guard let today = checkInManager.todayScores else { return nil }
        switch type {
        case .physical: return today.physical
        case .mental: return today.mental
        case .emotional: return today.emotional
        case .sleep: return today.sleep
        case .appetite: return today.appetite
        case .overall: return nil
        }
    }

    private func weeklyAverage(for type: HealthIndicatorType) -> Double {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -6, to: Date()) ?? Date()
        let weeklyScores = checkInManager.weeklyScores.filter { $0.date >= startDate }
        guard !weeklyScores.isEmpty else { return 0 }

        let values: [Int] = weeklyScores.map { score in
            switch type {
            case .physical: return score.physical
            case .mental: return score.mental
            case .emotional: return score.emotional
            case .sleep: return score.sleep
            case .appetite: return score.appetite
            case .overall: return 0
            }
        }
        let total = values.reduce(0, +)
        return Double(total) / Double(values.count)
    }

    private func statusLabel(for value: Double) -> String {
        switch value {
        case 0..<2.5: return "不好"
        case 2.5..<3.5: return "一般"
        default: return "良好"
        }
    }
}
