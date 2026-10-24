import SwiftUI
import Foundation

// MARK: - 聊天狀態管理 Hook
@MainActor
class ChatHook: ObservableObject {
    // MARK: - 發布的狀態變數
    @Published var chatSessions: [ChatSession] = []
    @Published var messages: [UUID: [ChatMessage]] = [:]
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    @Published private(set) var typingSessionIds: Set<UUID> = []
    @Published var initialModeBySession: [UUID: InitialModeInfo] = [:]
    @Published private(set) var sendingSessionIds: Set<UUID> = []
    
    // MARK: - 私有屬性
    private let chatAPI = ChatAPI.shared
    
    // 當前用戶信息（從 TokenManager 獲取）
    private var currentUserId: String {
        // 這裡應該從你的 TokenManager 獲取實際的用戶 ID
        return "current_user_id" // 暫時用固定值
    }
    
    private var authToken: String? {
        AuthService.shared.authToken
    }
    
    // MARK: - 初始化
    init() {
        // 不在 init 期間修改 @Published，避免 SwiftUI view update 警告
    }
    
    // MARK: - 會話管理方法
    
    /// 建立新的聊天會話
    func createNewSession(mode: TherapyMode, title: String? = nil) async -> ChatSession? {
        isLoading = true
        error = nil
        
        do {
            // 如果有真實後端，使用 API
            if let token = authToken {
                let apiSessionInfo = try await chatAPI.createNewSession(mode: mode, title: title, provider: nil, token: token)
                let sessionMode = apiSessionInfo.chatbotType.therapyMode
                
                // 將 API 回應轉換為本地模型
                let session = ChatSession(
                    id: UUID(),
                    backendId: apiSessionInfo.id,
                    title: apiSessionInfo.title,
                    therapyMode: sessionMode,
                    lastMessage: "",
                    lastUpdated: parseAPIDate(apiSessionInfo.createdAt) ?? Date(),
                    tags: [sessionMode.shortName]
                )
                
                chatSessions.insert(session, at: 0)
                messages[session.id] = []
                
                // 添加歡迎訊息
                await addWelcomeMessage(to: session.id, mode: mode)
                
                isLoading = false
                return session
                
            } else {
                // 離線模式：直接建立本地會話
                let session = createLocalSession(mode: mode)
                chatSessions.insert(session, at: 0)
                messages[session.id] = []
                
                await addWelcomeMessage(to: session.id, mode: mode)
                
                isLoading = false
                return session
            }
            
        } catch {
            self.error = error.localizedDescription
            showError = true
            isLoading = false
            return nil
        }
    }
    
