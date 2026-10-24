import SwiftUI

struct BiorhythmCard: View {
    let biorhythmData: BiorhythmData
    let currentDate: Date
    let birthDate: Date
    let animationProgress: Double
    let onEditTapped: () -> Void
    @State private var showingDetails: BiorhythmIndicator? = nil
    
    init(biorhythmData: BiorhythmData, currentDate: Date, birthDate: Date, animationProgress: Double, onEditTapped: @escaping () -> Void) {
        self.biorhythmData = biorhythmData
        self.currentDate = currentDate
        self.birthDate = birthDate
        self.animationProgress = animationProgress
        self.onEditTapped = onEditTapped
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        return formatter
    }
    
    // 獲取圓環顏色組 - 多層次漸層色彩
    private func getRingBaseColors(for indicator: BiorhythmIndicator) -> [Color] {
        switch indicator {
        case .physical:
            return [
                Color(red: 0.8, green: 0.9, blue: 1.0),   // 極淺藍
                Color(red: 0.6, green: 0.8, blue: 1.0),   // 淺藍
                Color(red: 0.4, green: 0.7, blue: 1.0),   // 中淺藍
                Color(red: 0.2, green: 0.5, blue: 0.9),   // 中藍
                Color(red: 0.1, green: 0.4, blue: 0.8),   // 中深藍
                Color(red: 0.0, green: 0.3, blue: 0.7),   // 深藍
                Color(red: 0.0, green: 0.2, blue: 0.6)    // 極深藍
            ]
        case .emotional:
            return [
                Color(red: 0.8, green: 1.0, blue: 0.8),   // 極淺綠
                Color(red: 0.6, green: 0.9, blue: 0.6),   // 淺綠
                Color(red: 0.4, green: 0.8, blue: 0.4),   // 中淺綠
                Color(red: 0.2, green: 0.7, blue: 0.2),   // 中綠
                Color(red: 0.1, green: 0.6, blue: 0.1),   // 中深綠
                Color(red: 0.0, green: 0.5, blue: 0.0),   // 深綠
                Color(red: 0.0, green: 0.4, blue: 0.0)    // 極深綠
            ]
        case .intellectual:
            return [
                Color(red: 0.9, green: 0.8, blue: 1.0),   // 極淺紫
                Color(red: 0.8, green: 0.6, blue: 1.0),   // 淺紫
                Color(red: 0.7, green: 0.4, blue: 0.9),   // 中淺紫
                Color(red: 0.6, green: 0.2, blue: 0.8),   // 中紫
                Color(red: 0.5, green: 0.1, blue: 0.7),   // 中深紫
                Color(red: 0.4, green: 0.0, blue: 0.6),   // 深紫
                Color(red: 0.3, green: 0.0, blue: 0.5)    // 極深紫
            ]
        case .sleep:
            return [
                Color(red: 0.8, green: 0.8, blue: 1.0),   // 極淺靛
                Color(red: 0.6, green: 0.6, blue: 0.9),   // 淺靛
                Color(red: 0.5, green: 0.5, blue: 0.8),   // 中淺靛
                Color(red: 0.4, green: 0.4, blue: 0.7),   // 中靛
                Color(red: 0.3, green: 0.3, blue: 0.6),   // 中深靛
                Color(red: 0.2, green: 0.2, blue: 0.5),   // 深靛
                Color(red: 0.1, green: 0.1, blue: 0.4)    // 極深靛
            ]
        case .appetite:
            return [
                Color(red: 1.0, green: 0.9, blue: 0.7),   // 極淺橙
                Color(red: 1.0, green: 0.8, blue: 0.5),   // 淺橙
                Color(red: 1.0, green: 0.7, blue: 0.3),   // 中淺橙
                Color(red: 0.9, green: 0.6, blue: 0.1),   // 中橙
                Color(red: 0.8, green: 0.5, blue: 0.0),   // 中深橙
                Color(red: 0.7, green: 0.4, blue: 0.0),   // 深橙
                Color(red: 0.6, green: 0.3, blue: 0.0)    // 極深橙
            ]
        }
    }
    
