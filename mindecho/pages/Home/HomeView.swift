import SwiftUI

struct HomeView: View {
    // MARK: - State 屬性
    @State private var selectedTimePeriod = "本週"
    @State private var animationProgress: Double = 0
    @State private var showingDailyCheckIn = false
    @State private var showingDiary = false
    @State private var hasWrittenDiaryToday: Bool? = nil
    @State private var todayDiaryEntry: DiaryEntry?
    @State private var homeDiaryText: String = ""
    @State private var isSavingHomeDiary = false
    @State private var homeDiaryMessage: String?
    @State private var homeDiaryError: String?
    @State private var homeSelectedMood: String? = MoodCatalog.defaultCode
    @State private var diaryRefreshToken = UUID()
    @State private var showingHomeDiarySuccessPage = false
    
    private let homeDiaryDraftKey = "mindecho_home_diary_draft"

    private let homeMoods = MoodCatalog.all
    
    // MARK: - Observable Objects
    @ObservedObject private var checkInManager = DailyCheckInManager.shared
    @EnvironmentObject private var tabTourState: TabTourState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    homeHeader
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    // 五項指標追蹤
                    VStack {
                        FiveIndicatorsCard(selectedTimePeriod: $selectedTimePeriod)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        
                        DailyScoresTableCard(
                            scores: checkInManager.weeklyScores
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        
                        Spacer()
                    }
                    
                    // 今日提醒
                    DailyReminderCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    
                    // 每日檢測提醒（如果還沒完成）
                    if !checkInManager.hasCompletedToday {
                        DailyCheckInReminderCard(onTap: {
                            showingDailyCheckIn = true
                        })
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    if hasWrittenDiaryToday == false {
                        DiaryReminderCard(onTap: {
                            showingDiary = true
                        })
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    
                    Spacer().frame(height: 24)
                    
                    // 心理測驗區塊
                    PsychologicalTestsSection()
                        .padding(.top, 20)
                    
                    // 快捷入口
                    QuickAccessSection()
                        .padding(.top, 20)
                        .padding(.bottom, 20)
                    
                    // 心理健康資源區塊
                    MentalHealthResourcesSection()
                        .padding(.top, 20)

                    homeDiaryQuickEntry
                        .padding(.top, 20)
                        .padding(.bottom, 28)
                }
            }
            .background(AppColors.lightYellow)
            .onAppear {
                checkInManager.loadDataFromAPI()
                restoreHomeDiaryDraftIfNeeded()
                Task { await loadDiaryStatus() }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                // 觸發動畫
                withAnimation(.easeInOut(duration: HomeConstants.Animation.biorhythmAnimationDuration)) {
                    animationProgress = 1.0
                }
            }
        }
        .sheet(isPresented: $showingDailyCheckIn) {
            DailyCheckInView(isPresented: $showingDailyCheckIn)
        }
        .sheet(isPresented: $showingDiary) {
            NavigationView {
                MoodDiaryView(refreshToken: diaryRefreshToken, initialSelectedDate: Date())
            }
        }
        .fullScreenCover(isPresented: $showingHomeDiarySuccessPage) {
            HomeDiarySaveSuccessView(
                title: homeDiarySuccessTitle,
                message: homeDiarySuccessMessage,
                onDone: {
                    showingHomeDiarySuccessPage = false
                }
            )
        }
    }

    private var homeDiaryQuickEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("寫日記")
                    .font(.headline)
                    .foregroundColor(AppColors.titleColor)
                Spacer()
                if isSavingHomeDiary {
                    Text("儲存中...")
                        .font(.caption)
                        .foregroundColor(AppColors.titleColor.opacity(0.6))
                }
            }
            Text("可以寫關於你今天發生的事，或是心情……")
                .font(.caption)
                .foregroundColor(AppColors.titleColor.opacity(0.55))

            ZStack(alignment: .topLeading) {
                if homeDiaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("開始寫下你的心情…")
                        .font(.subheadline)
                        .foregroundColor(AppColors.titleColor.opacity(0.45))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $homeDiaryText)
                    .frame(height: 120)
                    .padding(10)
                    .foregroundColor(AppColors.titleColor)
                    .disabled(isSavingHomeDiary)
                    .onChange(of: homeDiaryText) { _, newText in
                        saveHomeDiaryDraft(content: newText, mood: homeSelectedMood)
                    }
                    .background(Color.white)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(AppColors.lightBrown.opacity(0.4), lineWidth: 1)
                    )
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("今天的心情")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppColors.titleColor)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(homeMoods) { mood in
                            Button {
                                homeSelectedMood = mood.code
                            } label: {
                                VStack(spacing: 4) {
                                    Text(mood.emoji)
                                        .font(.title2)
                                    Text(mood.label)
                                        .font(.caption)
                                        .foregroundColor(AppColors.titleColor)
                                }
                                .frame(width: 70, height: 78)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(homeSelectedMood == mood.code
                                              ? AppColors.resourceCardYellow.opacity(0.6)
                                              : Color.white)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    homeSelectedMood == mood.code
                                                    ? AppColors.orange
                                                    : AppColors.lightBrown.opacity(0.35),
                                                    lineWidth: 1.5
                                                )
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isSavingHomeDiary)
                        }
                    }
                }
                .onChange(of: homeSelectedMood) { _, newMood in
                    saveHomeDiaryDraft(content: homeDiaryText, mood: newMood)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppColors.lightYellow.opacity(0.5))
                )
            }

            Button {
                Task { await saveHomeDiaryEntry() }
            } label: {
                HStack(spacing: 8) {
                    if isSavingHomeDiary {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    }
                    Text(isSavingHomeDiary ? "儲存中..." : "儲存日記")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppColors.orange)
                .cornerRadius(12)
            }
            .disabled(isSavingHomeDiary)
            
            if let homeDiaryMessage {
                Text(homeDiaryMessage)
                    .font(.caption)
                    .foregroundColor(.green)
            }
            if let homeDiaryError {
                Text(homeDiaryError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.985, green: 0.965, blue: 0.94))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal, 16)
    }
    
    private var homeHeader: some View {
        ZStack {
            Text("首頁")
                .font(.title2.weight(.bold))
                .foregroundColor(AppColors.titleColor)

            HStack {
                Spacer()
                Button("功能介紹") {
                    tabTourState.step = .home
                    tabTourState.isActive = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppColors.orange)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
    }


    // MARK: - 私有方法
    private func loadDiaryStatus() async {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let end = calendar.date(byAdding: .second, value: -1, to: nextDay) ?? start
        
        do {
            let entries = try await APIService.shared.getDiaryEntries(
                startDate: start,
                endDate: end
            )
            let latest = entries.max { lhs, rhs in
                let l = parseISODate(lhs.updatedAt) ?? parseISODate(lhs.createdAt)
                let r = parseISODate(rhs.updatedAt) ?? parseISODate(rhs.createdAt)
                return (l ?? .distantPast) < (r ?? .distantPast)
            }
            hasWrittenDiaryToday = !(latest == nil)
            todayDiaryEntry = latest
            if let entry = latest {
                if homeDiaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   let content = entry.content {
                    homeDiaryText = content
                }
                if let mood = entry.mood {
                    homeSelectedMood = mood
                }
            }
        } catch {
            hasWrittenDiaryToday = nil
            todayDiaryEntry = nil
        }
    }

    private func saveHomeDiaryDraft(content: String, mood: String?) {
        let draft = HomeDiaryDraft(content: content, mood: mood)
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: homeDiaryDraftKey)
        }
    }

    private func clearHomeDiaryDraft() {
        UserDefaults.standard.removeObject(forKey: homeDiaryDraftKey)
    }

    private func restoreHomeDiaryDraftIfNeeded() {
        guard let data = UserDefaults.standard.data(forKey: homeDiaryDraftKey),
              let draft = try? JSONDecoder().decode(HomeDiaryDraft.self, from: data) else {
            return
        }
        if homeDiaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            homeDiaryText = draft.content
        }
        homeSelectedMood = draft.mood ?? homeSelectedMood
        if homeDiaryMessage == nil {
            homeDiaryMessage = "已恢復未送出的日記草稿"
        }
    }

    private func saveHomeDiaryEntry() async {
        let content = homeDiaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            await MainActor.run {
                homeDiaryError = "請先輸入內容"
                homeDiaryMessage = nil
            }
            return
        }

        await MainActor.run {
            isSavingHomeDiary = true
            homeDiaryError = nil
            homeDiaryMessage = nil
        }

        guard let mood = homeSelectedMood else {
            await MainActor.run {
                homeDiaryError = "請先選擇心情"
                homeDiaryMessage = nil
                isSavingHomeDiary = false
            }
            return
        }
        do {
            let saved = try await APIService.shared.saveDiaryEntry(
                existingId: todayDiaryEntry?.id,
                content: content,
                mood: mood,
                entryDate: Date()
            )
            await MainActor.run {
                let wasUpdating = todayDiaryEntry != nil
                todayDiaryEntry = saved
                hasWrittenDiaryToday = true
                homeDiaryText = content
                homeSelectedMood = mood
                homeDiaryMessage = wasUpdating ? "已更新今日日記" : "已儲存今日日記"
                diaryRefreshToken = UUID()
                showingHomeDiarySuccessPage = true
            }
            clearHomeDiaryDraft()
        } catch {
            await MainActor.run {
                saveHomeDiaryDraft(content: content, mood: mood)
                if let urlError = error as? URLError,
                   urlError.code == .userAuthenticationRequired {
                    homeDiaryError = "登入已過期，草稿已保留，請重新登入後再送出"
                } else {
                    homeDiaryError = "儲存失敗，草稿已保留，請稍後再試"
                }
            }
        }

        await MainActor.run {
            isSavingHomeDiary = false
        }
    }

    private var homeDiarySuccessTitle: String {
        "今天的紀錄已完成"
    }

    private var homeDiarySuccessMessage: String {
        "日記已成功儲存"
    }

    private func parseISODate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

private struct HomeDiaryDraft: Codable {
    let content: String
    let mood: String?
}

private struct HomeDiarySaveSuccessView: View {
    let title: String
    let message: String
    let onDone: () -> Void

    var body: some View {
        ZStack {
            AppColors.lightYellow
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 72))
                        .foregroundColor(AppColors.orange)

                    Text(title)
                        .font(.title2.weight(.bold))
                        .foregroundColor(AppColors.titleColor)

                    Text(message)
                        .font(.body)
                        .foregroundColor(AppColors.titleColor.opacity(0.75))
                        .multilineTextAlignment(.center)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 14, y: 8)
                )
                .padding(.horizontal, 24)

                Spacer()

                Button("完成") {
                    onDone()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.orange)
                .cornerRadius(14)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(TabTourState.shared)
}
