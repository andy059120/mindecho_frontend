import SwiftUI

struct RFQ8TestView: View {
    @Binding var isPresented: Bool
    @State private var showingIntro = true
    @State private var currentQuestion = 0
    @State private var answers: [Int] = Array(repeating: 0, count: 8)
    @State private var answeredQuestions = Set<Int>()
    @State private var showingResult = false
    @State private var showingReview = false
    
    let questions = [
        "我不總是知道我做一件事情背後的原因", // 題目1 - RFQ-C
        "我在生氣時會說出讓自己後悔的話", // 題目2 - RFQ-C & RFQ-U
        "缺乏安全感時會做出令人厭煩的行為", // 題目3 - RFQ-C
        "有時不知道自己行為原因", // 題目4 - RFQ-C & RFQ-U
        "他人的想法對我來說是神秘的", // 題目5 - RFQ-C & RFQ-U
        "生氣時會說出欠缺思考的話", // 題目6 - RFQ-C & RFQ-U
        "我總是知道自己內心的感受", // 題目7 - RFQ-U (反向計分)
        "強烈情緒會阻礙我的思考" // 題目8 - RFQ-U
    ]
    
    let options = ["非常不同意", "很不同意", "有點不同意", "普通", "有點同意", "很同意", "完全同意"]
    