    /// 刪除聊天會話
    func deleteSession(_ sessionId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            // 如果有真實後端，先刪除遠端資料
            if let token = authToken,
               let backendId = chatSessions.first(where: { $0.id == sessionId })?.backendId {
                try await chatAPI.deleteSession(sessionId: backendId, token: token)
            }
            
            // 刪除本地資料
            chatSessions.removeAll { $0.id == sessionId }
            messages.removeValue(forKey: sessionId)
            
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    /// 更新會話模式
    func updateSessionMode(_ sessionId: UUID, mode: TherapyMode) async {
        guard let index = chatSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        chatSessions[index].therapyMode = mode
        chatSessions[index].lastUpdated = Date()
        
        // 添加模式切換訊息
        await addMessage(
            to: sessionId,
            content: mode.welcomeMessage,
            isFromUser: false
        )
        
    }
    
    // MARK: - 訊息管理方法
    
    /// 發送訊息
    func sendMessage(to sessionId: UUID, content: String) async -> Bool {
        guard let session = chatSessions.first(where: { $0.id == sessionId }) else { return false }
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return false }
        guard !sendingSessionIds.contains(sessionId) else { return false }

        sendingSessionIds.insert(sessionId)
        defer { sendingSessionIds.remove(sessionId) }
        
        // 1. 立即添加用戶訊息到 UI
        await addMessage(to: sessionId, content: trimmedContent, isFromUser: true)
        
        // 2. 顯示打字指示器
        typingSessionIds.insert(sessionId)
        
        do {
            // 3. 呼叫 API 獲取 AI 回覆
            let aiResponse: String
            
            if let token = authToken {
                // 使用真實 API
                let request = SendMessageRequest(
                    message: trimmedContent
                )

                guard let backendId = session.backendId else {
                    throw ChatAPIError.invalidResponse
                }
                let response = try await chatAPI.sendMessage(
                    sessionId: backendId,
                    request: request,
                    token: token
                )
                aiResponse = response.reply
                if let initialMode = response.initialMode {
                    let mapped = InitialModeInfo(
                        roundsUsed: initialMode.roundsUsed,
                        maxRounds: initialMode.maxRounds,
                        sessionEnded: initialMode.sessionEnded,
                        selectedMode: TherapyMode.fromInitialMode(initialMode.selectedMode),
                        rawSelectedMode: initialMode.selectedMode
                    )
                    initialModeBySession[sessionId] = mapped
                }
                
            } else {
                // 使用模擬 API
                let mockResponse = chatAPI.generateMockResponse(
                    for: trimmedContent,
                    mode: session.therapyMode
                )
                
                // 模擬網路延遲
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 秒
                aiResponse = mockResponse.reply
            }
            
            // 4. 隱藏打字指示器
            typingSessionIds.remove(sessionId)
            
            // 5. 添加 AI 回覆
            await addMessage(to: sessionId, content: aiResponse, isFromUser: false)
            return true
            
        } catch {
            typingSessionIds.remove(sessionId)
            if let chatError = error as? ChatAPIError, case .rateLimited = chatError {
                await addMessage(
                    to: sessionId,
                    content: "免費額度已用完，請稍後再試或升級方案。",
                    isFromUser: false
                )
                self.error = nil
                showError = false
            } else {
                self.error = error.localizedDescription
                showError = true
            }
            return false
        }
    }

    func isSendingMessage(in sessionId: UUID) -> Bool {
        sendingSessionIds.contains(sessionId)
    }

    func isTyping(in sessionId: UUID) -> Bool {
        typingSessionIds.contains(sessionId)
    }

    /// 初談結束後，保留原始聊天室，並在建議學派建立一個帶有承接內容的新聊天室。
    func createHandoffSession(from sourceSessionId: UUID, to mode: TherapyMode) async -> ChatSession? {
        let handoff = handoffContext(for: sourceSessionId, targetMode: mode)
        guard let session = await createNewSession(mode: mode, title: "初談承接") else {
            return nil
        }
        _ = await sendMessage(to: session.id, content: handoff)
        return session
    }
    
    /// 添加訊息（內部方法）
    private func addMessage(to sessionId: UUID, content: String, isFromUser: Bool) async {
        guard let sessionIndex = chatSessions.firstIndex(where: { $0.id == sessionId }) else { return }
        
        let session = chatSessions[sessionIndex]
        let message = ChatMessage(
            content: content,
            isFromUser: isFromUser,
            mode: session.therapyMode
        )
        
        // 添加到訊息列表
        if messages[sessionId] == nil {
            messages[sessionId] = []
        }
        messages[sessionId]?.append(message)
        
        // 更新會話信息
        chatSessions[sessionIndex].lastMessage = content
        chatSessions[sessionIndex].lastUpdated = Date()
        chatSessions[sessionIndex].messageCount = messages[sessionId]?.count ?? 0
        
        // 如果是用戶的第一條訊息，更新標題
        if isFromUser && messages[sessionId]?.filter({ $0.isFromUser }).count == 1 {
            let title = String(content.prefix(20)) + (content.count > 20 ? "..." : "")
            chatSessions[sessionIndex].title = title
        }
        
        // 將最新會話移到最前面
        let updatedSession = chatSessions[sessionIndex]
        chatSessions.remove(at: sessionIndex)
        chatSessions.insert(updatedSession, at: 0)
        
    }
    
