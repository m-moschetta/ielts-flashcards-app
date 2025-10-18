import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let reminderIdentifier = "daily-review-reminder"

    private init() {}

    func ensureDailyReviewReminder(hour: Int = 20, minute: Int = 0) async {
        let status = await notificationStatus()

        switch status {
        case .notDetermined:
            let granted = await requestAuthorization()
            guard granted else { return }
        case .denied:
            return
        case .authorized, .provisional, .ephemeral:
            break
        @unknown default:
            break
        }

        let alreadyScheduled = await hasScheduledReminder()
        guard !alreadyScheduled else { return }

        await scheduleReminder(hour: hour, minute: minute)
    }

    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private func notificationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func hasScheduledReminder() async -> Bool {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in
                let exists = requests.contains { $0.identifier == self.reminderIdentifier }
                continuation.resume(returning: exists)
            }
        }
    }

    private func scheduleReminder(hour: Int, minute: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "IELTS Flashcards"
        content.body = "È il momento di ripassare qualche flashcard!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)

        do {
            try await add(request)
        } catch {
            #if DEBUG
            print("[NotificationManager] Failed to schedule reminder: \(error)")
            #endif
        }
    }

    private func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            center.add(request) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
