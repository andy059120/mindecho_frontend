import SwiftUI

struct ScaleTrackingCard: View {
    @ObservedObject var manager: ScaleSessionManager
    @State private var selectedScaleCode: String = "全部"
    @State private var selectedOverlap: OverlapPoint?
    private let recentLimit = 5
    
    var body: some View {
        let series = manager.seriesForLastSessions(limit: recentLimit, filterCode: selectedScaleCode)
        let axisCount = recentLimit
        let fixedSeries = series.map { item in
            let trimmed = Array(item.data.prefix(axisCount))
            let padded = trimmed + Array(repeating: 0, count: max(0, axisCount - trimmed.count))
            return FixedScaleSeries(
                id: item.id,
                name: item.name,
                code: item.code,
                color: item.color,
                data: padded,
                actualCount: trimmed.count
            )
        }
        let hasAnyData = fixedSeries.contains { $0.actualCount > 0 }
        let dataMax = fixedSeries.flatMap { $0.data }.max() ?? 0
        let thresholdValue = selectedScaleThreshold()
        let maxValue = max(dataMax, thresholdValue ?? 0, 5)
        let chartMax = max(5, Int(ceil(Double(maxValue) / 5.0)) * 5)
        let overlapPoints = makeOverlapPoints(series: fixedSeries, axisCount: axisCount)
        
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("量表追蹤")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                
                Spacer()
                
                Menu {
                    Button("全部") {
                        selectedScaleCode = "全部"
                    }
                    Divider()
                    ForEach(manager.scales, id: \.code) { scale in
                        Button(scaleMenuLabel(for: scale)) {
                            selectedScaleCode = scale.code
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedScaleLabel)
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                    }
                }
            }
            
            HStack(spacing: 12) {
                ForEach(fixedSeries) { item in
                    indicatorLegend(name: item.code, color: item.color)
                }
            }
            
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let labels = sessionIndexLabels(count: axisCount)
                    let dayCount = labels.count
                    let leftInset: CGFloat = 32
                    let rightInset: CGFloat = 25
                    let topInset: CGFloat = 14
                    let bottomInset: CGFloat = 2
                    let plotWidth = max(0, width - leftInset - rightInset)
                    let plotHeight = max(0, height - topInset - bottomInset)
                    let dayWidth = dayCount > 1 ? plotWidth / CGFloat(dayCount - 1) : plotWidth

                    ZStack(alignment: .leading) {
                        Path { path in
                            for i in 0..<5 {
                                let value = chartMax - i * (chartMax / 4)
                                let y = yPosition(for: value, plotHeight: plotHeight, topInset: topInset, maxValue: chartMax)
                                path.move(to: CGPoint(x: leftInset, y: y))
                                path.addLine(to: CGPoint(x: leftInset + plotWidth, y: y))
                            }
                        }
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)