    // 根據數值獲取位置性漸層顏色（跟著刻度走，使用多層次色彩）
    private func getValueGradient(baseColors: [Color], value: Double, cycleDay: Int, totalCycle: Int) -> [Color] {
        var gradientColors: [Color] = []
        
        for day in 0..<totalCycle {
            let angle = Double(day) * 2 * .pi / Double(totalCycle)
            let dayValue = sin(angle) * 100  // -100 到 100
            
            // 將 -100 到 100 的範圍映射到色彩階層 (0-6)
            let normalizedValue = (dayValue + 100) / 200.0  // 轉換為 0-1
            let colorIndex = normalizedValue * Double(baseColors.count - 1)  // 映射到色彩索引
            
            // 在相鄰顏色之間進行插值
            let lowerIndex = Int(colorIndex)
            let upperIndex = min(lowerIndex + 1, baseColors.count - 1)
            let fraction = colorIndex - Double(lowerIndex)
            
            let lowerColor = baseColors[lowerIndex]
            let upperColor = baseColors[upperIndex]
            
            // 顏色插值
            let interpolatedColor = Color(
                red: lowerColor.red * (1 - fraction) + upperColor.red * fraction,
                green: lowerColor.green * (1 - fraction) + upperColor.green * fraction,
                blue: lowerColor.blue * (1 - fraction) + upperColor.blue * fraction
            )
            
            gradientColors.append(interpolatedColor)
        }
        
        return gradientColors
    }
    
    // 獲取週期中的當前位置角度
    private func getCycleAngle(indicator: BiorhythmIndicator) -> Double {
        let daysSinceBirth = BiorhythmCalculator.daysBetween(from: birthDate, to: currentDate)
        let cycle = indicator.standardCycle
        let dayInCycle = daysSinceBirth % cycle
        return (Double(dayInCycle) / Double(cycle)) * 360.0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 標題
            HStack {
                Text("標準生理節律")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(AppColors.titleColor)
                
                Spacer()
                
                Button(action: onEditTapped) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(AppColors.titleColor)
                        .font(.title2)
                }
            }
            