    var body: some View {
        NavigationView {
            if showingResult {
                RFQ8ResultView(
                    rfqCScore: calculateRFQCScore(),
                    rfqUScore: calculateRFQUScore(),
                    isPresented: $isPresented
                )
            } else if showingIntro {
                introView
            } else if showingReview {
                reviewView
            } else {
                VStack(spacing: 20) {
                    ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.orange))
                    
                    Text("第 \(currentQuestion + 1) 題，共 \(questions.count) 題")
                        .font(.caption)
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("請根據您的實際情況選擇最符合的選項：")
                            .font(.subheadline)
                            .foregroundColor(AppColors.titleColor)
                        
                        Text(questions[currentQuestion])
                            .font(.headline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(0..<options.count, id: \.self) { index in
                                let isSelected = answeredQuestions.contains(currentQuestion) && answers[currentQuestion] == index
                                Button(action: {
                                    selectAnswer(index)
                                }) {
                                    HStack {
                                        Text(options[index])
                                            .font(.body)
                                            .foregroundColor(AppColors.titleColor)
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            if isRFQCQuestion(currentQuestion) {
                                                Text("C:\(getRFQCScore(for: index))")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                            }
                                            if isRFQUQuestion(currentQuestion) {
                                                Text("U:\(getRFQUScore(for: index, questionIndex: currentQuestion))")
                                                    .font(.caption)
                                                    .foregroundColor(AppColors.titleColor.opacity(0.6))
                                            }
                                        }
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
                    }

                    HStack(spacing: 12) {
                        Button("上一題") {
                            guard currentQuestion > 0 else { return }
                            currentQuestion -= 1
                        }
                        .font(.headline)
                        .foregroundColor(currentQuestion == 0 ? AppColors.titleColor.opacity(0.35) : AppColors.titleColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white)
                        .cornerRadius(12)
                        .disabled(currentQuestion == 0)

                        Button(currentQuestion == questions.count - 1 ? "確認答案" : "下一題") {
                            guard canAdvanceFromCurrentQuestion else { return }
                            goToNextQuestion()
                        }
                        .font(.headline)
                        .foregroundColor(canAdvanceFromCurrentQuestion ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canAdvanceFromCurrentQuestion ? AppColors.orange : AppColors.lightBrown.opacity(0.5))
                        .cornerRadius(12)
                        .disabled(!canAdvanceFromCurrentQuestion)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(AppColors.lightYellow)
                .navigationTitle("RFQ-8 心智化量表 (Reflective Functioning Questionnaire-8)")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("取消") { isPresented = false })
            }
        }
    }

    private var introView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("測驗前說明")
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppColors.titleColor)
                    Text("RFQ-8 心智化量表")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                }

                introCard(
                    title: "RFQ-8 心智化量表簡介",
                    content: """
                    這份量表主要在了解你如何理解自己與他人的內在狀態，例如情緒、想法、動機與行為背後的原因。

                    所謂「心智化」，是指一個人能不能在互動中意識到：自己和他人都有各自的感受、想法與觀點，而且這些內在經驗會影響行為。

                    這份量表不是在判斷你好不好，而是幫助我們理解：當情緒變強、關係變複雜時，你通常會怎麼理解自己和別人。
                    """
                )

                introCard(
                    title: "安心提醒",
                    content: HomeConstants.Tests.sharedClosingText
                )

                Button("開始測驗") {
                    showingIntro = false
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.orange)
                .cornerRadius(12)
            }
            .padding()
        }
        .background(AppColors.lightYellow)
        .navigationTitle("測驗開始前")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("取消") { isPresented = false })
    }

    private var reviewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("答案確認")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppColors.titleColor)
                Text("送出前可返回修改任一題。")
                    .font(.subheadline)
                    .foregroundColor(AppColors.titleColor.opacity(0.7))

                ForEach(Array(questions.enumerated()), id: \.offset) { index, question in
                    Button {
                        currentQuestion = index
                        showingReview = false
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("第 \(index + 1) 題")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(AppColors.orange)
                            Text(question)
                                .font(.subheadline)
                                .foregroundColor(AppColors.titleColor)
                            Text(answeredQuestions.contains(index) ? options[answers[index]] : "尚未作答")
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
        .navigationTitle("RFQ-8 心智化量表 (Reflective Functioning Questionnaire-8)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button("取消") { isPresented = false })
    }
    
    // 判斷是否為RFQ-C題目 (題目1,2,3,4,5,6 對應索引0,1,2,3,4,5)
    private func isRFQCQuestion(_ questionIndex: Int) -> Bool {
        return questionIndex <= 5
    }
    
    // 判斷是否為RFQ-U題目 (題目2,4,5,6,7,8 對應索引1,3,4,5,6,7)
    private func isRFQUQuestion(_ questionIndex: Int) -> Bool {
        let rfqUIndices = [1, 3, 4, 5, 6, 7]
        return rfqUIndices.contains(questionIndex)
    }
    
    // RFQ-C評分：3, 2, 1, 0, 0, 0, 0
    private func getRFQCScore(for optionIndex: Int) -> Int {
        let rfqCScores = [0, 0, 0, 0, 1, 2, 3]
        return rfqCScores[optionIndex]
    }
    
    // RFQ-U評分：0, 0, 0, 0, 1, 2, 3
    private func getRFQUScore(for optionIndex: Int, questionIndex: Int) -> Int {
        let rfqUReverseScores = [3, 2, 1, 0, 0, 0, 0]
        let rfqUScores = [0, 0, 0, 0, 1, 2, 3]

        if questionIndex == 6 {
            return rfqUScores[optionIndex]
        }
        return rfqUReverseScores[optionIndex]
    }
    
    private func selectAnswer(_ answer: Int) {
        answers[currentQuestion] = answer
        answeredQuestions.insert(currentQuestion)
        goToNextQuestion()
    }

    private func goToNextQuestion() {
        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
        } else {
            showingReview = true
        }
    }

    private func submitAnswers() async {
        guard let userId = AuthService.shared.currentUser?.primaryId, !userId.isEmpty else {
            showingResult = true
            return
        }

        let answerPayloads = answers.enumerated().map { index, value in
            ScaleAnswerPayload(questionId: "rfq_\(index + 1)", value: value)
        }

        do {
            try await APIService.shared.submitScaleAnswers(code: "RFQ8", userId: userId, answers: answerPayloads)
        } catch {
            // 送出失敗時仍顯示結果，避免阻塞體驗
            print("RFQ8 submit failed: \(error.localizedDescription)")
        }
        showingReview = false
        showingResult = true
    }
    
    private func calculateRFQCScore() -> Int {
        var score = 0
        for i in 0..<answers.count {
            if isRFQCQuestion(i) {
                score += getRFQCScore(for: answers[i])
            }
        }
        return score
    }
    
    private func calculateRFQUScore() -> Int {
        var score = 0
        for i in 0..<answers.count {
            if isRFQUQuestion(i) {
                score += getRFQUScore(for: answers[i], questionIndex: i)
            }
        }
        return score
    }

    private var canAdvanceFromCurrentQuestion: Bool {
        answeredQuestions.contains(currentQuestion)
    }

    private func introCard(title: String, content: String) -> some View {
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppColors.lightBrown.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

#Preview {
    RFQ8TestView(isPresented: .constant(true))
}
