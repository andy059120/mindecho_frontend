//
//  mindechoApp.swift
//  mindecho
//
//  Created by 鄧巧婕 on 2025/7/20.
//

import SwiftUI
import UserNotifications

@main
struct mindechoApp: App {
    init() {
        DailyReminderNotificationManager.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}

final class DailyReminderNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = DailyReminderNotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let reminderIdentifier = "mindecho.daily-login-reminder"

    func configure() {
        center.delegate = self

        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.scheduleDailyReminder()
            case .notDetermined:
                self.requestAuthorizationAndSchedule()
            case .denied:
                break
            @unknown default:
                break
            }
        }
    }

    private func requestAuthorizationAndSchedule() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            if let error {
                print("通知授權錯誤: \(error.localizedDescription)")
                return
            }

            guard granted else { return }
            self?.scheduleDailyReminder()
        }
    }

    private func scheduleDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "MindEcho 每日提醒"
        content.body = "記得登入 MindEcho，紀錄今天的身心狀態。"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("每日通知排程失敗: \(error.localizedDescription)")
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }
}
