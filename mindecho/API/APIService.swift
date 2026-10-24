import Foundation
import Combine

class APIService: NSObject, ObservableObject, URLSessionDelegate {
    static let shared = APIService()
    
    private let baseURL = "https://mindechoserver.com:8443/api"
    private var reasonBaseURL: String { "\(baseURL)/reason" }
    private var diaryBaseURL: String { "\(baseURL)/diaries" }
    private var healthAdviceURL: String { "\(baseURL)/health/advice" }
    private var emotionAnalysisURL: String { "\(baseURL)/emotion/analysis" }
    private static let reasonDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let diaryDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private let allowInsecureSelfSigned = true
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

    enum APIServiceError: Error {
        case unauthorized
        case httpStatus(Int, String?)
    }

    private func performWithRefresh<T>(
        requestBuilder: @escaping (String) throws -> URLRequest,
        decode: @escaping (Data) throws -> T
    ) async throws -> T {
        guard let token = AuthService.shared.authToken else {
            throw URLError(URLError.Code.userAuthenticationRequired)
        }
        do {
            return try await execute(requestBuilder: requestBuilder, token: token, decode: decode)
        } catch APIServiceError.unauthorized {
            do {
                let refreshedToken = try await AuthService.shared.refreshAccessTokenIfPossible()
                return try await execute(
                    requestBuilder: requestBuilder,
                    token: refreshedToken,
                    decode: decode
                )
            } catch {
                await MainActor.run {
                    AuthService.shared.logout()
                }
                throw URLError(URLError.Code.userAuthenticationRequired)
            }
        }
    }

    private func execute<T>(
        requestBuilder: (String) throws -> URLRequest,
        token: String,
        decode: (Data) throws -> T
    ) async throws -> T {
        let request = try requestBuilder(token)
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse {
            if http.statusCode == 401 {
                throw APIServiceError.unauthorized
            }
            guard (200...299).contains(http.statusCode) else {
                throw APIServiceError.httpStatus(http.statusCode, parseAPIErrorMessage(from: data))
            }
        }
        return try decode(data)
    }