            // 今天日期
            Text("今天：\(dateFormatter.string(from: currentDate))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.titleColor)
            
            HStack(spacing: 0) {
                // 左側圓環圖表 - 固定寬度
                VStack(alignment: .center, spacing: 32) {
                    ZStack {
                        // 圓環和相關元素
                        if biorhythmData.mode == .standard {
                            standardBiorhythmRings
                            cycleScales
                            pointers
                        } else {
                            personalBiorhythmRings
                        }
                        
                        // 中心圓點
                        Circle()
                            .fill(AppColors.titleColor)
                            .frame(width: 6, height: 6)
                    }
                    .frame(width: 180, height: 180)
                    .animation(.none, value: biorhythmData.mode)
                    
                    legendView
                }
                .frame(width: 200)
                .padding(.bottom, 8)
                
                Spacer(minLength: 16)
                
                // 右側數據 - 緊湊佈局
                VStack(alignment: .leading, spacing: 10) {
                    if biorhythmData.mode == .standard {
                        standardIndicatorsList
                    } else {
                        personalIndicatorsList
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(AppColors.cardBackground)
        .cornerRadius(HomeConstants.Charts.cardCornerRadius)
        .shadow(color: .black.opacity(0.1), radius: HomeConstants.Charts.cardShadowRadius)
        .sheet(item: Binding<BiorhythmIndicator?>(
            get: { showingDetails },
            set: { showingDetails = $0 }
        )) { indicator in
            detailSheet(for: indicator)
        }
    }
    
    // MARK: - 標準模式圓環
    private var standardBiorhythmRings: some View {
        ZStack {
            createBiorhythmRing(value: biorhythmData.physical, indicator: .physical, size: 180, lineWidth:20)
            createBiorhythmRing(value: biorhythmData.emotional, indicator: .emotional, size: 130, lineWidth: 20)
            createBiorhythmRing(value: biorhythmData.intellectual, indicator: .intellectual, size: 80, lineWidth: 20)
        }
    }
    
    // MARK: - 個人模式圓環
    private var personalBiorhythmRings: some View {
        ZStack {
            createBiorhythmRing(value: biorhythmData.physical, indicator: .physical, size: 160, lineWidth: 14)
            createBiorhythmRing(value: biorhythmData.intellectual, indicator: .intellectual, size: 130, lineWidth: 12)
            createBiorhythmRing(value: biorhythmData.emotional, indicator: .emotional, size: 100, lineWidth: 10)
            createBiorhythmRing(value: biorhythmData.sleep ?? 0, indicator: .sleep, size: 70, lineWidth: 8)
            createBiorhythmRing(value: biorhythmData.appetite ?? 0, indicator: .appetite, size: 45, lineWidth: 6)
        }
    }
    
    // MARK: - 創建圓環（多層次漸層）
    private func createBiorhythmRing(value: Double, indicator: BiorhythmIndicator, size: CGFloat, lineWidth: CGFloat) -> some View {
        let baseColors = getRingBaseColors(for: indicator)
        let cycle = indicator.standardCycle
        let gradientColors = getValueGradient(baseColors: baseColors, value: value, cycleDay: 0, totalCycle: cycle)
        
        return ZStack {
            Circle()
                .strokeBorder(Color.gray.opacity(0.1), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .strokeBorder(
                    AngularGradient(colors: gradientColors, center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                    lineWidth: lineWidth
                )
                .frame(width: size, height: size)
                .opacity(animationProgress)
                .animation(.easeInOut(duration: HomeConstants.Animation.biorhythmAnimationDuration), value: animationProgress)
        }
    }
    
    // MARK: - 週期刻度（外圈獨立處理）
    private var cycleScales: some View {
        ZStack {
            // 體力圈：23天，獨立刻度系統
            physicalCycleScale
            // 情緒圈：28天，每7天粗線
            cycleScale(cycle: 28, radius: 68, color: getRingBaseColors(for: .emotional)[4], majorInterval: 7)
            // 智力圈：33天，每8天粗線
            cycleScaleCustom(cycle: 33, radius: 43, color: getRingBaseColors(for: .intellectual)[4], majorDays: [8, 16, 24, 32])
        }
    }
    
    private var physicalCycleScale: some View {
        let cycle = 23
        let radius: CGFloat = 88
        let color = getRingBaseColors(for: .physical)[4]  // 使用中深色
        let majorDays = [5, 10, 15, 20]

        return ZStack {
            ForEach(0..<cycle, id: \.self) { day in
                let angle = Double(day) * (360.0 / Double(cycle)) - 90
                let radians = angle * .pi / 180.0
                let isMajor = majorDays.contains(day)

                // 刻度線
                Rectangle()
                    .fill(color.opacity(isMajor ? 1.0 : 0.4))
                    .frame(width: isMajor ? 2.5 : 1, height: isMajor ? 10 : 5)
                    .offset(y: -((isMajor ? 10 : 5) / 2))
                    .rotationEffect(.degrees(angle + 90))
                    .position(
                        x: cos(radians) * radius + 90,
                        y: sin(radians) * radius + 90
                    )

                // 數字
                if isMajor {
                    Text("\(day)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(color)
                        .frame(width: 20, height: 10)
                        .position(
                            x: cos(radians) * (radius + 20) + 90,
                            y: sin(radians) * (radius + 20) + 90
                        )
                }
            }
        }
    }
    
    // 自定義刻度位置
    private func cycleScaleCustom(cycle: Int, radius: CGFloat, color: Color, majorDays: [Int]) -> some View {
        ForEach(0..<cycle, id: \.self) { day in
            let angle = Double(day) * (360.0 / Double(cycle)) - 90
            let radians = angle * .pi / 180.0
            let isMajor = majorDays.contains(day)
            
            Group {
                // 刻度線
                Rectangle()
                    .fill(color.opacity(isMajor ? 1.0 : 0.4))
                    .frame(width: isMajor ? 2.5 : 1, height: isMajor ? 10 : 5)
                    .offset(y: radius - (isMajor ? 10 : 5))
                    .rotationEffect(.degrees(angle))
                
                // 數字標記
                if isMajor {
                    Text("\(day)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(color)
                        .offset(
                            x: cos(radians) * (radius + 10),
                            y: sin(radians) * (radius + 10)
                        )
                }
            }
        }
    }
    
    private func cycleScale(cycle: Int, radius: CGFloat, color: Color, majorInterval: Int) -> some View {
        ForEach(0..<cycle, id: \.self) { day in
            let angle = Double(day) * (360.0 / Double(cycle)) - 90
            let radians = angle * .pi / 180.0
            let isMajor = day % majorInterval == 0 && day != 0
            
            Group {
                // 刻度線
                Rectangle()
                    .fill(color.opacity(isMajor ? 1.0 : 0.4))
                    .frame(width: isMajor ? 2.5 : 1, height: isMajor ? 10 : 5)
                    .offset(y: radius - (isMajor ? 10 : 5))
                    .rotationEffect(.degrees(angle))
                
                // 數字標記
                if isMajor {
                    Text("\(day)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(color)
                        .offset(
                            x: cos(radians) * (radius + 10),
                            y: sin(radians) * (radius + 10)
                        )
                }
            }
        }
    }
    
    // MARK: - 指針（精確對齊圓環）
    private var pointers: some View {
        ZStack {
            // 體力指針 - 精確指向外圈
            createPhysicalPointer(angle: getCycleAngle(indicator: .physical), length: 80, color: getRingBaseColors(for: .physical)[5], width: 2.5)
            // 情緒指針 - 指向中圈
            createPointer(angle: getCycleAngle(indicator: .emotional), length: 60, color: getRingBaseColors(for: .emotional)[5], width: 2)
            // 智力指針 - 指向內圈
            createPointer(angle: getCycleAngle(indicator: .intellectual), length: 40, color: getRingBaseColors(for: .intellectual)[5], width: 3)
        }
    }
    
    // 體力指針專用（精確對齊外圈刻度）
    private func createPhysicalPointer(angle: Double, length: CGFloat, color: Color, width: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length/2)
            .rotationEffect(.degrees(angle * animationProgress))
            .animation(.easeInOut(duration: HomeConstants.Animation.biorhythmAnimationDuration), value: animationProgress)
    }
    
    private func createPointer(angle: Double, length: CGFloat, color: Color, width: CGFloat) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length/2)
            .rotationEffect(.degrees(angle * animationProgress))
            .animation(.easeInOut(duration: HomeConstants.Animation.biorhythmAnimationDuration), value: animationProgress)
    }
    
    // MARK: - 圖例
    private var legendView: some View {
        VStack(alignment: .leading, spacing: 3) {
            if biorhythmData.mode == .standard {
                legendItem(color: getRingBaseColors(for: .physical)[4], text: "體力(23天)")
                legendItem(color: getRingBaseColors(for: .emotional)[4], text: "情緒(28天)")
                legendItem(color: getRingBaseColors(for: .intellectual)[4], text: "智力(33天)")
            } else {
                HStack(spacing: 8) {
                    legendItem(color: getRingBaseColors(for: .physical)[4], text: "生理")
                    legendItem(color: getRingBaseColors(for: .emotional)[4], text: "情緒")
                }
                HStack(spacing: 8) {
                    legendItem(color: getRingBaseColors(for: .intellectual)[4], text: "精神")
                    legendItem(color: getRingBaseColors(for: .sleep)[4], text: "睡眠")
                    legendItem(color: getRingBaseColors(for: .appetite)[4], text: "食慾")
                }
            }
        }
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 3) {
            Rectangle()
                .fill(color)
                .frame(width: 10, height: 3)
                .cornerRadius(1.5)
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(AppColors.titleColor)
        }
    }
    
    // MARK: - 標準模式指標列表
    private var standardIndicatorsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            indicatorRowCompact(
                indicator: .physical,
                value: biorhythmData.physical,
                title: "體力",
                cycleDay: BiorhythmCalculator.daysBetween(from: birthDate, to: currentDate) % 23
            )
            
            indicatorRowCompact(
                indicator: .emotional,
                value: biorhythmData.emotional,
                title: "情緒",
                cycleDay: BiorhythmCalculator.daysBetween(from: birthDate, to: currentDate) % 28
            )
            
            indicatorRowCompact(
                indicator: .intellectual,
                value: biorhythmData.intellectual,
                title: "智力",
                cycleDay: BiorhythmCalculator.daysBetween(from: birthDate, to: currentDate) % 33
            )
        }
    }
    
    // MARK: - 個人模式指標列表（與標準模式相同總高度）
    private var personalIndicatorsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            indicatorRowCompactPersonal(indicator: .physical, value: biorhythmData.physical, title: "生理")
            indicatorRowCompactPersonal(indicator: .emotional, value: biorhythmData.emotional, title: "情緒")
            indicatorRowCompactPersonal(indicator: .intellectual, value: biorhythmData.intellectual, title: "精神")
            
            // 空白佔位元素，確保與標準模式高度一致
            VStack(spacing: 8) {
                indicatorRowCompactPersonal(indicator: .sleep, value: biorhythmData.sleep ?? 0, title: "睡眠")
                indicatorRowCompactPersonal(indicator: .appetite, value: biorhythmData.appetite ?? 0, title: "食慾")
            }
            .scaleEffect(0.85)  // 縮小最後兩個指標
        }
    }
    