                        if let thresholdValue {
                            let y = yPosition(for: thresholdValue, plotHeight: plotHeight, topInset: topInset, maxValue: chartMax)
                            Path { path in
                                path.move(to: CGPoint(x: leftInset, y: y))
                                path.addLine(to: CGPoint(x: leftInset + plotWidth, y: y))
                            }
                            .stroke(Color.red, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 4]))
                        }
                        
                        ZStack(alignment: .topLeading) {
                            ForEach(0..<5, id: \.self) { i in
                                let value = chartMax - i * (chartMax / 4)
                                let y = yPosition(for: value, plotHeight: plotHeight, topInset: topInset, maxValue: chartMax)
                                Text("\(value)")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                    .position(
                                        x: leftInset / 2,
                                        y: y
                                    )
                            }
                        }
                        .frame(width: leftInset, height: height, alignment: .leading)
                        
                        ForEach(fixedSeries) { item in
                            createLine(
                                data: item.data,
                                color: item.color,
                                xOffset: leftInset,
                                height: height,
                                topInset: topInset,
                                plotHeight: plotHeight,
                                dayWidth: dayWidth,
                                plotWidth: plotWidth,
                                maxValue: chartMax,
                                actualCount: item.actualCount
                            )
                        }

                        ForEach(overlapPoints) { point in
                            let x = min(leftInset + CGFloat(point.index) * dayWidth, leftInset + plotWidth)
                            let y = yPosition(for: point.value, plotHeight: plotHeight, topInset: topInset, maxValue: chartMax)
                            Button {
                                selectedOverlap = point
                            } label: {
                                Color.clear
                                    .frame(width: 24, height: 24)
                            }
                            .position(x: x, y: y)
                        }

                        if let selected = selectedOverlap {
                            let x = min(leftInset + CGFloat(selected.index) * dayWidth, leftInset + plotWidth)
                            let y = yPosition(for: selected.value, plotHeight: plotHeight, topInset: topInset, maxValue: chartMax)
                            tooltipView(for: selected)
                                .position(x: x, y: max(topInset, y - 28))
                        }
                        
                        if !hasAnyData {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.titleColor.opacity(0.3))
                                Text("暫無數據")
                                    .font(.caption)
                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: 230)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedOverlap = nil
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(AppColors.lightBrown.opacity(0.4), lineWidth: 1)
                        )
                )
                
                HStack(spacing: 0) {
                    ForEach(sessionIndexLabels(count: axisCount), id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor)
                            .frame(maxWidth: .infinity, minHeight: 24)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            VStack(spacing: 12) {
                ForEach(manager.scales, id: \.code) { scale in
                    scaleTable(for: scale)
                }
            }
        }
        .padding()
        .background(AppColors.lightYellow.opacity(0.4))
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
    }
    
    private func indicatorLegend(name: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(name)
                .font(.caption2)
                .foregroundColor(AppColors.titleColor.opacity(0.8))
        }
    }

    private struct FixedScaleSeries: Identifiable {
        let id: String
        let name: String
        let code: String
        let color: Color
        let data: [Int]
        let actualCount: Int
    }

    private struct OverlapEntry: Identifiable {
        let id = UUID()
        let code: String
        let value: Int
        let color: Color
    }

    private struct OverlapPoint: Identifiable {
        let id = UUID()
        let index: Int
        let value: Int
        let entries: [OverlapEntry]
    }
    
    private func sessionIndexLabels(count: Int) -> [String] {
        guard count > 0 else { return [] }
        return (1...count).map { "第\($0)次" }
    }
    
    private func scaleTable(for scale: ScaleSessionScale) -> some View {
        let sessions = manager.lastSessions(scale: scale, limit: 5)
        let title = scaleTitle(code: scale.code, fallbackName: scale.name)
        return VStack(alignment: .leading, spacing: 6) {
            Text("\(title) (\(scale.code))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.titleColor)
            
            if sessions.isEmpty {
                Text("暫無資料")
                    .font(.caption)
                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                HStack {
                    tableHeaderCell("日期")
                    tableHeaderCell("分數")
                }
                .padding(.vertical, 6)
                .background(AppColors.lightYellow.opacity(0.4))
                .cornerRadius(6)
                
                ForEach(sessions) { session in
                    HStack {
                        tableCell(formatSessionDate(session.createdAt))
                        tableCell("\(session.totalScore)")
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: HomeConstants.Charts.cardCornerRadius)
                .stroke(AppColors.lightBrown.opacity(0.35), lineWidth: 1)
        )
    }
    
    private func formatSessionDate(_ value: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy-MM-dd"
        let date = manager.parseSessionDate(value) ?? Date()
        return formatter.string(from: date)
    }
    
    private func tableHeaderCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(AppColors.titleColor)
    }
    
    private func tableCell(_ text: String) -> some View {
        Text(text)
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.caption2)
            .foregroundColor(AppColors.titleColor.opacity(0.8))
    }

    private var selectedScaleLabel: String {
        guard selectedScaleCode != "全部" else { return "全部" }
        guard let scale = manager.scales.first(where: { $0.code == selectedScaleCode }) else {
            return selectedScaleCode
        }
        return scaleMenuLabel(for: scale)
    }

    private func scaleMenuLabel(for scale: ScaleSessionScale) -> String {
        let title = scaleTitle(code: scale.code, fallbackName: scale.name)
        guard title != scale.code else { return scale.code }
        return "\(scale.code) \(title)"
    }

    private func scaleTitle(code: String, fallbackName: String) -> String {
        if let meta = HomeConstants.Tests.scaleMetas.first(where: { $0.code == code }) {
            return meta.title
        }
        return fallbackName.isEmpty ? code : fallbackName
    }
    
    private func createLine(
        data: [Int],
        color: Color,
        xOffset: CGFloat,
        height: CGFloat,
        topInset: CGFloat,
        plotHeight: CGFloat,
        dayWidth: CGFloat,
        plotWidth: CGFloat,
        maxValue: Int,
        actualCount: Int
    ) -> some View {
        ZStack {
            Path { path in
                guard actualCount > 0 else { return }
                for i in 0..<actualCount {
                    let x = xOffset + CGFloat(i) * dayWidth
                    let y = yPosition(for: data[i], plotHeight: plotHeight, topInset: topInset, maxValue: maxValue)
                    
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            
            ForEach(Array(data.prefix(actualCount).enumerated()), id: \.offset) { i, value in
                Circle()
                    .fill(color)
                    .frame(width: 4, height: 4)
                    .position(
                        x: min(xOffset + CGFloat(i) * dayWidth, xOffset + plotWidth),
                        y: yPosition(for: value, plotHeight: plotHeight, topInset: topInset, maxValue: maxValue)
                    )
                    .shadow(color: color.opacity(0.3), radius: 2)
            }
        }
    }

    private func makeOverlapPoints(series: [FixedScaleSeries], axisCount: Int) -> [OverlapPoint] {
        guard axisCount > 0 else { return [] }
        var results: [OverlapPoint] = []
        for index in 0..<axisCount {
            let entries = series.compactMap { item -> OverlapEntry? in
                guard index < item.actualCount else { return nil }
                return OverlapEntry(code: item.code, value: item.data[index], color: item.color)
            }
            guard entries.count > 1 else { continue }
            let groups = Dictionary(grouping: entries, by: { $0.value })
            for (value, grouped) in groups where grouped.count > 1 {
                results.append(OverlapPoint(index: index, value: value, entries: grouped))
            }
        }
        return results
    }

    private func tooltipView(for point: OverlapPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(point.entries) { entry in
                HStack(spacing: 6) {
                    Circle()
                        .fill(entry.color)
                        .frame(width: 6, height: 6)
                    Text("\(entry.code): \(entry.value)")
                        .font(.caption2)
                        .foregroundColor(AppColors.titleColor)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
        )
    }

    private func selectedScaleThreshold() -> Int? {
        guard selectedScaleCode != "全部" else { return nil }
        guard let meta = HomeConstants.Tests.scaleMetas.first(where: { $0.code == selectedScaleCode }) else {
            return nil
        }
        return meta.questionCount * 3
    }

    private func yPosition(for value: Int, plotHeight: CGFloat, topInset: CGFloat, maxValue: Int) -> CGFloat {
        let safeMax = max(maxValue, 1)
        let clamped = max(0, min(value, safeMax))
        let normalizedValue = CGFloat(clamped) / CGFloat(safeMax)
        return topInset + (plotHeight - (normalizedValue * plotHeight))
    }
}