    private func parseAPIErrorMessage(from data: Data) -> String? {
        if let payload = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = payload["message"] as? String,
           !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }
        if let text = String(data: data, encoding: .utf8),
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return nil
    }

    private func diaryRequest<T: Decodable>(
        path: String = "",
        method: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = [],
        decode: @escaping (Data) throws -> T
    ) async throws -> T {
        try await performWithRefresh(
            requestBuilder: { token in
                var components = URLComponents(string: self.diaryBaseURL + path)
                if !queryItems.isEmpty {
                    components?.queryItems = queryItems
                }
                guard let url = components?.url else {
                    throw URLError(.badURL)
                }

                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.httpBody = body
                return request
            },
            decode: decode
        )
    }

    private func reasonRequest<T: Decodable>(
        path: String = "",
        method: String,
        body: Data? = nil,
        queryItems: [URLQueryItem] = [],
        decode: @escaping (Data) throws -> T
    ) async throws -> T {
        try await performWithRefresh(
            requestBuilder: { token in
                var components = URLComponents(string: self.reasonBaseURL + path)
                if !queryItems.isEmpty {
                    components?.queryItems = queryItems
                }
                guard let url = components?.url else {
                    throw URLError(.badURL)
                }

                var request = URLRequest(url: url)
                request.httpMethod = method
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.httpBody = body
                return request
            },
            decode: decode
        )
    }

    private func latestDiaryEntry(on date: Date) async throws -> DiaryEntry? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        let end = calendar.date(byAdding: .second, value: -1, to: nextDay) ?? start
        let entries = try await getDiaryEntries(startDate: start, endDate: end)
        return entries.max { lhs, rhs in
            let l = parseISODate(lhs.updatedAt) ?? parseISODate(lhs.createdAt) ?? parseISODate(lhs.entryDate) ?? .distantPast
            let r = parseISODate(rhs.updatedAt) ?? parseISODate(rhs.createdAt) ?? parseISODate(rhs.entryDate) ?? .distantPast
            return l < r
        }
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
    
    func updateMetrics(data: [String: Any]) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self else {
                promise(.failure(URLError(.unknown)))
                return
            }
            Task {
                do {
                    let result = try await self.performWithRefresh(
                        requestBuilder: { token in
                            guard let url = URL(string: "\(self.baseURL)/main/updateMetrics") else {
                                throw URLError(.badURL)
                            }
                            var request = URLRequest(url: url)
                            request.httpMethod = "POST"
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                            request.httpBody = try JSONSerialization.data(withJSONObject: data)
                            return request
                        },
                        decode: { data in
                            let responseText = String(data: data, encoding: .utf8) ?? "No body"
                            print("🧾 [updateMetrics] Response Body: \(responseText)")
                            return true
                        }
                    )
                    await MainActor.run { promise(.success(result)) }
                } catch {
                    await MainActor.run { promise(.failure(error)) }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    
    func getMetrics() -> AnyPublisher<[DailyQuestionEntry], Error> {
        return Future<[DailyQuestionEntry], Error> { [weak self] promise in
            guard let self else {
                promise(.failure(URLError(.unknown)))
                return
            }
            Task {
                do {
                    let entries = try await self.performWithRefresh(
                        requestBuilder: { token in
                            guard let user = AuthService.shared.currentUser else {
                                throw URLError(URLError.Code.userAuthenticationRequired)
                            }
                            var components = URLComponents(string: "\(self.baseURL)/main/dailyQuestions")
                            components?.queryItems = [URLQueryItem(name: "userId", value: user.primaryId)]
                            guard let url = components?.url else {
                                throw URLError(.badURL)
                            }
                            var request = URLRequest(url: url)
                            request.httpMethod = "GET"
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                            print("🚀 Request URL: \(request.url?.absoluteString ?? "invalid url")")
                            return request
                        },
                        decode: { data in
                            let responseText = String(data: data, encoding: .utf8) ?? "No body"
                            print("📥 [getMetrics] Response: \(responseText)")
                            let response = try JSONDecoder().decode(DailyQuestionsResponse.self, from: data)
                            let dates = response.dailyQuestions.map { $0.entryDate }.joined(separator: ", ")
                            print("🔄 Decoded daily questions from API for date(s): \(dates)")
                            return response.dailyQuestions
                        }
                    )
                    await MainActor.run { promise(.success(entries)) }
                } catch {
                    await MainActor.run { promise(.failure(error)) }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getScaleQuestions(code: String) async throws -> [String] {
        let items = try await getScaleQuestionItems(code: code)
        return items.map { $0.text }
    }
    
    func getScaleQuestionItems(code: String) async throws -> [ScaleQuestionItem] {
        guard let url = URL(string: "\(baseURL)/main/scales/\(code)/questions") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        if let payload = try? decoder.decode(ScaleQuestionsResponse.self, from: data) {
            return payload.scale.questions.sorted { $0.order < $1.order }
        }
        if let items = try? decoder.decode([ScaleQuestionItem].self, from: data) {
            return items.sorted { $0.order < $1.order }
        }
        if let list = try? decoder.decode([String].self, from: data) {
            return list.enumerated().map { index, text in
                ScaleQuestionItem(id: "\(code)_\(index + 1)", order: index + 1, text: text, isReverse: false)
            }
        }
        
        return []
    }

    func submitScaleAnswers(code: String, userId: String, answers: [ScaleAnswerPayload]) async throws {
        guard let url = URL(string: "\(baseURL)/main/scales/\(code)/answers") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = ScaleAnswersRequest(userId: userId, answers: answers)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (_, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
    }

    func getScaleSessions(userId: String) async throws -> [ScaleSessionScale] {
        var components = URLComponents(string: "\(baseURL)/main/scales/sessions")
        components?.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = components?.url else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        print("ScaleSessions: GET \(url.absoluteString)")
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payload = try JSONDecoder().decode(ScaleSessionsResponse.self, from: data)
        print("ScaleSessions: received \(payload.scales.count) scales")
        return payload.scales
    }

    func createDiaryEntry(content: String, mood: String, entryDate: Date? = nil) async throws -> DiaryEntry {
        let payload = DiaryEntryCreateRequest(
            content: content,
            mood: mood,
            entryDate: entryDate.map { Self.diaryDateFormatter.string(from: $0) }
        )

        return try await diaryRequest(
            method: "POST",
            body: try JSONEncoder().encode(payload),
            decode: { data in
                let payloadResponse = try JSONDecoder().decode(DiaryEntryResponse.self, from: data)
                return payloadResponse.entry
            }
        )
    }
    
    func getDiaryEntries(startDate: Date? = nil, endDate: Date? = nil, limit: Int? = nil, offset: Int? = nil) async throws -> [DiaryEntry] {
        var queryItems: [URLQueryItem] = []
        if let startDate {
            queryItems.append(URLQueryItem(name: "startDate", value: Self.diaryDateFormatter.string(from: startDate)))
        }
        if let endDate {
            queryItems.append(URLQueryItem(name: "endDate", value: Self.diaryDateFormatter.string(from: endDate)))
        }
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }

        return try await diaryRequest(
            method: "GET",
            queryItems: queryItems,
            decode: { data in
                let payload = try JSONDecoder().decode(DiaryEntriesResponse.self, from: data)
                return payload.entries
            }
        )
    }
    
    func getDiaryEntry(id: String) async throws -> DiaryEntry {
        try await diaryRequest(
            path: "/\(id)",
            method: "GET",
            decode: { data in
                let payload = try JSONDecoder().decode(DiaryEntryResponse.self, from: data)
                return payload.entry
            }
        )
    }
    
    func updateDiaryEntry(id: String, content: String? = nil, mood: String? = nil, entryDate: Date? = nil) async throws -> DiaryEntry {
        if content == nil && mood == nil && entryDate == nil {
            throw NSError(domain: "Diary", code: 0, userInfo: [NSLocalizedDescriptionKey: "至少提供一個更新欄位"])
        }
        guard let resolvedContent = content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !resolvedContent.isEmpty else {
            throw NSError(domain: "Diary", code: 0, userInfo: [NSLocalizedDescriptionKey: "缺少日記內容"])
        }
        guard let resolvedMood = mood, !resolvedMood.isEmpty else {
            throw NSError(domain: "Diary", code: 0, userInfo: [NSLocalizedDescriptionKey: "缺少心情"])
        }
        let resolvedEntryDate = entryDate ?? Date()

        try await deleteDiaryEntry(id: id)

        return try await createDiaryEntry(
            content: resolvedContent,
            mood: resolvedMood,
            entryDate: resolvedEntryDate
        )
    }
    
    func deleteDiaryEntry(id: String) async throws -> DiaryEntry {
        return try await diaryRequest(
            path: "/\(id)",
            method: "DELETE",
            decode: { data in
                _ = try JSONDecoder().decode(DiaryDeleteResponse.self, from: data)
                return DiaryEntry(
                    id: id,
                    diaryId: nil,
                    userId: nil,
                    content: nil,
                    mood: nil,
                    entryDate: nil,
                    editCount: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
            }
        )
    }

    func saveDiaryEntry(existingId: String?, content: String, mood: String, entryDate: Date) async throws -> DiaryEntry {
        if let existingId {
            do {
                return try await updateDiaryEntry(
                    id: existingId,
                    content: content,
                    mood: mood,
                    entryDate: entryDate
                )
            } catch let APIServiceError.httpStatus(code, _) where code == 404 {
                let latest = try await latestDiaryEntry(on: entryDate)
                if let latest {
                    return try await updateDiaryEntry(
                        id: latest.id,
                        content: content,
                        mood: mood,
                        entryDate: entryDate
                    )
                }
                return try await createDiaryEntry(content: content, mood: mood, entryDate: entryDate)
            }
        }

        do {
            return try await createDiaryEntry(content: content, mood: mood, entryDate: entryDate)
        } catch let APIServiceError.httpStatus(code, _) where code == 409 || code == 400 {
            if let latest = try await latestDiaryEntry(on: entryDate) {
                return try await updateDiaryEntry(
                    id: latest.id,
                    content: content,
                    mood: mood,
                    entryDate: entryDate
                )
            }
            throw APIServiceError.httpStatus(code, nil)
        }
    }

    func getHealthAdvice(request: HealthAdviceRequest) async throws -> HealthAdviceResponse {
        guard let url = URL(string: healthAdviceURL) else {
            throw URLError(.badURL)
        }
        
        var requestURL = URLRequest(url: url)
        requestURL.httpMethod = "POST"
        requestURL.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            requestURL.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        requestURL.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: requestURL)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(HealthAdviceResponse.self, from: data)
    }
    
    func getEmotionAnalysis(request: EmotionAnalysisRequest) async throws -> EmotionAnalysisResponse {
        guard let url = URL(string: emotionAnalysisURL) else {
            throw URLError(.badURL)
        }
        
        var requestURL = URLRequest(url: url)
        requestURL.httpMethod = "POST"
        requestURL.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            requestURL.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        requestURL.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await session.data(for: requestURL)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(EmotionAnalysisResponse.self, from: data)
    }

    func getUserProfile() async throws -> User {
        guard let url = URL(string: "\(baseURL)/user/profile") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        if let payload = try? decoder.decode(UserProfileResponse.self, from: data),
           let user = payload.user {
            return user
        }
        if let user = try? decoder.decode(User.self, from: data) {
            return user
        }
        
        throw URLError(.cannotParseResponse)
    }

    func updateUserProfile(userId: String, email: String, firstName: String, lastName: String) async throws -> User {
        guard let url = URL(string: "\(baseURL)/user/profile") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = AuthService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let payload = UserProfileUpdateRequest(userId: userId, email: email, firstName: firstName, lastName: lastName)
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let decoder = JSONDecoder()
        if let payload = try? decoder.decode(UserProfileResponse.self, from: data),
           let user = payload.user {
            return user
        }
        if let user = try? decoder.decode(User.self, from: data) {
            return user
        }
        
        throw URLError(.cannotParseResponse)
    }
    
    func createReason(title: String, content: String, date: Date) async throws -> ReasonItem {
        let payload = ReasonCreateRequest(
            title: title,
            content: content,
            date: Self.reasonDateFormatter.string(from: date)
        )

        return try await reasonRequest(
            method: "POST",
            body: try JSONEncoder().encode(payload),
            decode: { data in
                let payloadResponse = try JSONDecoder().decode(ReasonResponse.self, from: data)
                return payloadResponse.reason
            }
        )
    }

    func createReason(
        title: String,
        content: String,
        date: Date,
        token: String
    ) async throws -> ReasonItem {
        guard let url = URL(string: reasonBaseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let payload = ReasonCreateRequest(
            title: title,
            content: content,
            date: Self.reasonDateFormatter.string(from: date)
        )
        request.httpBody = try JSONEncoder().encode(payload)
        
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        let payloadResponse = try JSONDecoder().decode(ReasonResponse.self, from: data)
        return payloadResponse.reason
    }
    
    func getReasons(includeDeleted: Bool = false) async throws -> [ReasonItem] {
        var queryItems: [URLQueryItem] = []
        if includeDeleted {
            queryItems = [URLQueryItem(name: "includeDeleted", value: "true")]
        }

        return try await reasonRequest(
            method: "GET",
            queryItems: queryItems,
            decode: { data in
                let payload = try JSONDecoder().decode(ReasonsResponse.self, from: data)
                return payload.reasons
            }
        )
    }
    
    func getReason(id: String, includeDeleted: Bool = false) async throws -> ReasonItem {
        var queryItems: [URLQueryItem] = []
        if includeDeleted {
            queryItems = [URLQueryItem(name: "includeDeleted", value: "true")]
        }

        return try await reasonRequest(
            path: "/\(id)",
            method: "GET",
            queryItems: queryItems,
            decode: { data in
                let payload = try JSONDecoder().decode(ReasonResponse.self, from: data)
                return payload.reason
            }
        )
    }
    
    func updateReason(id: String, title: String, content: String, date: Date, isDeleted: Bool) async throws -> ReasonItem {
        let payload = ReasonUpdateRequest(
            title: title,
            content: content,
            date: Self.reasonDateFormatter.string(from: date),
            isDeleted: isDeleted
        )

        return try await reasonRequest(
            path: "/\(id)",
            method: "PATCH",
            body: try JSONEncoder().encode(payload),
            decode: { data in
                let payloadResponse = try JSONDecoder().decode(ReasonResponse.self, from: data)
                return payloadResponse.reason
            }
        )
    }
    
    func deleteReason(id: String) async throws -> ReasonItem {
        return try await reasonRequest(
            path: "/\(id)",
            method: "DELETE",
            decode: { data in
                let payloadResponse = try JSONDecoder().decode(ReasonResponse.self, from: data)
                return payloadResponse.reason
            }
        )
    }
}

struct DailyQuestionsResponse: Codable {
    let message: String
    let dailyQuestions: [DailyQuestionEntry]
}

struct DailyQuestionEntry: Codable {
    let physical: Int
    let mental: Int
    let emotion: Int
    let sleep: Int
    let diet: Int
    let userId: String
    let entryDate: String
    
    func toDailyCheckInScores() -> DailyCheckInScores? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: entryDate) else {
            // 如果 ISO8601 解析失敗，嘗試其他格式
            let backupFormatter = DateFormatter()
            backupFormatter.dateFormat = "yyyy-M-dd"
            guard let backupDate = backupFormatter.date(from: entryDate) else {
                print("⚠️ 無法解析日期: \(entryDate)")
                return nil
            }
            return DailyCheckInScores(
                physical: normalizeScore(physical),
                mental: normalizeScore(mental),
                emotional: normalizeScore(emotion),
                sleep: normalizeScore(sleep),
                appetite: normalizeScore(diet),
                date: backupDate
            )
        }
        
        return DailyCheckInScores(
            physical: normalizeScore(physical),
            mental: normalizeScore(mental),
            emotional: normalizeScore(emotion),
            sleep: normalizeScore(sleep),
            appetite: normalizeScore(diet),
            date: date
        )
    }

    private func normalizeScore(_ value: Int) -> Int {
        if value <= 5 {
            return max(1, value)
        }
        switch value {
        case ..<21: return 1
        case ..<41: return 2
        case ..<61: return 3
        case ..<81: return 4
        default: return 5
        }
    }
}

struct ScaleQuestionsResponse: Decodable {
    let message: String
    let scale: ScaleResponse
}

struct ScaleResponse: Decodable {
    let id: String
    let code: String
    let name: String
    let description: String
    let questions: [ScaleQuestionItem]
}

struct ScaleQuestionItem: Decodable {
    let id: String
    let order: Int
    let text: String
    let isReverse: Bool
}

struct ScaleAnswersRequest: Encodable {
    let userId: String
    let answers: [ScaleAnswerPayload]
}

struct ScaleAnswerPayload: Encodable {
    let questionId: String
    let value: Int
}

struct ScaleSessionsResponse: Decodable {
    let message: String
    let scales: [ScaleSessionScale]
}

struct ScaleSessionScale: Decodable, Identifiable {
    let id: String
    let code: String
    let name: String
    let description: String
    let sessions: [ScaleSessionEntry]
}

struct ScaleSessionEntry: Decodable, Identifiable {
    let id: String
    let totalScore: Int
    let createdAt: String
}

struct DiaryEntryCreateRequest: Encodable {
    let content: String
    let mood: String
    let entryDate: String?
}

struct DiaryEntryUpdateRequest: Encodable {
    let content: String?
    let mood: String?
    let entryDate: String?
}

struct DiaryEntriesResponse: Decodable {
    let message: String
    let entries: [DiaryEntry]
}

struct DiaryEntryResponse: Decodable {
    let message: String
    let entry: DiaryEntry
}

struct DiaryDeleteResponse: Decodable {
    let message: String
}

struct DiaryEntry: Decodable {
    let id: String
    let diaryId: String?
    let userId: String?
    let content: String?
    let mood: String?
    let entryDate: String?
    let editCount: Int?
    let createdAt: String?
    let updatedAt: String?
}

struct HealthAdviceRequest: Encodable {
    let range: HealthAdviceRange
    let metrics: HealthAdviceMetrics
}

struct HealthAdviceRange: Encodable {
    let startDate: String
    let endDate: String
}

struct HealthAdviceMetrics: Encodable {
    let hrv: [HealthMetricPoint]
    let sleepHours: [HealthMetricPoint]
    let steps: [HealthMetricPoint]
    let weightKg: [HealthMetricPoint]
}

struct HealthMetricPoint: Encodable {
    let value: Double
    let date: String
}

struct HealthAdviceResponse: Decodable {
    let summary: String
    let items: [HealthAdviceItem]
}

struct HealthAdviceItem: Decodable, Identifiable {
    let id = UUID()
    let title: String
    let detail: String
    let severity: String
}

struct EmotionAnalysisRequest: Encodable {
    let range: HealthAdviceRange
    let entries: [EmotionEntryPayload]
}

struct EmotionEntryPayload: Encodable {
    let date: String
    let mood: String
    let content: String
}

struct EmotionAnalysisResponse: Decodable {
    let trend: [EmotionTrendItem]
    let keywords: [String]
    let insight: String
}

struct EmotionTrendItem: Decodable, Identifiable {
    let id = UUID()
    let label: String
    let ratio: Double
}

struct UserProfileResponse: Decodable {
    let message: String?
    let user: User?
}

struct UserProfileUpdateRequest: Encodable {
    let userId: String
    let email: String
    let firstName: String
    let lastName: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case firstName
        case lastName
    }
}

struct ReasonCreateRequest: Encodable {
    let title: String
    let content: String
    let date: String
}

struct ReasonUpdateRequest: Encodable {
    let title: String
    let content: String
    let date: String
    let isDeleted: Bool
}

struct ReasonsResponse: Decodable {
    let message: String
    let reasons: [ReasonItem]
}

struct ReasonResponse: Decodable {
    let message: String
    let reason: ReasonItem
}

struct ReasonItem: Decodable {
    let id: String
    let userId: String
    let title: String
    let content: String
    let date: String
    let isDeleted: Bool
    let createdAt: String
    let updatedAt: String
}