    /// 添加歡迎訊息
    private func addWelcomeMessage(to sessionId: UUID, mode: TherapyMode) async {
        await addMessage(to: sessionId, content: mode.welcomeMessage, isFromUser: false)
    }

    private func handoffContext(for sourceSessionId: UUID, targetMode: TherapyMode) -> String {
        let userMessages = (messages[sourceSessionId] ?? [])
            .filter(\.isFromUser)
            .suffix(4)
            .map { String($0.content.prefix(800)) }

        let sharedContent: String
        if userMessages.isEmpty {
            sharedContent = "使用者已完成初談，尚未留下可轉交的文字內容。"
        } else {
            sharedContent = userMessages.enumerated()
                .map { "\($0.offset + 1). \($0.element)" }
                .joined(separator: "\n")
        }

        return """
        這是從初談轉入 \(targetMode.shortName) 的承接內容。請先理解使用者先前分享的內容，不要要求使用者重新敘述，並以此模式的方式溫和接續對話。

        使用者先前分享：
        \(sharedContent)
        """
    }
    
    /// 清除會話的所有訊息
    func clearMessages(for sessionId: UUID) async {
        messages[sessionId] = []
        initialModeBySession[sessionId] = nil
        
        // 更新會話信息
        if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
            chatSessions[index].lastMessage = ""
            chatSessions[index].lastUpdated = Date()
            chatSessions[index].messageCount = 0
            
            // 重新添加歡迎訊息
            let mode = chatSessions[index].therapyMode
            await addWelcomeMessage(to: sessionId, mode: mode)
        }
        
    }
    
    /// 獲取特定會話的訊息
    func getMessages(for sessionId: UUID) -> [ChatMessage] {
        return messages[sessionId] ?? []
    }
    
    // MARK: - 資料同步方法
    
    /// 從伺服器載入聊天記錄
    func loadChatHistory(for sessionId: UUID) async {
        guard let token = authToken else { return }
        guard let backendId = chatSessions.first(where: { $0.id == sessionId })?.backendId else {
            return
        }
        error = nil
        
        do {
            let historyResponse = try await chatAPI.getChatHistory(
                sessionId: backendId,
                token: token
            )
            
            let existingTimestampsByBackendId: [String: Date] = Dictionary(
                uniqueKeysWithValues: (messages[sessionId] ?? []).compactMap { message -> (String, Date)? in
                    guard let backendId = message.backendId else { return nil }
                    return (backendId, message.timestamp)
                }
            )

            // 將 API 訊息轉換為本地模型
            let apiMessages: [ChatMessage] = historyResponse.messages.map { apiMessage in
                let resolvedTimestamp =
                    parseAPIDate(apiMessage.timestamp ?? apiMessage.createdAt) ??
                    existingTimestampsByBackendId[apiMessage.id]

                return ChatMessage(
                    id: UUID(uuidString: apiMessage.id) ?? UUID(),
                    backendId: apiMessage.id,
                    content: apiMessage.content,
                    isFromUser: apiMessage.isFromUser,
                    timestamp: resolvedTimestamp ?? Date.distantPast,
                    mode: apiMessage.chatbotType.therapyMode
                )
            }
            
            // 若使用者剛送出訊息，不能用較早取得的歷史資料覆蓋畫面上的新訊息。
            // 下一次進入頁面會再由後端紀錄完成同步。
            guard !sendingSessionIds.contains(sessionId) else { return }

            if !apiMessages.isEmpty {
                messages[sessionId] = apiMessages
                
                // 更新會話信息
                if let index = chatSessions.firstIndex(where: { $0.id == sessionId }) {
                    let lastUpdated = apiMessages.last?.timestamp ?? Date()
                    chatSessions[index].lastUpdated = lastUpdated
                    chatSessions[index].messageCount = apiMessages.count
                    chatSessions[index].lastMessage = apiMessages.last?.content ?? ""
                }
            } else if messages[sessionId] == nil {
                messages[sessionId] = []
            }
            
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
    }

    /// 取得會話列表（後端）
    func loadSessions(limit: Int = 20, offset: Int = 0) async {
        guard let token = authToken else { return }
        isLoading = true
        error = nil
        
        do {
            let response = try await chatAPI.getSessions(token: token, limit: limit, offset: offset)
            let existingIds: [String: UUID] = Dictionary(uniqueKeysWithValues: chatSessions.compactMap { session -> (String, UUID)? in
                guard let backendId = session.backendId else { return nil }
                return (backendId, session.id)
            })
            var mapped: [ChatSession] = response.sessions.map { session in
                    ChatSession(
                        id: existingIds[session.id] ?? UUID(),
                        backendId: session.id,
                        title: session.title,
                        therapyMode: session.chatbotType.therapyMode,
                        lastMessage: "",
                        lastUpdated: parseAPIDate(session.createdAt) ?? Date(),
                        tags: [session.chatbotType.therapyMode.shortName]
                    )
                }
            
            await withTaskGroup(of: (String, String?).self) { group in
                for session in mapped {
                    guard let backendId = session.backendId else { continue }
                    group.addTask { [token, chatAPI] in
                        do {
                            let response = try await chatAPI.getChatHistory(
                                sessionId: backendId,
                                token: token,
                                limit: 1
                            )
                            let lastMessage = response.messages.last?.content
                            return (backendId, lastMessage)
                        } catch {
                            return (backendId, nil)
                        }
                    }
                }
                
                var lastMessageMap: [String: String] = [:]
                var emptyBackendIds: [String] = []
                for await (backendId, message) in group {
                    if let message, !message.isEmpty {
                        lastMessageMap[backendId] = message
                    } else {
                        emptyBackendIds.append(backendId)
                    }
                }
                
                for index in mapped.indices {
                    guard let backendId = mapped[index].backendId else { continue }
                    if let message = lastMessageMap[backendId] {
                        mapped[index].lastMessage = message
                    }
                }
                
            }
            chatSessions = mapped
        } catch {
            self.error = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }

    private func parseAPIDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: trimmed) {
            return date
        }

        let formatters: [DateFormatter] = [
            makeDateFormatter("yyyy-MM-dd HH:mm:ss", timeZone: TimeZone.current),
            makeDateFormatter("yyyy-MM-dd'T'HH:mm:ss", timeZone: TimeZone.current),
            makeDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS", timeZone: TimeZone.current),
            makeDateFormatter("yyyy-MM-dd'T'HH:mm:ssZ"),
            makeDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSZ"),
            makeDateFormatter("yyyy-MM-dd'T'HH:mm:ssXXXXX"),
            makeDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }

    private func makeDateFormatter(_ format: String, timeZone: TimeZone? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        formatter.timeZone = timeZone
        return formatter
    }
    
    // 不使用本地快取
    
    /// 建立本地會話（離線模式）
    private func createLocalSession(mode: TherapyMode) -> ChatSession {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        formatter.locale = Locale(identifier: "zh_Hant_TW")
        
        return ChatSession(
            title: "\(mode.shortName) - \(formatter.string(from: now))",
            therapyMode: mode,
            tags: [mode.shortName]
        )
    }
    
    // MARK: - 示例資料（開發用）
    
    /// 建立示例資料（僅在沒有本地資料時使用）
    // 移除示例資料
    
    // MARK: - 清理方法（測試用）
    
    /// 清除所有資料
    func clearAllData() {
        chatSessions.removeAll()
        messages.removeAll()
    }
}

struct InitialModeInfo {
    let roundsUsed: Int
    let maxRounds: Int
    let sessionEnded: Bool
    let selectedMode: TherapyMode?
    let rawSelectedMode: String?
}

extension TherapyMode {
    static func fromInitialMode(_ value: String?) -> TherapyMode? {
        guard let value else { return nil }
        let normalized = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        switch normalized {
        case "CBT": return .cbtMode
        case "DBT": return .dbtMode
        case "MBT": return .mbtMode
        case "MBCT": return .mbctMode
        default: return nil
        }
    }
}
