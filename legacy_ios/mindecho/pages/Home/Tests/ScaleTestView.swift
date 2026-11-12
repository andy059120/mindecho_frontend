import SwiftUI

struct ScaleTestView: View {
    let meta: ScaleMeta
    @Binding var isPresented: Bool
    
    @State private var currentQuestion = 0
    @State private var answers: [Int] = []
    @State private var answeredQuestions = Set<Int>()
    @State private var showingResult = false
    @State private var showingReview = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var questions: [ScaleQuestion] = []
    @State private var questionIds: [String] = []
    @State private var showingIntro = true
    @State private var resultExplanationHeight: CGFloat?

    private struct ScaleOption {
        let label: String
        let score: Int
    }
    
    init(meta: ScaleMeta, isPresented: Binding<Bool>) {
        self.meta = meta
        self._isPresented = isPresented
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("載入中...")
                        .foregroundColor(AppColors.titleColor)
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text("載入失敗")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(AppColors.titleColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                        Button("重試") {
                            Task { await loadQuestions() }
                        }
                    }
                    .padding()
                } else if showingResult {
                    completionView
                } else if showingIntro {
                    introView
                } else if showingReview {
                    reviewView
                } else {
                    questionView
                }
            }
            .onAppear {
                if questions.isEmpty {
                    Task { await loadQuestions() }
                }
            }
        }
    }
    
    private var questionView: some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                .progressViewStyle(LinearProgressViewStyle(tint: AppColors.orange))
            
            Text("第 \(currentQuestion + 1) 題，共 \(questions.count) 題")
                .font(.caption)
                .foregroundColor(AppColors.titleColor.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 12) {
                if let instructions = meta.instructions, !instructions.isEmpty {
                    Text(instructions)
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor)
                }
                
                let question = questions[currentQuestion]
                Text(question.text)
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                    .multilineTextAlignment(.leading)
            }
            
            VStack(spacing: 12) {
                ForEach(0..<options.count, id: \.self) { index in
                    let isSelected = answeredQuestions.contains(currentQuestion) && answers[currentQuestion] == optionScores[index]
                    Button(action: {
                        selectAnswer(index)
                    }) {
                        HStack {
                            Text(options[index])
                                .font(.body)
                                .foregroundColor(AppColors.titleColor)
                            Spacer()
                            Text("(\(optionScores[index])分)")
                                .font(.caption)
                                .foregroundColor(AppColors.titleColor.opacity(0.6))
                        }
                        .padding()
                        .background(isSelected ? AppColors.orange.opacity(0.18) : AppColors.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? AppColors.orange : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.1), radius: 2)
                    }
                }
            }
            
            HStack(spacing: 12) {
                Button(action: goToPreviousQuestion) {
                    Text("上一題")
                        .font(.headline)
                        .foregroundColor(currentQuestion == 0 ? AppColors.titleColor.opacity(0.35) : AppColors.titleColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                }
                .disabled(currentQuestion == 0)

                Button(action: goToNextQuestion) {
                    Text(currentQuestion == questions.count - 1 ? "確認答案" : "下一題")
                        .font(.headline)
                        .foregroundColor(canAdvanceFromCurrentQuestion ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canAdvanceFromCurrentQuestion ? AppColors.orange : AppColors.lightBrown.opacity(0.5))
                        .cornerRadius(12)
                }
                .disabled(!canAdvanceFromCurrentQuestion)
            }

            Spacer()
        }
        .padding()
        .background(AppColors.lightYellow)
        .navigationTitle(meta.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("取消") { isPresented = false })
    }

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("答案確認")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppColors.titleColor)

                Text("送出前可點選任一題返回修改。")
                    .font(.subheadline)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))

                VStack(spacing: 12) {
                    ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                        Button {
                            currentQuestion = index
                            showingReview = false
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("第 \(index + 1) 題")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(AppColors.orange)
                                Text(question.text)
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.titleColor)
                                Text(answerSummary(for: index))
                                    .font(.caption)
                                    .foregroundColor(AppColors.titleColor.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(Color.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 12) {
                    Button("返回作答") {
                        showingReview = false
                    }
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(12)

                    Button("確認送出") {
                        Task { await submitAnswers() }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppColors.orange)
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(AppColors.lightYellow)
        .navigationTitle(meta.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("取消") { isPresented = false })
    }
    
    private var completionView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                completionHeader

                if let resultText = feedbackResultText {
                    completionSectionCard(
                        title: "測驗結果",
                        content: resultSummaryText(
                            tierLabel: feedbackTierLabel,
                            totalScore: totalScore
                        ),
                        background: Color.white
                    )
                    completionSectionCard(
                        title: "測驗結果解釋",
                        content: resultText,
                        background: Color.white
                    )
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ResultExplanationHeightKey.self,
                                    value: proxy.size.height
                                )
                        }
                    )
                    .onPreferenceChange(ResultExplanationHeightKey.self) { height in
                        if height > 0, resultExplanationHeight != height {
                            resultExplanationHeight = height
                        }
                    }
                    completionSectionCard(
                        title: "分數意義",
                        content: commonFeedbackReminder,
                        background: AppColors.lightYellow.opacity(0.6),
                        shadow: false
                    )
                    completionSectionCard(
                        title: "提醒您",
                        content: commonFeedbackClosing,
                        background: AppColors.lightYellow.opacity(0.6),
                        shadow: false
                    )
                }

                Button(action: {
                    isPresented = false
                }) {
                    Text("返回")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.orange)
                        .cornerRadius(12)
                }
                .padding(.top, 6)
            }
            .padding()
        }
        .background(AppColors.lightYellow)
    }

    private var completionHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(AppColors.orange)
                        .font(.system(size: 22, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("量表完成")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppColors.titleColor)
                    Text("已記錄您的作答")
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                }
                Spacer()
            }

            HStack(spacing: 8) {
                if let tier = feedbackTierLabel {
                    completionTag(text: "等級 \(tier)")
                }
                if totalScore >= 0 {
                    completionTag(text: "總分 \(totalScore)")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }

    private func completionTag(text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundColor(AppColors.titleColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(AppColors.lightYellow.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(AppColors.lightBrown.opacity(0.35), lineWidth: 1)
                    )
            )
    }

    private func completionSectionCard(
        title: String,
        content: String,
        background: Color,
        height: CGFloat? = nil,
        shadow: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.titleColor)
            Text(content)
                .font(.subheadline)
                .foregroundColor(AppColors.titleColor.opacity(0.85))
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.lightBrown.opacity(0.25), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
        .shadow(color: .black.opacity(shadow ? 0.06 : 0.0), radius: shadow ? 6 : 0, y: shadow ? 3 : 0)
    }
    
    private func selectAnswer(_ answer: Int) {
        answers[currentQuestion] = optionScores[answer]
        answeredQuestions.insert(currentQuestion)
        advanceFromCurrentQuestion()
    }

    private func advanceFromCurrentQuestion() {
        if meta.action == .bss, currentQuestion == 4 {
            if answers.count > 4, answers[3] == 0, answers[4] == 0 {
                for skippedIndex in 5..<min(19, answers.count) {
                    answers[skippedIndex] = 0
                    answeredQuestions.insert(skippedIndex)
                }
                currentQuestion = min(19, questions.count - 1)
                return
            }
        }

        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
        } else {
            showingReview = true
        }
    }

    private func goToPreviousQuestion() {
        guard currentQuestion > 0 else { return }
        currentQuestion -= 1
    }

    private func goToNextQuestion() {
        guard canAdvanceFromCurrentQuestion else { return }
        advanceFromCurrentQuestion()
    }
    
    private func loadQuestions() async {
        isLoading = true
        errorMessage = nil

        if let local = localQuestions {
            await MainActor.run {
                self.questions = local.enumerated().map { index, question in
                    let needsReverse = question.isReverse || meta.reverseIndices.contains(index + 1)
                    return ScaleQuestion(text: question.text, isReverse: needsReverse)
                }
                self.questionIds = localQuestionIds(for: meta.code, count: local.count)
                self.answers = Array(repeating: 0, count: self.questions.count)
                self.answeredQuestions = []
                self.currentQuestion = 0
                self.showingResult = false
                self.showingReview = false
                self.showingIntro = true
                self.isLoading = false
            }
            return
        }
        
        do {
            let items = try await APIService.shared.getScaleQuestionItems(code: meta.code)
            let cleaned = items
                .map { ScaleQuestion(text: $0.text, isReverse: $0.isReverse) }
                .filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            if cleaned.isEmpty {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "沒有取得題目"
                }
                return
            }
            await MainActor.run {
                self.questions = cleaned.enumerated().map { index, question in
                    let needsReverse = question.isReverse || meta.reverseIndices.contains(index + 1)
                    return ScaleQuestion(text: question.text, isReverse: needsReverse)
                }
                self.questionIds = items
                    .sorted { $0.order < $1.order }
                    .map { $0.id }
                self.answers = Array(repeating: 0, count: self.questions.count)
                self.answeredQuestions = []
                self.currentQuestion = 0
                self.showingResult = false
                self.showingReview = false
                self.showingIntro = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func submitAnswers() async {
        guard let userId = AuthService.shared.currentUser?.primaryId, !userId.isEmpty else {
            await MainActor.run {
                self.errorMessage = "找不到使用者資訊"
                self.showingResult = false
            }
            return
        }
        
        if questionIds.count != answers.count {
            await MainActor.run {
                self.errorMessage = "題目資料異常"
                self.showingResult = false
            }
            return
        }
        
        let payload = zip(questionIds, answers).map { (id, value) in
            ScaleAnswerPayload(questionId: id, value: value)
        }
        
        do {
            try await APIService.shared.submitScaleAnswers(code: meta.code, userId: userId, answers: payload)
            await MainActor.run {
                self.showingReview = false
                self.showingResult = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "送出失敗，請重試"
                self.showingReview = true
                self.showingResult = false
            }
        }
    }

    private func answerSummary(for index: Int) -> String {
        guard answeredQuestions.contains(index) else { return "尚未作答" }
        let score = answers[index]
        if let option = scaleOptions.first(where: { $0.score == score }) {
            return "\(option.label)（\(score) 分）"
        }
        return "\(score) 分"
    }

    private var introView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("測驗前說明")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppColors.titleColor)
                    Text(meta.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                }

                if let scaleIntro = scaleIntroText(for: meta) {
                    sectionCard(title: "\(meta.title) 簡介", content: scaleIntro)
                }

                Button(action: {
                    showingIntro = false
                }) {
                    Text("開始測驗")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppColors.orange)
                        .cornerRadius(12)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(AppColors.lightYellow)
        .navigationTitle("測驗開始前")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("取消") { isPresented = false })
    }

    private func scaleIntroText(for meta: ScaleMeta) -> String? {
        switch meta.code {
        case "CESD20":
            return """
            這份量表主要了解你最近一段時間的情緒狀態，例如是否感到低落、提不起勁、疲倦，或對事情失去興趣。

            它關注的是情緒與生活感受的頻率，不是用來判定你是否「有憂鬱症」，而是幫助我們理解你目前的情緒起伏。
            """
        case "BSRS5":
            return """
            這是一份非常簡短的心理壓力量表，用來快速了解你最近是否感到緊張、煩躁、憂鬱、睡眠困擾或壓力。

            它就像一個心理狀態的溫度計，幫助我們初步掌握你目前的心理負荷程度。
            """
        case "SATS8":
            return """
            消沉傾向是指個人所存有，對人、事、世界的一種長期自我挫敗心態，包括認知、情感、行為以及人際關係等方面的消極傾向。

            這份量表以存在疏離、困竭思覺、疏忽自我照顧及關係矛盾等四構面表示之，協助我們了解你是否正處於一段心理消沉或情緒停滯的狀態。
            """
        case "AQ10":
            return """
            AQ-10（自閉症光譜量表精簡版）是一項用於初步篩檢自閉症光譜特質（Autism Spectrum Traits）的簡短工具，可協助了解個人在社交互動、溝通方式、注意力焦點與細節覺察等方面，是否呈現較明顯的自閉症光譜相關特徵。

            AQ-10 滿分為 10 分，分數越高，表示自閉症光譜特質越明顯。
            """
        case "PCS12":
            return """
            這份量表主要了解你的內在心理資源，包含四大核心要素：

            1. 自我效能（Self-efficacy）：相信自己有能力付出努力，並成功完成具挑戰性任務的自信心。
            2. 希望（Hope）：為了達成目標而堅持不懈，並在遭遇阻礙時能尋找其他替代途徑的意志力。
            3. 樂觀（Optimism）：對當前與未來的成功抱持積極、現實且正面的歸因態度。
            4. 韌性（Resilience）：面對逆境、失敗或挫折時，能夠迅速恢復、適應並超越困境的能力。
            """
        case "CDRISC25":
            return """
            這份量表聚焦於你在面對壓力、挫折或困境時，調適、恢復與重新站起來的能力。

            它不是在看你「有沒有受傷」，而是關心你「如何走過來」。
            """
        case "PANSI14":
            return """
            這份量表用來了解你是否曾出現過關於生命價值、生存意義或自我傷害的想法。

            其中也包含對生命的保護因子與正向理由的探索，目的在於更完整理解你內在的拉扯與支持力量。
            """
        case "BSS21":
            return """
            這是一份較為深入的量表，用來了解你是否曾經出現過自我傷害或結束生命的相關想法與程度。

            如果在作答過程中感到不舒服、想暫停，你可以隨時停下來或告知我們，你的感受是被尊重的。
            """
        default:
            return nil
        }
    }

    private var canAdvanceFromCurrentQuestion: Bool {
        answeredQuestions.contains(currentQuestion)
    }

    private var totalScore: Int {
        zip(answers, questions).enumerated().reduce(0) { total, pair in
            let (index, item) = pair
            let (answer, question) = item
            let scored = scoreForAnswer(answer, at: index, question: question)
            return total + scored
        }
    }

    private var options: [String] {
        scaleOptions.map { $0.label }
    }

    private var optionScores: [Int] {
        scaleOptions.map { $0.score }
    }

    private var scaleOptions: [ScaleOption] {
        switch meta.action {
        case .cesd:
            return [
                ScaleOption(label: "沒有或極少", score: 0),
                ScaleOption(label: "有時候", score: 1),
                ScaleOption(label: "時常", score: 2),
                ScaleOption(label: "常常", score: 3)
            ]
        case .bsrs5:
            return [
                ScaleOption(label: "完全沒有", score: 0),
                ScaleOption(label: "輕微", score: 1),
                ScaleOption(label: "中等程度", score: 2),
                ScaleOption(label: "厲害", score: 3),
                ScaleOption(label: "非常厲害", score: 4)
            ]
        case .sats:
            return [
                ScaleOption(label: "完全不符合", score: 1),
                ScaleOption(label: "很不符合", score: 2),
                ScaleOption(label: "大多不符合", score: 3),
                ScaleOption(label: "部分符合", score: 4),
                ScaleOption(label: "大多符合", score: 5),
                ScaleOption(label: "很符合", score: 6),
                ScaleOption(label: "完全符合", score: 7)
            ]
        case .aq10:
            return [
                ScaleOption(label: "完全同意", score: 1),
                ScaleOption(label: "稍微同意", score: 2),
                ScaleOption(label: "稍微不同意", score: 3),
                ScaleOption(label: "完全不同意", score: 4)
            ]
        case .psycap:
            return [
                ScaleOption(label: "非常不同意", score: 1),
                ScaleOption(label: "不同意", score: 2),
                ScaleOption(label: "普通", score: 3),
                ScaleOption(label: "同意", score: 4),
                ScaleOption(label: "非常同意", score: 5)
            ]
        case .cdrisc:
            return [
                ScaleOption(label: "從不", score: 0),
                ScaleOption(label: "很少", score: 1),
                ScaleOption(label: "有時", score: 2),
                ScaleOption(label: "經常", score: 3),
                ScaleOption(label: "幾乎總是", score: 4)
            ]
        case .pansi:
            return [
                ScaleOption(label: "從來沒有", score: 0),
                ScaleOption(label: "很少", score: 1),
                ScaleOption(label: "有時", score: 2),
                ScaleOption(label: "常常", score: 3),
                ScaleOption(label: "經常", score: 4)
            ]
        case .bss:
            return [
                ScaleOption(label: "無或低", score: 0),
                ScaleOption(label: "中等", score: 1),
                ScaleOption(label: "高", score: 2)
            ]
        default:
            return [
                ScaleOption(label: "完全沒有", score: 1),
                ScaleOption(label: "輕微", score: 2),
                ScaleOption(label: "中等程度", score: 3),
                ScaleOption(label: "厲害", score: 4),
                ScaleOption(label: "非常厲害", score: 5)
            ]
        }
    }

    private var optionScoreRange: (min: Int, max: Int) {
        let scores = optionScores
        return (scores.min() ?? 0, scores.max() ?? 0)
    }

    private func reverseScore(for score: Int) -> Int {
        let range = optionScoreRange
        return range.min + range.max - score
    }

    private func scoreForAnswer(_ answer: Int, at index: Int, question: ScaleQuestion) -> Int {
        switch meta.action {
        case .aq10:
            let agreeScores: Set<Int> = [1, 2]
            let disagreeScores: Set<Int> = [3, 4]
            let agreeIsAutistic = Set([1, 2, 9, 10]).contains(index + 1)
            if agreeIsAutistic {
                return agreeScores.contains(answer) ? 1 : 0
            } else {
                return disagreeScores.contains(answer) ? 1 : 0
            }
        case .bss:
            // 第20-21題不計入核心總分
            if index >= 19 { return 0 }
            return answer
        default:
            if question.isReverse {
                return reverseScore(for: answer)
            }
            return answer
        }
    }

    private var localQuestions: [ScaleQuestion]? {
        switch meta.action {
        case .cesd:
            return [
                "原來不介意的事最近竟然會困擾我",
                "我的胃口不好，不想吃東西",
                "即使有親人的幫忙，我還是無法拋開煩惱",
                "我覺得我和別人一樣好",
                "我做事時無法集中精神",
                "我覺得悶悶不樂",
                "我做任何事都覺得費力",
                "我對未來充滿希望",
                "我認為我的人生是失敗的",
                "我覺得恐懼",
                "我睡得不安寧",
                "我是快樂的",
                "我比平日不愛說話",
                "我覺得寂寞",
                "人們是不友善的",
                "我享受了生活的樂趣",
                "我曾經痛哭",
                "我覺得悲傷",
                "我覺得別人不喜歡我",
                "我缺乏幹勁"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        case .bsrs5:
            return [
                "感覺緊張不安",
                "覺得容易苦惱或動怒",
                "感覺憂鬱、心情低落",
                "覺得比不上別人",
                "睡眠困難（難入睡、易醒或早醒）"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        case .sats:
            return [
                "我心裡有空洞的感覺",
                "我無法決定我的未來",
                "面對生活，我有無力感",
                "我的生活像是掉入漩渦裡面",
                "我會沉溺在某些事情上而打亂生活作息",
                "這一段時間以來，我的生活作息混亂",
                "我對於人常常有失望的感覺",
                "和別人親近常常讓我覺得不自在"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        case .aq10:
            return [
                "我時常注意到其他人不會留意的小聲音",
                "當我在閱讀故事時，我覺得很難理解故事人物的想法或動機",
                "我可以輕易地瞭解別人跟我說話時背後的含義",
                "我常把注意力放在事物的整體多過於細節上",
                "我能意識到別人對我所說的話是否感到悶了",
                "我覺得同時進行多項任務是容易的",
                "我可以容易地憑別人的表情來理解他人的想法和情感",
                "如果我在做事時被幹擾了，可以很快地回頭做原先做的事",
                "我覺得理解別人的情緒對我來說很困難",
                "我傾向注意事情的細節而不是整體"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        case .psycap:
            return [
                "我有信心能分析長遠的問題，並找到解決的方法",
                "與主管開會時，我有信心表達自己工作範圍的事務",
                "我有信心能設定對工作領域有幫助的目標",
                "眼前我認為自己在工作上相當成功",
                "我可以想出很多方法來達到我的工作目標",
                "目前我正逐步達成自己設定的工作目標",
                "我總是會嘗試各種方法來處理難題",
                "我能獨立完成自己分內的工作",
                "在目前的工作上，我感覺自己能同時處理很多事情",
                "面對工作上的不確定性，我總是往最好的地方想",
                "在工作時，我總是看到事情的光明面",
                "對於工作上即將發生的事，我都能樂觀以對"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        case .cdrisc:
            return [
                "當改變發生時，我能適應。",
                "面臨壓力時，我至少有一個親近且安全的人際關係可以幫助我。",
                "當我的問題沒有清楚的答案時，命運或神有時會幫助我。",
                "不管發生什麼事情，我都能處理。",
                "過去的成功讓我有信心去處理新的挑戰和困難。",
                "當我面對問題時，我試著去看事情幽默的一面。",
                "克服壓力而使我更堅強。",
                "生病、受傷或苦難之後，我很容易就能恢復過來。",
                "不管好事或壞事，我相信事出必有因。",
                "不管結果如何，我都會盡最大的努力。",
                "即使有阻礙，我相信我能達成我的目標。",
                "即使看起來沒有希望了，我仍然不放棄。",
                "壓力或危機來時，我知道去哪裡尋求幫助。",
                "在壓力之下，我可以專注並且能清楚地思考。",
                "我寧願自己主導去解決問題，而不是全由別人做決定。",
                "我不會因失敗而很容易氣餒。",
                "處理生命中的挑戰和困難時，我認為我是一個堅強的人。",
                "如果有必要，我可以做一個不受歡迎或困難的決定而去影響別人。",
                "我能處理一些不愉快或痛苦的感覺，例如：悲傷、害怕和生氣。",
                "處理生活問題時，有時候必須憑直覺，而不知道為什麼要這樣做。",
                "我非常清楚我生命的意義。",
                "我覺得我可以掌握我的人生。",
                "我喜歡挑戰。",
                "不管人生的路途中遇到什麼阻礙，我會努力達成我的目標。",
                "我為我的成就而得意。"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        case .pansi:
            return [
                "因無法達成他人期望而想自殺",
                "覺得生活大部分事情可掌控",
                "對未來感到無望而想到自殺",
                "因人際關係不好希望死",
                "因無法完成重要事情想到自殺",
                "因事情發展良好而覺得有希望",
                "因無法解決問題想到自殺",
                "因工作或學校表現好而高興",
                "覺得自己是失敗者而想到自殺",
                "覺得自殺是唯一解決方法",
                "因孤單或難過想到自殺",
                "對自己處理問題能力有信心",
                "覺得生存有意義",
                "對未來計畫有信心"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        case .bss:
            return [
                "求生意願",
                "求死意願",
                "求生與求死理由",
                "自殺慾望",
                "面臨生命威脅時的態度",
                "自殺念頭持續時間",
                "自殺念頭頻率",
                "對自殺觀念態度",
                "自殺控制能力",
                "自殺顧慮",
                "自殺動機",
                "自殺計畫",
                "自殺方法取得",
                "自殺能力",
                "自殺嘗試意圖",
                "自殺準備",
                "遺書",
                "自殺事後安排",
                "隱瞞自殺意圖",
                "過去自殺企圖",
                "上次企圖自殺時求死意願"
            ].map { ScaleQuestion(text: $0, isReverse: false) }
        default:
            return nil
        }
    }

    private func localQuestionIds(for code: String, count: Int) -> [String] {
        let prefix: String
        switch code {
        case "CESD20": prefix = "cesd"
        case "BSRS5": prefix = "bsrs"
        case "SATS8": prefix = "sats"
        case "AQ10": prefix = "aq"
        case "PCS12": prefix = "pcs"
        case "CDRISC25": prefix = "cdr"
        case "PANSI14": prefix = "pansi"
        case "BSS21": prefix = "bss"
        default:
            prefix = code.lowercased()
        }
        return (0..<count).map { "\(prefix)_\($0 + 1)" }
    }

    private var feedbackResultText: String? {
        guard let tier = feedbackTier(for: totalScore, code: meta.code) else {
            return nil
        }
        return feedbackText(for: tier, code: meta.code)
    }

    private func feedbackTier(for score: Int, code: String) -> FeedbackTier? {
        guard let range = scoreRanges[code] else { return nil }
        if score <= range.lowMax { return .low }
        if score <= range.midMax { return .medium }
        return .high
    }

    private var feedbackTierLabel: String? {
        guard let tier = feedbackTier(for: totalScore, code: meta.code) else { return nil }
        if meta.code == "CESD20" {
            switch tier {
            case .low, .medium: return "常模內（≤11）"
            case .high: return "高於常模（>11）"
            }
        } else {
            switch tier {
            case .low: return "低分"
            case .medium: return "中分"
            case .high: return "高分"
            }
        }
    }

    private var feedbackTierColor: Color {
        guard let tier = feedbackTier(for: totalScore, code: meta.code) else { return AppColors.orange }
        switch tier {
        case .low: return Color.green.opacity(0.7)
        case .medium: return Color.orange.opacity(0.8)
        case .high: return Color.red.opacity(0.75)
        }
    }

    private func feedbackText(for tier: FeedbackTier, code: String) -> String {
        switch code {
        case "CESD20":
            switch tier {
            case .low:
                return "你的分數落在常模範圍內（≤11），目前沒有顯著的憂鬱警訊。請持續留意情緒與生活作息。"
            case .medium:
                return "你的分數落在常模範圍內（≤11），目前沒有顯著的憂鬱警訊。請持續留意情緒與生活作息。"
            case .high:
                return "你的分數高於常模（>11）。建議進一步評估憂鬱的可能性，並尋求身心健康專業人員的協助（如學校輔導人員、心理師、精神醫療院所）。"
            }
        case "BSRS5":
            switch tier {
            case .low:
                return "目前你的心理壓力程度偏低，身心狀態大致穩定，能夠應付日常生活。"
            case .medium:
                return "你可能正在承受一定程度的心理壓力，身心已有一些提醒訊號。適時休息、調整節奏，對你會有所幫助。"
            case .high:
                return "你的心理負荷目前較重，這表示你已經努力撐了一段時間。尋求支持並不是脆弱，而是一種照顧自己的方式。"
            }
        case "SATS8":
            return """
            消沉指數愈高可能表示你對於存在意義感到迷惑、有空虛感，面對壓力時容易有既困頓又耗竭的思想與感覺，在基本生活要求上疏忽或無力因應，在人際關係中隱藏自己的想法、討好他人，或者對於關係的經營過於被動與逃避。這意謂著是時候需要別人來關心、幫助你了。建議找人談談、尋求專業人士（如心理師、輔導人員、精神醫療部門）協助。另外，也可以閱讀心靈提升書籍、增加生活接觸面、參與人際社交活動等。
            """
        case "AQ10":
            switch tier {
            case .low:
                return """
                0–5 分：自閉症光譜特質較低

                此分數範圍表示受測者的自閉症光譜特質大致落在一般範圍內，出現自閉症光譜特徵的可能性相對較低。
                """
            case .medium:
                return """
                6–10 分：建議進一步專業評估

                若分數達 6 分以上，表示受測者可能具有較多與自閉症光譜相關的特質。然而，AQ-10 僅能作為初步篩檢工具，不能作為正式診斷依據。量表結果僅供參考，實際情況仍需結合個人發展史、日常功能、人際互動表現與專業臨床評估進行判斷。
                """
            case .high:
                return """
                6–10 分：建議進一步專業評估

                若分數達 6 分以上，表示受測者可能具有較多與自閉症光譜相關的特質。然而，AQ-10 僅能作為初步篩檢工具，不能作為正式診斷依據。量表結果僅供參考，實際情況仍需結合個人發展史、日常功能、人際互動表現與專業臨床評估進行判斷。
                """
            }
        case "PCS12":
            switch tier {
            case .low:
                return "目前你感受到的內在心理資源較少，可能覺得缺乏希望感或自信。這並非能力不足，而是你可能需要更多支持與補充。"
            case .medium:
                return "你擁有部分心理資源，在某些情境中能支持自己，但在壓力下仍會感到動搖。"
            case .high:
                return "你擁有較多正向心理資源，在面對困難時，能較容易相信自己並持續前行。"
            }
        case "CDRISC25":
            switch tier {
            case .low:
                return "你近期面對的壓力可能已超過負荷，復原與調適的能量暫時較低。這不代表你不夠堅強，而是你已經撐很久了。"
            case .medium:
                return "你具備一定程度的復原能力，但在長期壓力下仍需要更多支持。"
            case .high:
                return "你展現出良好的復原能力，即使面對困難，也有機會逐步調整並重新站穩。"
            }
        case "PANSI14":
            switch tier {
            case .low:
                return "你的結果顯示，你心中仍保有支持自己活下去的理由與力量。"
            case .medium:
                return "你可能正經歷一些內在拉扯，一方面感到痛苦，一方面仍有牽掛與支持力量。"
            case .high:
                return "你近期可能承受相當程度的心理痛苦，這是一個非常重要、需要被關心的訊號。你不需要獨自承擔這些感受。"
            }
        case "BSS21":
            switch tier {
            case .low:
                return "目前你較少出現與自我傷害相關的想法。"
            case .medium:
                return "你可能偶爾出現關於生命或自我傷害的想法，這代表你正在面對一些不容易的情緒。"
            case .high:
                return "你可能正承受非常大的痛苦。請記得，尋求專業或可信任的人協助，是一種保護自己、而非失敗的行動。"
            }
        default:
            return ""
        }
    }

    private var commonFeedbackReminder: String {
        "以上回饋僅反映你近期一段時間的狀態，並非診斷。你可持續檢測，觀察自己的變化。"
    }

    private var commonFeedbackClosing: String {
        "無論結果如何，你的感受都是真實且值得被重視的。理解自己，是改變與照顧自己的第一步。"
    }

    private enum FeedbackTier {
        case low
        case medium
        case high
    }

    private struct ScoreRange {
        let lowMax: Int
        let midMax: Int
    }

    private var scoreRanges: [String: ScoreRange] {
        [
            "CESD20": ScoreRange(lowMax: 11, midMax: 11),
            "BSRS5": ScoreRange(lowMax: 11, midMax: 18),
            "SATS8": ScoreRange(lowMax: 23, midMax: 37),
            "AQ10": ScoreRange(lowMax: 5, midMax: 5),
            "PCS12": ScoreRange(lowMax: 28, midMax: 44),
            "CDRISC25": ScoreRange(lowMax: 58, midMax: 92),
            "PANSI14": ScoreRange(lowMax: 15, midMax: 31),
            "BSS21": ScoreRange(lowMax: 5, midMax: 19)
        ]
    }

    private func sectionCard(
        title: String,
        content: String,
        background: Color = AppColors.cardBackground,
        height: CGFloat? = nil,
        shadow: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.titleColor)
            Text(content)
                .font(.subheadline)
                .foregroundColor(AppColors.titleColor.opacity(0.85))
                .lineSpacing(4)
        }
        .padding(16)
        .background(background)
        .cornerRadius(14)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .leading)
        .shadow(color: .black.opacity(shadow ? 0.05 : 0.0), radius: shadow ? 5 : 0, y: shadow ? 3 : 0)
    }

    private func resultSummaryText(tierLabel: String?, totalScore: Int) -> String {
        var lines: [String] = []
        if let tierLabel {
            lines.append("等級：\(tierLabel)")
        }
        if totalScore >= 0 {
            lines.append("總分 \(totalScore)")
        }
        if lines.isEmpty {
            return "尚無分數資訊"
        }
        return lines.joined(separator: "\n")
    }

    private struct ResultExplanationHeightKey: PreferenceKey {
        static var defaultValue: CGFloat = 0

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            let next = nextValue()
            if next > 0 {
                value = next
            }
        }
    }
}

#Preview {
    ScaleTestView(
        meta: ScaleMeta(
            action: .cesd,
            code: "CESD20",
            title: "CES-D 憂鬱量表",
            questionCount: 20,
            instructions: "請依「過去一週內」的情形作答",
            reverseIndices: [4, 8, 12, 16]
        ),
        isPresented: .constant(true)
    )
}
