import Foundation
import SwiftUI

class ScaleSessionManager: ObservableObject {
    static let shared = ScaleSessionManager()
    
    @Published var scales: [ScaleSessionScale] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private init() {}
    
    func loadSessions() {
        guard let userId = AuthService.shared.currentUser?.primaryId, !userId.isEmpty else {
            errorMessage = "找不到使用者資訊"
            return
        }
        
        print("ScaleSessions: fetching for userId=\(userId)")
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await APIService.shared.getScaleSessions(userId: userId)
                await MainActor.run {
                    self.scales = result
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "載入量表資料失敗"
                }
            }
        }
    }
    
    func seriesForLastSessions(limit: Int = 5, filterCode: String? = nil) -> [ScaleSeries] {
        let palette: [Color] = [
            .red, .blue, .green, .orange, .purple, .teal, .pink, .brown
        ]
        
        let filteredScales = scales.filter { scale in
            guard let filterCode, filterCode != "全部" else { return true }
            return scale.code == filterCode
        }
        
        return filteredScales.enumerated().map { index, scale in
            let data = scoresForRecentSessions(scale: scale, limit: limit)
            return ScaleSeries(
                id: scale.id,
                name: scale.name,
                code: scale.code,
                color: palette[index % palette.count],
                data: data
            )
        }
    }
    
    func scoresForLastWeek(scale: ScaleSessionScale) -> [Int] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = (0..<7).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        
        return days.map { date in
            let sameDaySessions = scale.sessions.filter {
                guard let sessionDate = parseSessionDate($0.createdAt) else { return false }
                return calendar.isDate(sessionDate, inSameDayAs: date)
            }
            return sameDaySessions
                .sorted { $0.createdAt > $1.createdAt }
                .first?
                .totalScore ?? 0
        }
    }

    func scoresForRecentSessions(scale: ScaleSessionScale, limit: Int = 5) -> [Int] {
        let sessions = scale.sessions
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .reversed()
        return sessions.map { $0.totalScore }
    }
    
    func lastSessions(scale: ScaleSessionScale, limit: Int = 5) -> [ScaleSessionEntry] {
        return scale.sessions
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
    
    func parseSessionDate(_ value: String) -> Date? {
        if let date = formatter.date(from: value) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value)
    }
}

struct ScaleSeries: Identifiable {
    let id: String
    let name: String
    let code: String
    let color: Color
    let data: [Int]
}
