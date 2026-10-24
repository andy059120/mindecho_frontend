import SwiftUI

struct DailyCheckInView: View {
    @Binding var isPresented: Bool
    @State private var currentQuestion = 0
    @State private var answers: [Int] = Array(repeating: -1, count: 5) // -1 表示未選擇
    @State private var showingResult = false
    @State private var isFirstQuestion = true
    @State private var calculatedScores: DailyCheckInScores? // 新增：保存計算結果
    
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    
    let questions = HomeConstants.DailyCheckIn.questions
    let moodOptions = HomeConstants.DailyCheckIn.moodOptions
    
    var body: some View {
        NavigationView {
            if showingResult, let scores = calculatedScores {
                DailyCheckInResultView(
                    scores: scores, // 使用已計算的分數
                    isPresented: $isPresented
                )
            } else if isFirstQuestion {
                welcomeView
            } else {
                questionView
            }
        }
    }
    
    // MARK: - 歡迎頁面
    private var welcomeView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // 裝飾方框
            VStack(spacing: 32) {
                // 標題區塊
                VStack(spacing: 12) {
                    Text("每日檢測")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                    
                    Text("花一分鐘記錄今天的狀態，幫助你更好地了解自己的健康趨勢。")
                        .font(.body)
                        .foregroundColor(AppColors.titleColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 24)
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8)
                
                // 開始按鈕
                Button(action: {
                    withAnimation(.easeInOut(duration: HomeConstants.Animation.cardAppearDuration)) {
                        isFirstQuestion = false
                    }
                }) {
                    Text("開始檢測")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColors.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 12)
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.lightYellow)
        .navigationBarItems(trailing: Button("關閉") { isPresented = false })
    }
    
    // MARK: - 問題頁面
    private var questionView: some View {
        VStack(spacing: 0) {
            // 進度條
            VStack(spacing: 8) {
                ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: AppColors.orange))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("問題\(currentQuestion + 1)/\(questions.count)")
                    .font(.caption)
                    .foregroundColor(AppColors.orange)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
            
            Spacer()
            
            // 問題卡片
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text(questions[currentQuestion].title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppColors.titleColor)
                        .multilineTextAlignment(.center)
                    
                    Text(questions[currentQuestion].subtitle)
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                
                // 情緒選項
                HStack(spacing: 12) {
                    ForEach(0..<moodOptions.count, id: \.self) { index in
                        MoodButton(
                            option: moodOptions[index],
                            isSelected: answers[currentQuestion] == index,
                            onTap: {
                                selectAnswer(index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                
                // 導航按鈕（保留上一題）
                if currentQuestion > 0 {
                    HStack(spacing: 16) {
                        Button(action: previousQuestion) {
                            Text("上一題")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppColors.titleColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AppColors.lightYellow)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(AppColors.titleColor, lineWidth: 1)
                                )
                        }
                        .transition(.slide)
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 20)
                }
            }
            .padding(.vertical, 32)
            .background(AppColors.cardBackground)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8)
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(AppColors.lightYellow)
        .navigationBarItems(trailing: Button("關閉") { isPresented = false })
    }
    
    // MARK: - 私有方法
    private func selectAnswer(_ index: Int) {
        withAnimation(.easeInOut(duration: HomeConstants.Animation.moodSelectionDuration)) {
            answers[currentQuestion] = index
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            nextQuestion()
        }
    }
    
    private func previousQuestion() {
        withAnimation(.easeInOut(duration: HomeConstants.Animation.cardAppearDuration)) {
            if currentQuestion > 0 {
                currentQuestion -= 1
            }
        }
    }
    
    private func nextQuestion() {
        withAnimation(.easeInOut(duration: HomeConstants.Animation.cardAppearDuration)) {
            if currentQuestion < questions.count - 1 {
                currentQuestion += 1
            } else {
                handleCompletion()
            }
        }
    }

    private func handleCompletion() {
        // 計算分數並保存（只執行一次）
        let scores = calculateScores()
        calculatedScores = scores
        checkInManager.saveDailyCheckIn(scores: scores)

        // 送出問卷回答（數字分數）並記錄 log（配合後端確認）
        let answerValues = answers.map { idx in
            idx >= 0 && idx < moodOptions.count ? (idx + 1) : 0
        }
        print("🟢 DailyCheckIn: sending dailyQuestions payload")
        checkInManager.sendDailyQuestions(
            questions: questions.map { $0.title },
            answers: answerValues,
            date: scores.date
        )

        showingResult = true
    }
    
    private func calculateScores() -> DailyCheckInScores {
        return DailyCheckInScores(
            physical: answers[0] + 1,
            mental: answers[1] + 1,
            emotional: answers[2] + 1,
            sleep: answers[3] + 1,
            appetite: answers[4] + 1,
            date: Date()
        )
    }
}

// MARK: - 情緒按鈕
struct MoodButton: View {
    let option: MoodOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onTap) {
                VStack(spacing: 6) {
                    Text(option.emoji)
                        .font(.system(size: 32))
                    
                    Text(option.label)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.titleColor)
                }
                .frame(width: 60, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? AppColors.orange.opacity(0.2) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? AppColors.orange : Color.gray.opacity(0.3),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: HomeConstants.Animation.moodSelectionDuration), value: isSelected)
        }
    }
}

#Preview {
    DailyCheckInView(isPresented: .constant(true))
}
