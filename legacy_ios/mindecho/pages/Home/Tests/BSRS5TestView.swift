import SwiftUI

struct BSRS5TestView: View {
    @Binding var isPresented: Bool
    @State private var currentQuestion = 0
    @State private var answers: [Int] = Array(repeating: 0, count: 5)
    @State private var showingResult = false
    
    let questions = [
        "感到緊張、焦慮或不安",
        "感到情緒低落、心情不好",
        "覺得容易生氣或煩躁",
        "感到睡眠困難（難以入睡、易醒或睡不好）",
        "覺得生活壓力很大、事情變得困難"
    ]
    
    let options = ["完全沒有", "輕微", "中等程度", "厲害", "非常厲害"]
    
    var body: some View {
        NavigationView {
            if showingResult {
                BSRS5ResultView(score: calculateScore(), isPresented: $isPresented)
            } else {
                VStack(spacing: 20) {
                    ProgressView(value: Double(currentQuestion + 1), total: Double(questions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppColors.orange))
                    
                    Text("第 \(currentQuestion + 1) 題，共 \(questions.count) 題")
                        .font(.caption)
                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("在過去一週內，您有多常被以下的問題所困擾：")
                            .font(.subheadline)
                            .foregroundColor(AppColors.titleColor)
                        
                        Text(questions[currentQuestion])
                            .font(.headline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(0..<options.count, id: \.self) { index in
                            Button(action: {
                                selectAnswer(index)
                            }) {
                                HStack {
                                    Text(options[index])
                                        .font(.body)
                                        .foregroundColor(AppColors.titleColor)
                                    Spacer()
                                    Text("(\(index)分)")
                                        .font(.caption)
                                        .foregroundColor(AppColors.titleColor.opacity(0.6))
                                }
                                .padding()
                                .background(AppColors.cardBackground)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.1), radius: 2)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(AppColors.lightYellow)
                .navigationTitle("BSRS-5簡式健康量表")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(trailing: Button("取消") { isPresented = false })
            }
        }
    }
    
    private func selectAnswer(_ answer: Int) {
        answers[currentQuestion] = answer
        
        if currentQuestion < questions.count - 1 {
            currentQuestion += 1
        } else {
            showingResult = true
        }
    }
    
    private func calculateScore() -> Int {
        return answers.reduce(0, +)
    }
}

#Preview {
    BSRS5TestView(isPresented: .constant(true))
}
