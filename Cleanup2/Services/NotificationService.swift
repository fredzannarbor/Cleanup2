import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("NotificationService: Authorization error: \(error)")
            }
        }
    }

    /// Schedule notifications for the next 7 days of due tasks.
    /// Respects the iOS 64-notification limit by scheduling at most 60.
    func scheduleUpcoming(tasks: [CleaningTask]) {
        let center = UNUserNotificationCenter.current()
        // Remove all pending to refresh
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        var scheduled = 0
        let maxNotifications = 60

        for dayOffset in 0..<7 {
            guard scheduled < maxNotifications else { break }

            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }

            let dueTasks = tasks.filter { task in
                isDue(task: task, on: targetDate)
            }

            guard !dueTasks.isEmpty else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Cleaning Tasks Due"
            content.body = "\(dueTasks.count) task\(dueTasks.count == 1 ? "" : "s") to complete today"
            content.sound = .default

            var dateComponents = calendar.dateComponents([.year, .month, .day], from: targetDate)
            dateComponents.hour = 9 // 9 AM reminder
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(
                identifier: "cleaning-\(dayOffset)",
                content: content,
                trigger: trigger
            )

            center.add(request) { error in
                if let error = error {
                    print("NotificationService: Failed to schedule: \(error)")
                }
            }
            scheduled += 1
        }
    }

    private func isDue(task: CleaningTask, on date: Date) -> Bool {
        guard let last = task.lastCompleted else { return true }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: last, to: date).day ?? 0
        return daysSince >= task.frequency.intervalDays
    }
}
