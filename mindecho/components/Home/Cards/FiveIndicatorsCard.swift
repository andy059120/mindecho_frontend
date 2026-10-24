import SwiftUI

struct FiveIndicatorsCard: View {
    @Binding var selectedTimePeriod: String
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    @State private var showingDropdown = false
    @State private var selectedIndicator: HealthIndicatorType? = nil  // nil = 顯示所有指標
    @State private var selectedOverlap: OverlapPoint? = nil
    
    private let indicatorOrder: [HealthIndicatorType]
    private let customDisplayNames: [HealthIndicatorType: String]
    
    let timePeriodOptions = HomeConstants.Charts.timePeriodOptions
    
    init(
        selectedTimePeriod: Binding<String>,
        indicatorOrder: [HealthIndicatorType] = [.physical, .emotional, .sleep, .mental, .appetite],
        customDisplayNames: [HealthIndicatorType: String] = [:]
    ) {
        _selectedTimePeriod = selectedTimePeriod
        self.indicatorOrder = indicatorOrder
        self.customDisplayNames = customDisplayNames
    }
    
    private var activeIndicators: [HealthIndicatorType] {
        indicatorOrder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("五項指標追蹤")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)

                Spacer()

                // 指標選擇器
                Menu {
                    Button("顯示全部") {
                        selectedIndicator = nil
                    }
                    Divider()
                    ForEach(activeIndicators, id: \.self) { indicator in
                        Button(displayName(for: indicator)) {
                            selectedIndicator = indicator
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedIndicator.map { displayName(for: $0) } ?? "全部")
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                    }
                }

                // 時間週期選擇器
                Menu {
                    ForEach(timePeriodOptions, id: \.self) { option in
                        Button(action: {
                            selectedTimePeriod = option
                        }) {
                            Text(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedTimePeriod)
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                    }
                }
            }

            // 圖例 - 根據選擇顯示
            HStack(spacing: 12) {
                if let selected = selectedIndicator {
                    indicatorLegend(name: displayName(for: selected), color: selected.color)
                } else {
                    ForEach(activeIndicators, id: \.self) { indicator in
                        indicatorLegend(name: displayName(for: indicator), color: indicator.color)
                    }
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption2)
                Text(selectedIndicator == nil
                     ? "右上角的「全部」可切換成單一指標檢視"
                     : "可從右上角切換回全部或改看其他指標")
                    .font(.caption2)
                    .lineLimit(1)
            }
            .foregroundColor(AppColors.titleColor.opacity(0.55))

            // 圖表和標籤組合
            VStack(spacing: 4) {
                // 圖表區域
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let dataLabels = checkInManager.getDateLabelsForPeriod(selectedTimePeriod)
                    let dayCount = dataLabels.count
                    let leftInset: CGFloat = 32
                    let rightInset: CGFloat = 25
                    let plotWidth = max(0, width - leftInset - rightInset)
                    let dayWidth = dayCount > 1 ? plotWidth / CGFloat(dayCount - 1) : plotWidth
                    let overlapPoints = makeOverlapPoints(
                        indicators: activeIndicators,
                        dayCount: dayCount,
                        dayWidth: dayWidth,
                        xOffset: leftInset,
                        plotWidth: plotWidth,
                        height: height
                    )

                    ZStack(alignment: .leading) {
                        let hasData: Bool = {
                            if let selected = selectedIndicator {
                                return checkInManager
                                    .getDataForPeriod(selectedTimePeriod, indicator: selected)
                                    .contains(where: { $0 > 0 })
                            }
                            return activeIndicators.contains { indicator in
                                checkInManager
                                    .getDataForPeriod(selectedTimePeriod, indicator: indicator)
                                    .contains(where: { $0 > 0 })
                            }
                        }()
                        // 背景網格線
                        Path { path in
                            for i in 0..<5 {
                                let y = height * CGFloat(i) / 4
                                path.move(to: CGPoint(x: leftInset, y: y))
                                path.addLine(to: CGPoint(x: leftInset + plotWidth, y: y))
                            }
                        }
                        .stroke(Color.gray.opacity(0.1), lineWidth: 0.5)
                        
                        // Y軸刻度標籤
                        VStack(alignment: .leading) {
                            ForEach(0..<5, id: \.self) { i in
                                HStack {
                                    Text("\(5 - i)")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.titleColor.opacity(0.6))
                                    Spacer()
                                }
                                if i < 4 { Spacer() }
                            }
                        }
                        .frame(width: leftInset, height: height, alignment: .leading)
                        
                        // 根據選擇顯示指標線條
                        if let selected = selectedIndicator {
                            // 只顯示選中的指標
                            createIndicatorLine(
                                data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: selected),
                                color: selected.color,
                                width: width,
                                height: height,
                                xOffset: leftInset,
                                dayWidth: dayWidth,
                                plotWidth: plotWidth,
                                lineWidth: 3,
                                showValueLabels: true
                            )
                        } else {
                            // 顯示所有指標
                            ForEach(activeIndicators, id: \.self) { indicator in
                                createIndicatorLine(
                                    data: checkInManager.getDataForPeriod(selectedTimePeriod, indicator: indicator),
                                    color: indicator.color,
                                    width: width,
                                    height: height,
                                    xOffset: leftInset,
                                    dayWidth: dayWidth,
                                    plotWidth: plotWidth,
                                    lineWidth: 2,
                                    showValueLabels: false
                                )
                            }
                        }