    // 個人模式指標行（調整為與標準模式相同的垂直間距）
    private func indicatorRowCompactPersonal(indicator: BiorhythmIndicator, value: Double, title: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(getRingBaseColors(for: indicator)[4])
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.titleColor)
            
            Spacer()
            
            Text(getValueText(value: value))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(getValueColor(value: value))
                .cornerRadius(8)
            
            Button("更多") {
                showingDetails = indicator
            }
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(AppColors.titleColor)
            .overlay(
                Rectangle()
                    .frame(height: 0.8)
                    .foregroundColor(AppColors.titleColor),
                alignment: .bottom
            )
        }
        .padding(.vertical, 4)
        .opacity(animationProgress)
    }
    
    // MARK: - 緊湊指標行
    private func indicatorRowCompact(indicator: BiorhythmIndicator, value: Double, title: String, cycleDay: Int) -> some View {
        let totalCycle = indicator.standardCycle
        let status = getCycleStatus(cycleDay: cycleDay, totalCycle: totalCycle)
        
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(getRingBaseColors(for: indicator)[4])
                    .frame(width: 10, height: 10)
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.titleColor)
                
                Spacer()
                
                Text(status.text)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(status.color)
                    .cornerRadius(10)
                    .fixedSize(horizontal: true, vertical: false)
            }
            
            HStack(spacing: 8) {
                Text("第\(cycleDay)天")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(getRingBaseColors(for: indicator)[4])
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(getRingBaseColors(for: indicator)[4].opacity(0.1))
                    .cornerRadius(8)
                
                Spacer()
                
                Button("更多") {
                    showingDetails = indicator
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.titleColor)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(AppColors.titleColor),
                    alignment: .bottom
                )
            }
        }
        .padding(.vertical, 4)
        .opacity(animationProgress)
        .animation(.easeInOut(duration: 1.0).delay(0.3), value: animationProgress)
    }
    
    // MARK: - 詳細資訊彈出視窗
    private func detailSheet(for indicator: BiorhythmIndicator) -> some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("詳細分析")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle()
                            .fill(getRingBaseColors(for: indicator)[4])
                            .frame(width: 12, height: 12)
                        Text(indicator == .physical ? "體力狀態" : indicator == .emotional ? "情緒狀態" : "智力狀態")
                            .font(.headline)
                    }
                    
                    Text("當前數值：\(Int((getValue(for: indicator) + 100) / 2))%")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(BiorhythmCalculator.getBiorhythmDescription(indicator: indicator, value: getValue(for: indicator)))
                        .font(.body)
                        .foregroundColor(AppColors.titleColor)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        showingDetails = nil
                    }
                }
            }
        }
    }
    
    private func getValue(for indicator: BiorhythmIndicator) -> Double {
        switch indicator {
        case .physical: return biorhythmData.physical
        case .emotional: return biorhythmData.emotional
        case .intellectual: return biorhythmData.intellectual
        case .sleep: return biorhythmData.sleep ?? 0
        case .appetite: return biorhythmData.appetite ?? 0
        }
    }
    
    // MARK: - 輔助方法（根據傳統生理節律理論）
    private func getValueText(value: Double) -> String {
        return value > 0 ? "高" : "低"
    }
    
    private func getValueColor(value: Double) -> Color {
        return value > 0 ? .green : .red
    }
    
    // 根據正弦波理論判斷狀態（臨界日是穿越基線時）
    private func getCycleStatus(cycleDay: Int, totalCycle: Int) -> (text: String, color: Color) {
        let angle = Double(cycleDay) * 2 * .pi / Double(totalCycle)
        let value = sin(angle) * 100
        
        if abs(value) <= 5 {
            return ("臨界", .orange)
        } else if value > 5 {
            return ("高", .green)
        } else {
            return ("低", .red)
        }
    }
}

// 讓 BiorhythmIndicator 符合 Identifiable
extension BiorhythmIndicator: Identifiable {
    public var id: String {
        switch self {
        case .physical: return "physical"
        case .emotional: return "emotional"
        case .intellectual: return "intellectual"
        case .sleep: return "sleep"
        case .appetite: return "appetite"
        }
    }
}

// Color extension for RGB initialization
extension Color {
    init(red: Double, green: Double, blue: Double) {
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1.0)
    }
    
    var red: Double {
        if let components = UIColor(self).cgColor.components, components.count >= 3 {
            return Double(components[0])
        }
        return 0
    }
    
    var green: Double {
        if let components = UIColor(self).cgColor.components, components.count >= 3 {
            return Double(components[1])
        }
        return 0
    }
    
    var blue: Double {
        if let components = UIColor(self).cgColor.components, components.count >= 3 {
            return Double(components[2])
        }
        return 0
    }
}
