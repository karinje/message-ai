import Foundation
import FirebaseMessaging
import UserNotifications
import UIKit

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // MARK: MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM registration token: \(fcmToken ?? "nil")")
        NotificationService.shared.updateFCMToken(fcmToken)
    }
    
    // MARK: UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        let conversationId = userInfo["conversationId"] as? String
        if NotificationService.shared.isConversationActive(conversationId) {
            completionHandler([.sound])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        Messaging.messaging().appDidReceiveMessage(response.notification.request.content.userInfo)
        completionHandler()
    }
}
