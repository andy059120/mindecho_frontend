import SwiftUI
import AudioToolbox
import AVFoundation

struct DailyReminderItem {
    let title: String
    let content: String
}

enum DailyReminderData {
    static let reminders: [DailyReminderItem] = [
        DailyReminderItem(title: "追尋", content: "不論成功或失敗，我選擇追尋心中堅定不移的方向。成功者追尋更大的可能，失敗者追尋新的希望。"),
        DailyReminderItem(title: "接觸", content: "我允許自己深深接觸情緒，盡情大哭、盡情大笑，讓情緒成為重整、轉化與整合的資源。"),
        DailyReminderItem(title: "迎新", content: "迎向新希望，開啟人生的轉折點。"),
        DailyReminderItem(title: "給予", content: "不求回報地給予他人，使我重新拾回內在的能量與滿足。我知道，自己就是一股力量。"),
        DailyReminderItem(title: "微笑", content: "微笑，是我與世界連結的開始，是一種表達愉悅、歡樂與幸福的方式。"),
        DailyReminderItem(title: "誠實", content: "誠實面對內心的傷口，以愛回應自己，也回應他人。"),
        DailyReminderItem(title: "及時", content: "愛要及時，活在當下，珍惜此刻。"),
        DailyReminderItem(title: "創造", content: "不再受限於陳舊的信念，我親力親為，創造屬於自己的嶄新生活與正向環境。"),
        DailyReminderItem(title: "定位", content: "我給自己重新定位，找到真正想追求的目標。"),
        DailyReminderItem(title: "決心", content: "深呼吸，在猶豫之後下定決心，然後持續往前走。"),
        DailyReminderItem(title: "執行", content: "掌握當下，確實行動，讓決心落地。"),
        DailyReminderItem(title: "毅力", content: "世人缺乏的往往不是力量，而是堅持到底的毅力。"),
        DailyReminderItem(title: "奮鬥", content: "我捍衛所堅信的價值，奮鬥，是夢想實現的開始。"),
        DailyReminderItem(title: "平衡", content: "人生如同騎單車，唯有向前，才能保持平衡。"),
        DailyReminderItem(title: "謙虛", content: "柔軟謙和，是我最強大的力量。"),
        DailyReminderItem(title: "重複", content: "我明白，所有能力與技能，皆來自無數次緩慢卻踏實的重複練習。"),
        DailyReminderItem(title: "志氣", content: "昂首闊步，我以自己為榮，為高尚而遠大的目標前行。"),
        DailyReminderItem(title: "綻放", content: "以付出與滋養，讓生命之花自然綻放，讓世界見證我的美好。"),
        DailyReminderItem(title: "美", content: "世界不缺少美，缺少的是發現美的眼睛。我選擇用心體驗生活中的每一刻。"),
        DailyReminderItem(title: "舒坦", content: "不再鑽牛角尖，讓心回到放鬆與舒坦。"),
        DailyReminderItem(title: "經營", content: "我用心經營生命中的每一刻，處處皆有美好。"),
        DailyReminderItem(title: "思考", content: "停下忙亂的腳步，靜心思考，親近自己。"),
        DailyReminderItem(title: "能力", content: "我認識並相信自己的力量，在能力範圍內突破每一次挑戰。"),
        DailyReminderItem(title: "願景", content: "我找回心中最初的願景，不再被眼前的挫折遮蔽雙眼。"),
        DailyReminderItem(title: "夢想", content: "我正走在通往夢想的路上，即使跌倒，也依然帶著喜悅前行。"),
        DailyReminderItem(title: "無限", content: "我探索自身無限的潛能，接納生命中的各種可能。"),
        DailyReminderItem(title: "勤勉", content: "我願意付出時間與心力，完成屬於我的任務與挑戰。"),
        DailyReminderItem(title: "感恩", content: "感恩，開啟豐富的人生，讓我體驗身旁的人、事、物與所擁有的一切。"),
        DailyReminderItem(title: "關懷", content: "我關懷自己，也關懷他人，用心體會其中的溫柔與美好。"),
        DailyReminderItem(title: "尋找", content: "當我尋找出路時，我記得：雨後的天空，終會出現彩虹。"),
        DailyReminderItem(title: "提升", content: "開啟內在的正向潛能，成為更完整的自己。"),
        DailyReminderItem(title: "忠誠", content: "忠於真實的我，誠實面對自己與他人。"),
        DailyReminderItem(title: "欣賞", content: "這一次，我選擇以欣賞的眼光看世界，看見不同的風景。"),
        DailyReminderItem(title: "克服", content: "挑戰不只是困境，也是成長的契機。"),
        DailyReminderItem(title: "責任", content: "我是我自己，也願為自己的選擇負責。"),
        DailyReminderItem(title: "嘗試", content: "每一次小小的嘗試，都可能帶來巨大的改變。"),
        DailyReminderItem(title: "修養", content: "回歸內在，傾聽自己的聲音。"),
        DailyReminderItem(title: "理想", content: "穩健的步伐，引領我走向心中的理想。"),
        DailyReminderItem(title: "奉獻", content: "投入、奉獻，在學習中成長。"),
        DailyReminderItem(title: "感動", content: "珍惜內心被觸動的時刻，好好靠近自己。")
    ]

