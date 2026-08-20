import Foundation
import UserNotifications

enum NotificationScheduleResult {
    case disabled
    case scheduled
    case denied
}

enum NotificationManager {
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func scheduleReminders(enabled: Bool, hour: Int, minute: Int) async -> NotificationScheduleResult {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return .disabled }

        let granted = await requestAuthorization()
        guard granted else { return .denied }

        let reminders: [(id: String, title: String, body: String, weekday: Int?)] = [
            ("allowance", "Allowance day", "Time to stash at least $1 in the piggy!", nil),
            ("coin-friday", "Coin Friday", "Dump your coins into savings today!", 6),
            ("five-friday", "$5 Friday", "Stash $5 (or more) today!", 6),
        ]

        for reminder in reminders {
            var date = DateComponents()
            date.hour = hour
            date.minute = minute
            if let weekday = reminder.weekday {
                date.weekday = weekday
            }

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let request = UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger)
            try? await center.add(request)
        }
        return .scheduled
    }
}