                        if selectedIndicator == nil {
                            ForEach(overlapPoints) { point in
                                Button {
                                    selectedOverlap = point
                                } label: {
                                    overlapMarkerView(for: point)
                                }
                                .buttonStyle(.plain)
                                .position(x: point.x, y: point.y)
                            }

                            if let selected = selectedOverlap {
                                tooltipView(for: selected)
                                    .position(x: selected.x, y: max(12, selected.y - 28))
                            }
                        }
                        
                        // 如果沒有數據，顯示提示
                        if !hasData {
                            VStack(spacing: 8) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.titleColor.opacity(0.3))
                                Text("暫無數據")
                                    .font(.caption)
                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                Text("完成每日檢測後查看趨勢")
                                    .font(.caption2)
                                    .foregroundColor(AppColors.titleColor.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .frame(height: HomeConstants.Charts.chartHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedOverlap = nil
                }
                
                // 日期標籤 - 雙行顯示
                HStack(spacing: 0) {
                    ForEach(Array(checkInManager.getDateLabelsForPeriod(selectedTimePeriod).enumerated()), id: \.offset) { index, day in
                        if selectedTimePeriod == "最近七月" && !day.isEmpty {
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(AppColors.titleColor)
                                .frame(maxWidth: .infinity, minHeight: 24)
                                .lineLimit(1)
                        } else if selectedTimePeriod == "最近七週" && !day.isEmpty {
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(AppColors.titleColor)
                                .frame(maxWidth: .infinity, minHeight: 24)
                                .lineLimit(1)
                        } else if selectedTimePeriod == "最近三年半" && !day.isEmpty {
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(AppColors.titleColor)
                                .frame(maxWidth: .infinity, minHeight: 24)
                                .lineLimit(1)
                        } else {
                            // 本週：單行顯示
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(AppColors.titleColor)
                                .frame(maxWidth: .infinity, minHeight: 24)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
    }
    
    // MARK: - 輔助方法
    private func displayName(for indicator: HealthIndicatorType) -> String {
        customDisplayNames[indicator] ?? indicator.displayName
    }
    
    /// 創建圖例項目
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

    private struct OverlapEntry: Identifiable {
        let id = UUID()
        let name: String
        let value: Int
        let color: Color
    }

    private struct OverlapPoint: Identifiable {
        let id = UUID()
        let x: CGFloat
        let y: CGFloat
        let entries: [OverlapEntry]
    }
    
    /// 創建指標線條
    private func createIndicatorLine(
        data: [Int],
        color: Color,
        width: CGFloat,
        height: CGFloat,
        xOffset: CGFloat,
        dayWidth: CGFloat,
        plotWidth: CGFloat,
        lineWidth: CGFloat = 2,
        showValueLabels: Bool = false
    ) -> some View {
        ZStack {
            // 線條
            Path { path in
                var hasStarted = false
                for i in 0..<data.count {
                    if data[i] > 0 {
                        let x = xOffset + CGFloat(i) * dayWidth
                        let normalizedValue = CGFloat(data[i] - 1) / 4.0
                        let y = height - (normalizedValue * height)

                        if !hasStarted {
                            path.move(to: CGPoint(x: x, y: y))
                            hasStarted = true
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            
            // 數據點
            ForEach(Array(data.enumerated()), id: \.offset) { i, value in
                if value > 0 {
                    let x = xOffset + CGFloat(i) * dayWidth
                    let y = height - (CGFloat(value - 1) / 4.0 * height)
                    Circle()
                        .fill(color)
                        .frame(width: lineWidth + 2, height: lineWidth + 2)
                        .position(
                            x: x,
                            y: y
                        )
                        .shadow(color: color.opacity(0.3), radius: 2)
                    
                    if showValueLabels {
                        Text("\(value)")
                            .font(.caption2)
                            .foregroundColor(color)
                            .position(x: x, y: max(8, y - 12))
                    }
                }
            }
        }
    }

    private func makeOverlapPoints(
        indicators: [HealthIndicatorType],
        dayCount: Int,
        dayWidth: CGFloat,
        xOffset: CGFloat,
        plotWidth: CGFloat,
        height: CGFloat
    ) -> [OverlapPoint] {
        guard dayCount > 0 else { return [] }
        var points: [OverlapPoint] = []

        for index in 0..<dayCount {
            let entries = indicators.compactMap { indicator -> OverlapEntry? in
                let data = checkInManager.getDataForPeriod(selectedTimePeriod, indicator: indicator)
                guard index < data.count else { return nil }
                let value = data[index]
                guard value > 0 else { return nil }
                return OverlapEntry(name: displayName(for: indicator), value: value, color: indicator.color)
            }
            guard entries.count > 1 else { continue }

            let groups = Dictionary(grouping: entries, by: { $0.value })
            for (value, grouped) in groups where grouped.count > 1 {
                let x = min(xOffset + CGFloat(index) * dayWidth, xOffset + plotWidth)
                let y = height - (CGFloat(value - 1) / 4.0 * height)
                points.append(OverlapPoint(x: x, y: y, entries: grouped))
            }
        }
        return points
    }

    private func tooltipView(for point: OverlapPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(point.entries) { entry in
                HStack(spacing: 6) {
                    Circle()
                        .fill(entry.color)
                        .frame(width: 6, height: 6)
                    Text("\(entry.name): \(entry.value)")
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

    private func overlapMarkerView(for point: OverlapPoint) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(AppColors.titleColor.opacity(0.18), lineWidth: 1)
                )

            ForEach(Array(point.entries.enumerated()), id: \.element.id) { index, entry in
                let offset = overlapMarkerOffset(for: index, total: point.entries.count)
                Circle()
                    .fill(entry.color)
                    .frame(width: 7, height: 7)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 1)
                    )
                    .offset(x: offset.width, y: offset.height)
            }
        }
        .frame(width: 28, height: 28)
        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
    }

    private func overlapMarkerOffset(for index: Int, total: Int) -> CGSize {
        guard total > 1 else { return .zero }
        let radius: CGFloat = total > 3 ? 7 : 6
        let startAngle = -CGFloat.pi / 2
        let angle = startAngle + (2 * CGFloat.pi * CGFloat(index) / CGFloat(total))
        return CGSize(width: cos(angle) * radius, height: sin(angle) * radius)
    }
}

// 擴展 HealthIndicatorType 添加顯示名稱
extension HealthIndicatorType {
    var displayName: String {
        switch self {
        case .physical: return "生理"
        case .mental: return "精神"
        case .emotional: return "心情"
        case .sleep: return "睡眠"
        case .appetite: return "食慾"
        case .overall: return "整體"
        }
    }
}

#Preview {
    FiveIndicatorsCard(selectedTimePeriod: .constant("本週"))
        .padding()
        .background(AppColors.lightYellow)
}