    static func randomReminder() -> DailyReminderItem {
        reminders.randomElement() ?? reminders[0]
    }
}

struct DailyReminderCard: View {
    private let spinDuration: TimeInterval = 2.4
    @State private var reminder: DailyReminderItem = DailyReminderData.randomReminder()
    @State private var hasSelected = false
    @State private var wheelItems: [DailyReminderItem] = []
    @State private var rotation: Double = 0
    @State private var isSpinning = false
    private let cardHeight: CGFloat = HomeConstants.Charts.chartHeight + 96

    var body: some View {
        Button {
            spinWheel()
        } label: {
            VStack(alignment: .center, spacing: 10) {
                Text("今日箴言")
                    .font(.headline)
                    .foregroundColor(.brown)
                    .frame(maxWidth: .infinity, alignment: .center)

                ZStack {
                    InlineQuoteWheel(
                        items: wheelItems,
                        rotation: rotation
                    )
                    .frame(width: 110, height: 110)

                    PressMeButton()
                        .frame(width: 56, height: 56)
                }
                .padding(.top, 6)

                if hasSelected {
                    // MARK: - 引言文字
                    Text(reminder.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(reminder.content)
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor)
                        .lineLimit(6)
                        .minimumScaleFactor(0.95)
                        .padding(.bottom, 4)
                        .frame(minHeight: 50, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.yellow.opacity(0.15))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if wheelItems.isEmpty {
                wheelItems = Array(DailyReminderData.reminders.shuffled().prefix(12))
            }
        }
    }

    private func spinWheel() {
        guard !isSpinning else { return }
        isSpinning = true
        DailyReminderSoundPlayer.startLoop()
        let pool = wheelItems.isEmpty ? DailyReminderData.reminders : wheelItems
        let extraRotations = Double(Int.random(in: 3...6)) * 360
        let randomOffset = Double.random(in: 0..<360)
        let targetRotation = rotation + extraRotations + randomOffset
        withAnimation(.easeOut(duration: spinDuration)) {
            rotation = targetRotation
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration) {
            DailyReminderSoundPlayer.stopLoop()
            let index = selectedIndex(for: rotation, segmentCount: pool.count)
            let selectedReminder = pool[index]
            reminder = selectedReminder
            hasSelected = true
            isSpinning = false
        }
    }

    private func selectedIndex(for rotation: Double, segmentCount: Int) -> Int {
        guard segmentCount > 0 else { return 0 }
        let sliceAngle = 360.0 / Double(segmentCount)
        let normalized = rotation.truncatingRemainder(dividingBy: 360.0)
        let angle = normalized < 0 ? normalized + 360.0 : normalized
        let rawIndex = Int((angle / sliceAngle).rounded(.down))
        let index = max(0, min(segmentCount - 1, rawIndex))
        return index % segmentCount
    }
}

struct QuoteWheelView: View {
    let reminders: [DailyReminderItem]
    let onSelected: (DailyReminderItem) -> Void

    @Environment(\.dismiss) private var dismiss
    private let spinDuration: TimeInterval = 2.4
    @State private var rotation: Double = 0
    @State private var isSpinning = false
    @State private var selected: DailyReminderItem?
    @State private var wheelItems: [DailyReminderItem] = []

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                wheel
                pointer
            }
            .frame(width: 280, height: 280)

            Button {
                spinWheel()
            } label: {
                Text(isSpinning ? "轉動中..." : "開始轉動")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.orange)
                    .cornerRadius(12)
            }
            .disabled(isSpinning)

