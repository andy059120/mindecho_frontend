import Foundation

// MARK: - API 請求/回應模型
struct SendMessageRequest: Codable {
    let message: String
}

struct ChatAPIResponse: Codable {
    let reply: String
    let messageId: String?
    let timestamp: String?
    let initialMode: InitialModePayload?
}

struct InitialModePayload: Codable {
    let roundsUsed: Int
    let maxRounds: Int
    let sessionEnded: Bool
    let selectedMode: String?
}

struct ChatMessagesResponse: Decodable {
    let messages: [APIMessage]
}

struct APIMessage: Decodable {
    let id: String
    let content: String
    let isFromUser: Bool
    let timestamp: String?
    let createdAt: String?
    let chatbotType: ChatbotType

    enum CodingKeys: String, CodingKey {
        case id
        case content
        case isFromUser
        case timestamp
        case createdAt
        case chatbotType
        case created_at
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        isFromUser = try container.decode(Bool.self, forKey: .isFromUser)
        timestamp = try container.decodeIfPresent(String.self, forKey: .timestamp)
        createdAt =
            try container.decodeIfPresent(String.self, forKey: .createdAt) ??
            (try container.decodeIfPresent(String.self, forKey: .created_at))
        chatbotType = try container.decode(ChatbotType.self, forKey: .chatbotType)
    }
}

struct APISessionInfo: Codable {
    let id: String
    let title: String
    let chatbotType: ChatbotType
    let provider: ChatProvider?
    let createdAt: String
}

struct ChatSessionResponse: Codable {
    let session: APISessionInfo
}

struct ChatSessionsResponse: Codable {
    let sessions: [APISessionInfo]
}

// MARK: - API 錯誤類型
enum ChatAPIError: Error, LocalizedError {
    case networkError(String)
    case invalidResponse
    case serverError(Int)
    case unauthorized
    case rateLimited
    case badRequest(String)
    case notFound(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "網路錯誤: \(message)"
        case .invalidResponse:
            return "伺服器回應格式錯誤"
        case .serverError(let code):
            return "伺服器錯誤 (\(code))"
        case .unauthorized:
            return "未授權，請重新登入"
        case .rateLimited:
            return "免費額度已用完"
        case .badRequest(let message):
            return message.isEmpty ? "請求參數錯誤" : message
        case .notFound(let message):
            return message.isEmpty ? "Session not found." : message
        }
    }
}

enum ChatbotType: String, Codable {
    case mbt = "MBT"
    case cbt = "CBT"
    case dbt = "DBT"
    case mbct = "MBCT"
    case initial = "INITIAL"

    var therapyMode: TherapyMode {
        switch self {
        case .mbt: return .mbtMode
        case .cbt: return .cbtMode
        case .dbt: return .dbtMode
        case .mbct: return .mbctMode
        case .initial: return .initial
        }
    }
}

enum ChatProvider: String, Codable {
    case gemini
    case anthropic
}

extension TherapyMode {
    var chatbotType: ChatbotType {
        switch self {
        case .chatMode: return .initial
        case .cbtMode: return .cbt
        case .dbtMode: return .dbt
        case .mbtMode: return .mbt
        case .mbctMode: return .mbct
        case .initial: return .initial
        }
    }
}

// MARK: - 聊天 API 服務
class ChatAPI: NSObject, URLSessionDelegate {
    static let shared = ChatAPI()
    
