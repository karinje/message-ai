import Foundation
import UserNotifications
import UIKit

final class NotificationService {
    static let shared = NotificationService()
    
    private weak var authService: AuthService?
    private var hasRequestedAuthorization = false
    
    private init() {}
    
    func configure(authService: AuthService) {
        self.authService = authService
    }
    
    func requestAuthorizationIfNeeded() {
        guard !hasRequestedAuthorization else { return }
        hasRequestedAuthorization = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
                return
            }
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func updateFCMToken(_ token: String?) {
        guard let token = token, !token.isEmpty else { return }
        Task { @MainActor in
            await authService?.updateFCMToken(token)
        }
    }
    
    func clearFCMToken() {
        Task { @MainActor in
            await authService?.updateFCMToken("")
        }
    }
    
    func presentLocalNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
