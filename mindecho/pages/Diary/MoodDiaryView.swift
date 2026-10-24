//
//  MoodDiaryView.swift
//  mindecho
//
//  Created by 陳敬翰 on 2025/9/26.
//
import SwiftUI

struct MoodDiaryView: View {
    let refreshToken: UUID
    let initialSelectedDate: Date
    @State private var selectedDate = Date()
    @State private var selectedMood: String? = nil
    @State private var diaryText: String = ""   // 用來存放日記內容
    @State private var isSaving = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var entriesByDay: [Date: DiaryEntryViewData] = [:]
    @State private var loadedMonthStart: Date?
    @State private var showingHistory = false
    @State private var showingSaveSuccessPage = false
    @State private var hasUnsavedChanges = false
    @FocusState private var isDiaryEditorFocused: Bool
    @EnvironmentObject private var mainTabState: MainTabState
    @Environment(\.dismiss) private var dismiss
    
    let moods = MoodCatalog.all

    init(refreshToken: UUID = UUID(), initialSelectedDate: Date = Date()) {
        self.refreshToken = refreshToken
        self.initialSelectedDate = initialSelectedDate
        self._selectedDate = State(initialValue: initialSelectedDate)
    }

    private let pageBackground = AppColors.lightYellow
    private let cardBackground = Color(red: 0.985, green: 0.965, blue: 0.94)
    private let draftStorageKeyPrefix = "mindecho_diary_draft_"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // 📅 日曆卡片（內建）
                VStack(alignment: .leading, spacing: 10) {
                    Text("選擇日期")
                        .font(.headline)
                        .foregroundColor(AppColors.titleColor)
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(AppColors.titleColor)
                        .disabled(isSaving)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackground)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
                )
                .padding(.horizontal)

                // 📌 本月紀錄
                if !monthlyEntries.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("本月紀錄")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppColors.titleColor)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(monthlyEntries) { entry in
                                    Button {
                                        selectedDate = entry.entryDate
                                    } label: {
                                        VStack(spacing: 4) {
                                            Text(entry.dayText)
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(AppColors.titleColor)
                                            Text(entry.moodEmoji)
                                                .font(.caption)
                                        }
                                        .frame(width: 36, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(cardBackground)
                                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isSaving)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // 😊 心情選擇
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("今天的心情")
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)
                        Spacer()
                        if let mood = selectedMood {
                            Text("已選擇：\(displayName(for: mood))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(moods) { mood in
                                Button {
                                    selectedMood = mood.code
                                } label: {
                                    VStack(spacing: 6) {
                                        Text(mood.emoji).font(.largeTitle)
                                        Text(mood.label)
                                            .font(.caption)
                                            .foregroundColor(AppColors.titleColor)
                                    }
                                    .frame(width: 90, height: 100)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(cardBackground)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .stroke(
                                                        selectedMood == mood.code
                                                        ? AppColors.chatModeColor
                                                        : Color.gray.opacity(0.2),
                                                        lineWidth: 2
                                                    )
                                            )
                                            .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
                                    )
                                }
                                .buttonStyle(.plain)
                                .disabled(isSaving)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                
                // 📔 日記
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("日記")
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)
                        Spacer()
                        Button("查看歷史日記") {
                            showingHistory = true
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundColor(AppColors.orange)
                        .disabled(isSaving)
                    }
                    
                    if isLoading {
                        Text("載入中...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextEditor(text: $diaryText)
                        .frame(height: 160)
                        .padding(10)
                        .foregroundColor(AppColors.titleColor)
                        .focused($isDiaryEditorFocused)
                        .onChange(of: diaryText) { _, _ in
                            hasUnsavedChanges = true
                            saveCurrentDraft()
                        }
                        .disabled(isSaving)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(pageBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        )
                }
                .padding(.horizontal)
                .onChange(of: selectedMood) { _, _ in
                    hasUnsavedChanges = true
                    saveCurrentDraft()
                }
                
                // 📌 儲存區
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.headline)
                            .foregroundColor(AppColors.titleColor)

                        Spacer()

                        Button {
                            selectedDate = Date()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                Text("今天")
                            }
                            .font(.caption.weight(.semibold))
                        }
                        .disabled(isSaving)
                    }
                    
                    Button {
                        Task { await saveDiaryEntry() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Image(systemName: "tray.and.arrow.down.fill")
                            }
                            Text(isSaving ? "儲存中..." : "儲存")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isSaving)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBackground)
                        .shadow(color: .black.opacity(0.06), radius: 10, y: 6)
                )
                .padding(.horizontal)
                
                if let successMessage {
                    Text(successMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(pageBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") {
                    dismissKeyboard()
                }
            }
        }
        .onAppear {
            restoreDraftIfNeeded(for: selectedDate)
            Task { await loadEntries(for: selectedDate) }
        }
        .onChange(of: refreshToken) { _, _ in
            Task { await loadEntries(for: selectedDate) }
        }
        .onChange(of: selectedDate) { _, newValue in
            saveCurrentDraft()
            dismissKeyboard()
            applyEntry(for: newValue)
            restoreDraftIfNeeded(for: newValue)
            Task { await loadEntriesIfMonthChanged(for: newValue) }
        }
        .sheet(isPresented: $showingHistory) {
            DiaryHistorySheet(
                entries: historyEntries,
                onSelect: { entry in
                    selectedDate = entry.entryDate
                    showingHistory = false
                }
            )
        }
        .onChange(of: showingHistory) { _, newValue in
            if newValue {
                Task { await loadHistoryEntries() }
            }
        }
        .fullScreenCover(isPresented: $showingSaveSuccessPage) {
            DiarySaveSuccessView(
                title: successAlertTitle,
                message: successAlertMessage,
                onDone: {
                    handleSaveSuccessDone()
                }
            )
        }
        .onDisappear {
            saveCurrentDraft()
        }
    }
    
    private struct DiaryEntryViewData: Identifiable {
        let id: String
        let content: String
        let mood: String
        let entryDate: Date
    }

    private struct MonthlyEntryItem: Identifiable {
        let id: String
        let entryDate: Date
        let moodEmoji: String
        let dayText: String
    }

    struct HistoryEntryItem: Identifiable {
        let id: String
        let entryDate: Date
        let moodEmoji: String
        let contentPreview: String
    }

    private var historyEntries: [HistoryEntryItem] {
        entriesByDay.values
            .sorted { $0.entryDate > $1.entryDate }
            .map { entry in
                let trimmed = entry.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let preview = trimmed.count > 60 ? String(trimmed.prefix(60)) + "…" : trimmed
                return HistoryEntryItem(
                    id: entry.id,
                    entryDate: entry.entryDate,
                    moodEmoji: moodEmoji(for: entry.mood),
                    contentPreview: preview
                )
            }
    }

    private var monthlyEntries: [MonthlyEntryItem] {
        let calendar = Calendar.current
        return entriesByDay.values
            .sorted { $0.entryDate < $1.entryDate }
            .map { entry in
                MonthlyEntryItem(
                    id: entry.id,
                    entryDate: entry.entryDate,
                    moodEmoji: moodEmoji(for: entry.mood),
                    dayText: "\(calendar.component(.day, from: entry.entryDate))"
                )
            }
    }
    
    private func displayName(for moodCode: String) -> String {
        MoodCatalog.entry(for: moodCode)?.label ?? moodCode
    }

    private func moodEmoji(for moodCode: String) -> String {
        MoodCatalog.entry(for: moodCode)?.emoji ?? "•"
    }
    
    private func normalizeDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private func applyEntry(for date: Date) {
        guard !isDiaryEditorFocused || !hasUnsavedChanges else { return }
        let day = normalizeDay(date)
        if let entry = entriesByDay[day] {
            selectedMood = entry.mood
            diaryText = entry.content
            hasUnsavedChanges = false
        } else {
            selectedMood = nil
            diaryText = ""
            hasUnsavedChanges = false
        }
    }

    private func draftKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return draftStorageKeyPrefix + formatter.string(from: normalizeDay(date))
    }

    private func saveDraft(for date: Date, content: String, mood: String?) {
        let key = draftKey(for: date)
        let draft = DiaryDraft(content: content, mood: mood)
        if let data = try? JSONEncoder().encode(draft) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func clearDraft(for date: Date) {
        UserDefaults.standard.removeObject(forKey: draftKey(for: date))
    }

    /// 草稿在每次輸入時即寫入本機，避免 app 被中斷、白屏或網路失敗時遺失內容。
    private func saveCurrentDraft() {
        guard hasUnsavedChanges else { return }
        saveDraft(for: selectedDate, content: diaryText, mood: selectedMood)
    }

    private func restoreDraftIfNeeded(for date: Date) {
        guard !isDiaryEditorFocused || !hasUnsavedChanges else { return }
        let key = draftKey(for: date)
        guard let data = UserDefaults.standard.data(forKey: key),
              let draft = try? JSONDecoder().decode(DiaryDraft.self, from: data) else {
            return
        }
        diaryText = draft.content
        selectedMood = draft.mood
        hasUnsavedChanges = true
        if successMessage == nil {
            successMessage = "已恢復未送出的日記草稿"
        }
    }
    
    private func monthRange(for date: Date) -> (Date, Date) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let nextMonth = calendar.date(byAdding: DateComponents(month: 1), to: start) ?? date
        let end = calendar.date(byAdding: DateComponents(second: -1), to: nextMonth) ?? date
        return (start, end)
    }

    private func loadEntriesIfMonthChanged(for date: Date) async {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        if loadedMonthStart != monthStart {
            await loadEntries(for: date)
        }
    }
    
    private func parseEntryDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
    
    private func loadEntries(for date: Date) async {
        isLoading = true
        errorMessage = nil
        let range = monthRange(for: date)
        do {
            let entries = try await APIService.shared.getDiaryEntries(
                startDate: range.0,
                endDate: range.1
            )
            var updated: [Date: DiaryEntryViewData] = [:]
            var bestTimestampByDay: [Date: Date] = [:]
            for entry in entries {
                guard let entryDate = parseEntryDate(entry.entryDate),
                      let mood = entry.mood,
                      let content = entry.content else { continue }
                let day = normalizeDay(entryDate)
                let timestamp = parseEntryDate(entry.updatedAt) ?? parseEntryDate(entry.createdAt) ?? entryDate
                if let existing = bestTimestampByDay[day], existing >= timestamp {
                    continue
                }
                bestTimestampByDay[day] = timestamp
                updated[day] = DiaryEntryViewData(
                    id: entry.id,
                    content: content,
                    mood: mood,
                    entryDate: entryDate
                )
            }
            entriesByDay = updated
            loadedMonthStart = Calendar.current.startOfDay(for: range.0)
            applyEntry(for: selectedDate)
        } catch {
            errorMessage = "載入日記失敗，請稍後再試"
        }
        isLoading = false
    }

    private func loadHistoryEntries() async {
        let calendar = Calendar.current
        let end = Date()
        let start = calendar.date(byAdding: .year, value: -5, to: end) ?? end
        do {
            let entries = try await APIService.shared.getDiaryEntries(
                startDate: start,
                endDate: end
            )
            var updated: [Date: DiaryEntryViewData] = [:]
            var bestTimestampByDay: [Date: Date] = [:]
            for entry in entries {
                guard let entryDate = parseEntryDate(entry.entryDate),
                      let mood = entry.mood,
                      let content = entry.content else { continue }
                let day = normalizeDay(entryDate)
                let timestamp = parseEntryDate(entry.updatedAt) ?? parseEntryDate(entry.createdAt) ?? entryDate
                if let existing = bestTimestampByDay[day], existing >= timestamp {
                    continue
                }
                bestTimestampByDay[day] = timestamp
                updated[day] = DiaryEntryViewData(
                    id: entry.id,
                    content: content,
                    mood: mood,
                    entryDate: entryDate
                )
            }
            entriesByDay = updated
        } catch {
            errorMessage = "載入日記失敗，請稍後再試"
        }
    }
    
    private func saveDiaryEntry() async {
        await MainActor.run {
            dismissKeyboard()
        }
        try? await Task.sleep(nanoseconds: 180_000_000)

        errorMessage = nil
        successMessage = nil
        
        guard let mood = selectedMood else {
            errorMessage = "請選擇心情"
            return
        }
        let content = diaryText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            errorMessage = "請輸入日記內容"
            return
        }
        
        isSaving = true
        do {
            let day = normalizeDay(selectedDate)
            let saved = try await APIService.shared.saveDiaryEntry(
                existingId: entriesByDay[day]?.id,
                content: content,
                mood: mood,
                entryDate: selectedDate
            )
            let entryDate = parseEntryDate(saved.entryDate) ?? selectedDate
            entriesByDay[day] = DiaryEntryViewData(
                id: saved.id,
                content: content,
                mood: mood,
                entryDate: entryDate
            )
            selectedMood = mood
            diaryText = content
            hasUnsavedChanges = false
            successMessage = Calendar.current.isDateInToday(selectedDate) ? "今天的紀錄已完成" : "日記已成功儲存"
            showingSaveSuccessPage = true
            clearDraft(for: selectedDate)
        } catch {
            saveDraft(for: selectedDate, content: content, mood: mood)
            errorMessage = diarySaveErrorMessage(for: error)
        }
        isSaving = false
    }

    private var successAlertTitle: String {
        Calendar.current.isDateInToday(selectedDate) ? "今天的紀錄已完成" : "日記已成功儲存"
    }

    private var successAlertMessage: String {
        Calendar.current.isDateInToday(selectedDate) ? "日記已成功儲存" : "這篇日記已成功儲存"
    }

    private func diarySaveErrorMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .userAuthenticationRequired:
                return "登入狀態已失效，草稿已保留，請重新登入後再送出"
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .timedOut:
                return "網路連線異常，草稿已保留，請確認網路後再試"
            default:
                return "儲存失敗，草稿已保留，請稍後再試"
            }
        }

        if let apiError = error as? APIService.APIServiceError {
            switch apiError {
            case .unauthorized:
                return "登入狀態已失效，草稿已保留，請重新登入後再送出"
            case .httpStatus(let statusCode, let message):
                switch statusCode {
                case 400:
                    return message ?? "內容未填寫完整或格式有誤，請確認後再試"
                case 404:
                    return "找不到原本的日記紀錄，請重新整理後再試"
                case 409:
                    return "今天的日記資料正在同步，請稍後再試"
                case 500...599:
                    return "伺服器暫時無回應，草稿已保留，請稍後再試"
                default:
                    return message ?? "儲存失敗，草稿已保留，請稍後再試"
                }
            }
        }

        return "儲存失敗，草稿已保留，請稍後再試"
    }

    private func dismissKeyboard() {
        isDiaryEditorFocused = false
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif
    }

    private func handleSaveSuccessDone() {
        showingSaveSuccessPage = false
        mainTabState.selectedTab = .home
        dismiss()
    }
}

private struct DiarySaveSuccessView: View {
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

private struct DiaryDraft: Codable {
    let content: String
    let mood: String?
}

#if canImport(UIKit)
private struct DiaryHistorySheet: View {
    let entries: [MoodDiaryView.HistoryEntryItem]
    let onSelect: (MoodDiaryView.HistoryEntryItem) -> Void

    var body: some View {
        NavigationView {
            List {
                if entries.isEmpty {
                    Text("尚無日記紀錄")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    ForEach(entries) { entry in
                        Button {
                            onSelect(entry)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Text(entry.moodEmoji)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.entryDate.formatted(date: .abbreviated, time: .omitted))
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(AppColors.titleColor)
                                    Text(entry.contentPreview)
                                        .font(.caption)
                                        .foregroundColor(AppColors.titleColor.opacity(0.7))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("歷史日記")
            .navigationBarTitleDisplayMode(.inline)
            .background(AppColors.lightYellow.ignoresSafeArea())
        }
        .presentationBackground(AppColors.lightYellow)
    }
}
#endif

#Preview {
    MoodDiaryView()
        .environmentObject(MainTabState.shared)
}