    private let baseURL = "https://mindechoserver.com:8443/api"
    private let allowInsecureSelfSigned = true
    private let enableDebugLog = true
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        return URLSession(
            configuration: config,
            delegate: allowInsecureSelfSigned ? self : nil,
            delegateQueue: nil
        )
    }()
    
    private override init() {
        super.init()
    }

    private func log(_ message: String) {
        guard enableDebugLog else { return }
        print("[ChatAPI] \(message)")
    }

    private func sendMessageRequest(
        sessionId: String,
        request: SendMessageRequest,
        token: String
    ) async throws -> ChatAPIResponse {
        guard let url = URL(string: "\(self.baseURL)/chat/sessions/\(sessionId)/messages") else {
            throw ChatAPIError.networkError("無效的 URL")
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)" ,forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
            if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                self.log("sendMessage → \(url.absoluteString) body=\(bodyString)")
            } else {
                self.log("sendMessage → \(url.absoluteString) body=<empty>")
            }
            
            let (data, response) = try await self.session.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse {
                if let body = String(data: data, encoding: .utf8) {
                    self.log("sendMessage ← body=\(body)")
                }
                self.log("sendMessage ← status=\(httpResponse.statusCode)")
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 400:
                    let message = parseErrorMessage(from: data)
                    throw ChatAPIError.badRequest(message)
                case 401:
                    throw ChatAPIError.unauthorized
                case 429:
                    throw ChatAPIError.rateLimited
                case 404:
                    let message = parseErrorMessage(from: data)
                    throw ChatAPIError.notFound(message.isEmpty ? "Session not found." : message)
                default:
                    throw ChatAPIError.serverError(httpResponse.statusCode)
                }
            }

            return try JSONDecoder().decode(ChatAPIResponse.self, from: data)
        } catch {
            self.log("sendMessage ✖︎ \(error.localizedDescription)")
            if error is ChatAPIError {
                throw error
            } else {
                throw ChatAPIError.networkError(error.localizedDescription)
            }
        }
    }

    private func sendMessageWithRetry(
        sessionId: String,
        request: SendMessageRequest,
        token: String,
        attemptsRemaining: Int = 1
    ) async throws -> ChatAPIResponse {
        do {
            return try await sendMessageRequest(sessionId: sessionId, request: request, token: token)
        } catch let error as ChatAPIError {
            switch error {
            case .badRequest, .unauthorized, .rateLimited, .notFound:
                throw error
            case .networkError, .invalidResponse, .serverError:
                guard attemptsRemaining > 0 else { throw error }
                self.log("sendMessage ↻ retrying after failure")
                try await Task.sleep(nanoseconds: 800_000_000)
                return try await sendMessageWithRetry(
                    sessionId: sessionId,
                    request: request,
                    token: token,
                    attemptsRemaining: attemptsRemaining - 1
                )
            }
        } catch {
            guard attemptsRemaining > 0 else {
                throw ChatAPIError.networkError(error.localizedDescription)
            }
            self.log("sendMessage ↻ retrying after unexpected failure")
            try await Task.sleep(nanoseconds: 800_000_000)
            return try await sendMessageWithRetry(
                sessionId: sessionId,
                request: request,
                token: token,
                attemptsRemaining: attemptsRemaining - 1
            )
        }
    }

    private func performWithRefresh<T>(
        token: String,
        operation: @escaping (String) async throws -> T
    ) async throws -> T {
        do {
            return try await operation(token)
        } catch ChatAPIError.unauthorized {
            do {
                let refreshedToken = try await AuthService.shared.refreshAccessTokenIfPossible()
                return try await operation(refreshedToken)
            } catch {
                await MainActor.run {
                    AuthService.shared.logout()
                }
                throw ChatAPIError.unauthorized
            }
        }
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard allowInsecureSelfSigned,
              challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let trust = challenge.protectionSpace.serverTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        completionHandler(.useCredential, URLCredential(trust: trust))
    }
    
    // MARK: - 發送訊息
    func sendMessage(sessionId: String, request: SendMessageRequest, token: String) async throws -> ChatAPIResponse {
        return try await performWithRefresh(token: token) { [self] token in
            try await self.sendMessageWithRetry(
                sessionId: sessionId,
                request: request,
                token: token
            )
        }
    }
    
    // MARK: - 獲取聊天記錄
    func getChatHistory(sessionId: String, token: String, limit: Int? = nil, before: String? = nil) async throws -> ChatMessagesResponse {
        return try await performWithRefresh(token: token) { [self] token in
            var components = URLComponents(string: "\(self.baseURL)/chat/sessions/\(sessionId)/messages")
            var queryItems: [URLQueryItem] = []
            if let limit {
                queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            if let before {
                queryItems.append(URLQueryItem(name: "before", value: before))
            }
            components?.queryItems = queryItems.isEmpty ? nil : queryItems
            guard let url = components?.url else {
                throw ChatAPIError.networkError("無效的 URL")
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                self.log("getChatHistory → \(url.absoluteString)")
                let (data, response) = try await self.session.data(for: urlRequest)
                
                if let httpResponse = response as? HTTPURLResponse {
                    self.log("getChatHistory ← status=\(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200...299:
                        break
                    case 400:
                        let message = parseErrorMessage(from: data)
                        throw ChatAPIError.badRequest(message)
                    case 401:
                        throw ChatAPIError.unauthorized
                    case 404:
                        let message = parseErrorMessage(from: data)
                        throw ChatAPIError.notFound(message.isEmpty ? "Session not found." : message)
                    default:
                        throw ChatAPIError.serverError(httpResponse.statusCode)
                    }
                }
                
                if let body = String(data: data, encoding: .utf8) {
                    self.log("getChatHistory ← body=\(body)")
                }
                return try JSONDecoder().decode(ChatMessagesResponse.self, from: data)
                
            } catch {
                self.log("getChatHistory ✖︎ \(error.localizedDescription)")
                if error is ChatAPIError {
                    throw error
                } else {
                    throw ChatAPIError.networkError(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - 取得會話列表
    func getSessions(token: String, limit: Int = 20, offset: Int = 0) async throws -> ChatSessionsResponse {
        return try await performWithRefresh(token: token) { [self] token in
            var components = URLComponents(string: "\(self.baseURL)/chat/sessions")
            components?.queryItems = [
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "offset", value: String(offset))
            ]
            guard let url = components?.url else {
                throw ChatAPIError.networkError("無效的 URL")
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "GET"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                self.log("getSessions → \(url.absoluteString)")
                let (data, response) = try await self.session.data(for: urlRequest)
                
                if let httpResponse = response as? HTTPURLResponse {
                    self.log("getSessions ← status=\(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200...299:
                        break
                    case 400:
                        let message = parseErrorMessage(from: data)
                        throw ChatAPIError.badRequest(message)
                    case 401:
                        throw ChatAPIError.unauthorized
                    default:
                        throw ChatAPIError.serverError(httpResponse.statusCode)
                    }
                }
                
                if let body = String(data: data, encoding: .utf8) {
                    self.log("getSessions ← body=\(body)")
                }
                return try JSONDecoder().decode(ChatSessionsResponse.self, from: data)
                
            } catch {
                self.log("getSessions ✖︎ \(error.localizedDescription)")
                if error is ChatAPIError {
                    throw error
                } else {
                    throw ChatAPIError.networkError(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 建立新會話
    func createNewSession(mode: TherapyMode, title: String? = nil, provider: ChatProvider? = nil, token: String) async throws -> APISessionInfo {
        return try await performWithRefresh(token: token) { [self] token in
            guard let url = URL(string: "\(self.baseURL)/chat/sessions") else {
                throw ChatAPIError.networkError("無效的 URL")
            }
            
            var requestBody: [String: String] = ["chatbotType": mode.chatbotType.rawValue]
            if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                requestBody["title"] = title.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let provider {
                requestBody["provider"] = provider.rawValue
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
                if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
                    self.log("createNewSession → \(url.absoluteString) body=\(bodyString)")
                } else {
                    self.log("createNewSession → \(url.absoluteString) body=<empty>")
                }
                
                let (data, response) = try await self.session.data(for: urlRequest)
                
                if let httpResponse = response as? HTTPURLResponse {
                    self.log("createNewSession ← status=\(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200...299:
                        break
                    case 400:
                        let message = parseErrorMessage(from: data)
                        throw ChatAPIError.badRequest(message)
                    case 401:
                        throw ChatAPIError.unauthorized
                    default:
                        throw ChatAPIError.serverError(httpResponse.statusCode)
                    }
                }
                
                if let body = String(data: data, encoding: .utf8) {
                    self.log("createNewSession ← body=\(body)")
                }
                let payload = try JSONDecoder().decode(ChatSessionResponse.self, from: data)
                return payload.session
                
            } catch {
                self.log("createNewSession ✖︎ \(error.localizedDescription)")
                if error is ChatAPIError {
                    throw error
                } else {
                    throw ChatAPIError.networkError(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 刪除會話
    func deleteSession(sessionId: String, token: String) async throws {
        try await performWithRefresh(token: token) { [self] token in
            guard let url = URL(string: "\(self.baseURL)/chat/sessions/\(sessionId)") else {
                throw ChatAPIError.networkError("無效的 URL")
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "DELETE"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                self.log("deleteSession → \(url.absoluteString)")
                let (data, response) = try await self.session.data(for: urlRequest)
                
                if let httpResponse = response as? HTTPURLResponse {
                    self.log("deleteSession ← status=\(httpResponse.statusCode)")
                    switch httpResponse.statusCode {
                    case 200...299:
                        break
                    case 400:
                        let message = parseErrorMessage(from: data)
                        throw ChatAPIError.badRequest(message.isEmpty ? "請求參數錯誤" : message)
                    case 401:
                        throw ChatAPIError.unauthorized
                    case 404:
                        let message = parseErrorMessage(from: data)
                        throw ChatAPIError.notFound(message.isEmpty ? "Session not found." : message)
                    default:
                        throw ChatAPIError.serverError(httpResponse.statusCode)
                    }
                }
                
            } catch {
                if error is ChatAPIError {
                    throw error
                } else {
                    throw ChatAPIError.networkError(error.localizedDescription)
                }
            }
        }
    }

    private func parseErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            if let innerData = message.data(using: .utf8),
               let inner = try? JSONSerialization.jsonObject(with: innerData) as? [String: Any],
               let error = inner["error"] as? [String: Any],
               let innerMessage = error["message"] as? String {
                return innerMessage
            }
            return message
        }
        return ""
    }
}

// MARK: - 模擬 API（開發階段使用）
extension ChatAPI {
    // 這個方法在你還沒有真實後端時可以使用
    func generateMockResponse(for message: String, mode: TherapyMode) -> ChatAPIResponse {
        let response = generateAIResponse(for: message, mode: mode)
        
        return ChatAPIResponse(
            reply: response,
            messageId: UUID().uuidString,
            timestamp: ISO8601DateFormatter().string(from: Date()),
            initialMode: nil
        )
    }
    
    // 從你原本的 ChatManager 移過來的 AI 回覆邏輯
    private func generateAIResponse(for message: String, mode: TherapyMode) -> String {
        let lowercaseMessage = message.lowercased()
        
        switch mode {
        case .chatMode:
            if lowercaseMessage.contains("壓力") {
                return "聽起來您最近壓力不小。能告訴我是什麼讓您感到有壓力嗎？"
            } else if lowercaseMessage.contains("開心") || lowercaseMessage.contains("高興") {
                return "很高興聽到您心情不錯！是有什麼特別的事情讓您開心嗎？"
            } else if lowercaseMessage.contains("累") || lowercaseMessage.contains("疲憊") {
                return "感覺您很疲憊。最近工作或生活節奏是不是比較緊張？"
            } else if lowercaseMessage.contains("週末") || lowercaseMessage.contains("休息") {
                return "聽起來您需要好好休息一下！有什麼特別想做的嗎？戶外活動、看電影，還是其他的興趣愛好？"
            } else if lowercaseMessage.contains("感受不明") {
                return "感受是很重要的信息。能告訴我這種感受在您身體的哪個部位最明顯嗎？"
            } else {
                return "我理解您的感受。能告訴我更多關於這個情況的細節嗎？"
            }
            
        case .cbtMode:
            if lowercaseMessage.contains("總是") || lowercaseMessage.contains("永遠") {
                return "我注意到您用了「總是」這個詞。讓我們檢視一下這個想法是否準確。能給我一些具體的例子嗎？"
            } else if lowercaseMessage.contains("失敗") || lowercaseMessage.contains("做不好") {
                return "失敗的感受很難受。讓我們分析一下這個想法背後的證據。什麼讓您覺得是失敗？"
            } else if lowercaseMessage.contains("焦慮") || lowercaseMessage.contains("擔心") {
                return "焦慮和擔心是很常見的情緒。讓我們用CBT的方式來分析這些想法，看看哪些是基於事實的。"
            } else {
                return "讓我們用認知行為療法的方式來分析這個問題。首先，我們可以識別一些可能影響您情緒的想法模式。"
            }
            
        case .dbtMode:
            if lowercaseMessage.contains("快撐不住") || lowercaseMessage.contains("失控") || lowercaseMessage.contains("爆炸") {
                return "聽起來情緒已經很滿了。我們先不急著分析對錯，先一起把這一刻撐過去。此刻最強烈的是哪個感受？它大概有多強，0 到 10 分會是幾分？"
            } else if lowercaseMessage.contains("衝動") || lowercaseMessage.contains("想傷害自己") {
                return "謝謝你直接說出這個衝動。現在最重要的是先降低衝動強度。你願意先把危險物品移遠一點，然後跟我一起做一個短短的穩定步驟嗎？"
            } else if lowercaseMessage.contains("關係") || lowercaseMessage.contains("吵架") {
                return "在人際壓力下情緒被拉高很常見。DBT 會先分開看：你現在的情緒是什麼、你最想達成的目標是什麼、以及你希望這段關係最後變成什麼樣子。"
            } else {
                return "我們先用 DBT 的方式處理這一刻：先穩住情緒，再整理需求，最後決定下一步。你現在最需要的是安定自己、撐過衝動，還是想清楚怎麼和別人互動？"
            }
        case .mbtMode:
            if lowercaseMessage.contains("不理解") || lowercaseMessage.contains("不懂") {
                return "理解他人的想法確實不容易。讓我們試著從心智化的角度來看，您覺得對方可能在想什麼？"
            } else if lowercaseMessage.contains("感受") || lowercaseMessage.contains("情緒") {
                return "感受是很重要的信息。能告訴我這種感受在您身體的哪個部位最明顯嗎？"
            } else if lowercaseMessage.contains("關係") || lowercaseMessage.contains("人際") {
                return "人際關係是複雜的。讓我們一起探索在這個關係中，您和對方各自的感受和需求。"
            } else if lowercaseMessage.contains("感受不明") {
                return "感受混亂時很正常的。讓我們慢慢來，先試著感受一下您現在身體的狀態，有什麼地方特別緊繃或放鬆嗎？"
            } else {
                return "在正念為基礎的療法中，我們關注當下的感受和體驗。讓我們花一點時間覺察您現在的感受。"
            }
        case .mbctMode:
            if lowercaseMessage.contains("壓力") || lowercaseMessage.contains("焦慮") {
                return "謝謝你的分享。我們可以先用幾次深呼吸，覺察當下身體的緊繃感。你願意描述一下此刻身體最明顯的感受嗎？"
            } else if lowercaseMessage.contains("想法") || lowercaseMessage.contains("念頭") {
                return "在MBCT裡，我們會練習把念頭當作「路過的雲」。你願意試著描述這些念頭，但不急著判斷它們嗎？"
            } else if lowercaseMessage.contains("情緒") || lowercaseMessage.contains("心情") {
                return "我們可以先為情緒命名，並用好奇的態度觀察它。此刻最主要的情緒是什麼？它大約有多強烈？"
            } else {
                return "我們可以先停一下，做個短暫的覺察。現在的呼吸、身體、情緒，各自是什麼狀態？"
            }
        case .initial:
            return "謝謝你願意開始分享。我們可以從你最近最在意的一件事開始。你想先從哪裡聊起？"
        }
    }
}