            if let selected {
                VStack(spacing: 8) {
                    Text(selected.title)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(AppColors.titleColor)
                    Text(selected.content)
                        .font(.body)
                        .foregroundColor(AppColors.titleColor)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
            } else {
                Text("轉動轉盤，獲得今日箴言")
                    .font(.subheadline)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))
            }

            Spacer()
        }
        .padding(.top, 16)
        .padding(.horizontal, 20)
        .background(AppColors.lightYellow.ignoresSafeArea())
        .navigationTitle(" ")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if wheelItems.isEmpty {
                wheelItems = Array(reminders.shuffled().prefix(12))
            }
        }
    }

    private var wheelTitles: [String] {
        wheelItems.map { $0.title }
    }

    private var wheel: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2
            let segmentCount = 12
            let sliceAngle = 360.0 / Double(segmentCount)

            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    PieSlice(
                        startAngle: .degrees(Double(index) * sliceAngle - 90),
                        endAngle: .degrees(Double(index + 1) * sliceAngle - 90)
                    )
                    .fill(AppColors.resourceCardYellow)
                }

                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 6)
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(0..<segmentCount, id: \.self) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2, height: 20)
                        .offset(y: -radius + 18)
                        .rotationEffect(.degrees(Double(index) * sliceAngle))
                }

                ForEach(0..<wheelTitles.count, id: \.self) { index in
                    Text(wheelTitles[index])
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(AppColors.titleColor)
                        .rotationEffect(.degrees(Double(index) * sliceAngle))
                        .offset(y: -radius + 58)
                        .rotationEffect(.degrees(-Double(index) * sliceAngle))
                }
            }
            .frame(width: size, height: size)
        }
    }

    private var pointer: some View {
        ZStack {
            Image(systemName: "triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(AppColors.titleColor)
                .rotationEffect(.degrees(180))
                .offset(y: -138)
        }
        .frame(width: 280, height: 280)
        .rotationEffect(.degrees(rotation))
    }

    private func spinWheel() {
        guard !isSpinning else { return }
        isSpinning = true
        DailyReminderSoundPlayer.startLoop()
        let pool = wheelItems.isEmpty ? reminders : wheelItems
        let extraRotations = Double(Int.random(in: 3...6)) * 360
        let randomOffset = Double.random(in: 0..<360)
        let targetRotation = rotation + extraRotations + randomOffset
        withAnimation(.easeOut(duration: spinDuration)) {
            rotation = targetRotation
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + spinDuration) {
            DailyReminderSoundPlayer.stopLoop()
            let index = selectedIndex(for: rotation, segmentCount: pool.count)
            let selectedReminder = pool[index]
            selected = selectedReminder
            onSelected(selectedReminder)
            isSpinning = false
        }
    }

    private func selectedIndex(for rotation: Double, segmentCount: Int) -> Int {
        guard segmentCount > 0 else { return 0 }
        let sliceAngle = 360.0 / Double(segmentCount)
        let normalized = rotation.truncatingRemainder(dividingBy: 360.0)
        let angle = normalized < 0 ? normalized + 360.0 : normalized
        let rawIndex = Int((angle / sliceAngle).rounded(.down))
        let index = max(0, min(segmentCount - 1, rawIndex))
        return index % segmentCount
    }
}

private struct InlineQuoteWheel: View {
    let items: [DailyReminderItem]
    let rotation: Double

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size / 2
            let segmentCount = max(items.count, 1)
            let sliceAngle = 360.0 / Double(segmentCount)

            ZStack {
                ForEach(0..<segmentCount, id: \.self) { index in
                    PieSlice(
                        startAngle: .degrees(Double(index) * sliceAngle - 90),
                        endAngle: .degrees(Double(index + 1) * sliceAngle - 90)
                    )
                    .fill(AppColors.resourceCardYellow)
                }

                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 4)
                    .frame(width: radius * 2, height: radius * 2)

                ForEach(0..<segmentCount, id: \.self) { index in
                    Rectangle()
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2, height: 10)
                        .offset(y: -radius + 10)
                        .rotationEffect(.degrees(Double(index) * sliceAngle))
                }

                Image(systemName: "triangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.titleColor)
                    .rotationEffect(.degrees(180))
                    .offset(y: -radius + 6)
            }
            .rotationEffect(.degrees(rotation))
            .animation(.easeOut(duration: 2.4), value: rotation)
            .frame(width: size, height: size)
        }
    }
}

private struct PressMeButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.82, blue: 0.45),
                            Color(red: 0.96, green: 0.60, blue: 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                .shadow(color: Color.white.opacity(0.7), radius: 2, x: 0, y: -1)

            Text("按我")
                .font(.caption.weight(.bold))
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1)
        }
    }
}

private struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        path.closeSubpath()
        return path
    }
}

private final class DailyReminderSoundPlayer {
    private static var loopPlayer: AVAudioPlayer?
    private static var fallbackTimer: Timer?

    static func startLoop() {
        stopLoop()

        if let player = makeLoopPlayer() {
            loopPlayer = player
            player.numberOfLoops = -1
            player.currentTime = 0
            player.play()
            return
        }

        startFallbackLoop()
    }

    static func stopLoop() {
        loopPlayer?.stop()
        loopPlayer = nil
        fallbackTimer?.invalidate()
        fallbackTimer = nil
    }

    private static func makeLoopPlayer() -> AVAudioPlayer? {
        let candidates = [
            ("wheel-spin-loop", "mp3"),
            ("wheel-spin-loop", "wav"),
            ("wheel-spin-loop", "m4a")
        ]

        for (name, ext) in candidates {
            guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
                continue
            }

            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                return player
            } catch {
                print("DailyReminderSoundPlayer: failed to load \(name).\(ext) - \(error.localizedDescription)")
            }
        }

        return nil
    }

    private static func startFallbackLoop() {
        AudioServicesPlaySystemSound(1104)
        fallbackTimer = Timer.scheduledTimer(withTimeInterval: 0.09, repeats: true) { _ in
            AudioServicesPlaySystemSound(1104)
        }
    }
}

#Preview {
    DailyReminderCard()
        .previewLayout(.sizeThatFits)
        .padding()
        .background(Color(.systemBackground))
}
