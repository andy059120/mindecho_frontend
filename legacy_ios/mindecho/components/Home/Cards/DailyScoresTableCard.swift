import SwiftUI

struct DailyScoresTableCard: View {
    let scores: [DailyCheckInScores]
    @State private var showingAllRecords = false
    @State private var selectedPeriod = "這週"

    private let timePeriodOptions = ["這週", "這月", "這季", "這半年", "這年"]
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter
    }()
    
    private var filteredScores: [DailyCheckInScores] {
        let calendar = Calendar.current
        let startDate = startDate(for: selectedPeriod, calendar: calendar)
        
        return scores
            .filter { $0.date >= startDate }
            .sorted { $0.date > $1.date }
    }

    private var visibleScores: [DailyCheckInScores] {
        Array(filteredScores.prefix(7))
    }

    private var averageRow: AverageScores? {
        guard !filteredScores.isEmpty else { return nil }

        let count = Double(filteredScores.count)
        let totalPhysical = filteredScores.reduce(0) { $0 + $1.physical }
        let totalEmotional = filteredScores.reduce(0) { $0 + $1.emotional }
        let totalSleep = filteredScores.reduce(0) { $0 + $1.sleep }
        let totalMental = filteredScores.reduce(0) { $0 + $1.mental }
        let totalAppetite = filteredScores.reduce(0) { $0 + $1.appetite }

        return AverageScores(
            physical: Double(totalPhysical) / count,
            emotional: Double(totalEmotional) / count,
            sleep: Double(totalSleep) / count,
            mental: Double(totalMental) / count,
            appetite: Double(totalAppetite) / count
        )
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("每日檢測紀錄")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                Spacer()
                if !scores.isEmpty {
                    Button("查看全部") {
                        showingAllRecords = true
                    }
                    .font(.caption)
                    .foregroundColor(AppColors.orange)
                }
            }

            HStack {
                Text("平均區間")
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))

                Spacer()

                Menu {
                    ForEach(timePeriodOptions, id: \.self) { option in
                        Button(option) {
                            selectedPeriod = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedPeriod)
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppColors.lightYellow.opacity(0.45))
                    )
                }
            }
            
            if filteredScores.isEmpty {
                Text("暫無資料")
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 6) {
                    HStack {
                        tableHeaderCell("日期")
                        tableHeaderCell("生理")
                        tableHeaderCell("心情")
                        tableHeaderCell("睡眠")
                        tableHeaderCell("精神")
                        tableHeaderCell("食慾")
                    }
                    .padding(.vertical, 6)
                    .background(AppColors.lightYellow.opacity(0.4))
                    .cornerRadius(6)
                    
                    ForEach(visibleScores) { score in
                        HStack {
                            tableCell(dateFormatter.string(from: score.date))
                            tableCell("\(score.physical)")
                            tableCell("\(score.emotional)")
                            tableCell("\(score.sleep)")
                            tableCell("\(score.mental)")
                            tableCell("\(score.appetite)")
                        }
                        .padding(.vertical, 4)
                    }

                    if let averageRow {
                        Divider()
                            .padding(.top, 2)

                        HStack {
                            averageCell("\(selectedPeriod)平均")
                            averageCell(formatAverage(averageRow.physical))
                            averageCell(formatAverage(averageRow.emotional))
                            averageCell(formatAverage(averageRow.sleep))
                            averageCell(formatAverage(averageRow.mental))
                            averageCell(formatAverage(averageRow.appetite))
                        }
                        .padding(.vertical, 6)
                        .background(AppColors.orange.opacity(0.08))
                        .cornerRadius(6)
                    }
                }
                .font(.caption2)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
        .sheet(isPresented: $showingAllRecords) {
            DailyScoresAllRecordsView(scores: filteredScores, periodTitle: selectedPeriod)
        }
    }
    
    private func tableHeaderCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.titleColor)
    }
    
    private func tableCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(AppColors.titleColor.opacity(0.8))
    }

    private func averageCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.titleColor)
    }

    private func formatAverage(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    private func startDate(for period: String, calendar: Calendar) -> Date {
        let now = Date()

        switch period {
        case "這週":
            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
            return calendar.date(from: components) ?? calendar.startOfDay(for: now)
        case "這月":
            let components = calendar.dateComponents([.year, .month], from: now)
            return calendar.date(from: components) ?? calendar.startOfDay(for: now)
        case "這季":
            let month = calendar.component(.month, from: now)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: now)
            components.month = quarterStartMonth
            components.day = 1
            return calendar.date(from: components) ?? calendar.startOfDay(for: now)
        case "這半年":
            return calendar.date(byAdding: .month, value: -6, to: calendar.startOfDay(for: now)) ?? calendar.startOfDay(for: now)
        case "這年":
            let components = calendar.dateComponents([.year], from: now)
            return calendar.date(from: components) ?? calendar.startOfDay(for: now)
        default:
            return calendar.startOfDay(for: now)
        }
    }
}

private struct DailyScoresAllRecordsView: View {
    let scores: [DailyCheckInScores]
    let periodTitle: String
    @Environment(\.dismiss) private var dismiss

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 8) {
                    HStack {
                        tableHeaderCell("日期")
                        tableHeaderCell("生理")
                        tableHeaderCell("心情")
                        tableHeaderCell("睡眠")
                        tableHeaderCell("精神")
                        tableHeaderCell("食慾")
                    }
                    .padding(.vertical, 6)
                    .background(AppColors.lightYellow.opacity(0.4))
                    .cornerRadius(6)

                    ForEach(scores.sorted { $0.date > $1.date }) { score in
                        HStack {
                            tableCell(dateFormatter.string(from: score.date))
                            tableCell("\(score.physical)")
                            tableCell("\(score.emotional)")
                            tableCell("\(score.sleep)")
                            tableCell("\(score.mental)")
                            tableCell("\(score.appetite)")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .font(.caption2)
                .padding()
            }
            .background(AppColors.lightYellow.ignoresSafeArea())
            .navigationTitle("\(periodTitle)紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundColor(AppColors.orange)
                }
            }
        }
    }

    private func tableHeaderCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.titleColor)
    }

    private func tableCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .foregroundColor(AppColors.titleColor.opacity(0.8))
    }
}

private struct AverageScores {
    let physical: Double
    let emotional: Double
    let sleep: Double
    let mental: Double
    let appetite: Double
}

#Preview {
    DailyScoresTableCard(
        scores: [
            DailyCheckInScores(physical: 3, mental: 1, emotional: 4, sleep: 2, appetite: 1, date: Date()),
            DailyCheckInScores(physical: 2, mental: 5, emotional: 2, sleep: 5, appetite: 1, date: Date().addingTimeInterval(-86400))
        ]
    )
    .padding()
    .background(AppColors.lightYellow)
}
