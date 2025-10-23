import Foundation
import UserNotifications
import UIKit

final class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private weak var authService: AuthService?
    private var hasRequestedAuthorization = false
    private var activeConversationId: String?
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    func configure(authService: AuthService) {
        self.authService = authService
    }
    
    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestAuthorization()
            case .authorized, .provisional, .ephemeral:
                self.registerForRemoteNotifications()
            case .denied:
                print("🔕 Notification permission denied by user")
            @unknown default:
                print("⚠️ Unknown notification authorization status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }
    
    private func requestAuthorization() {
        guard !hasRequestedAuthorization else {
            registerForRemoteNotifications()
            return
        }
        hasRequestedAuthorization = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
                return
            }
            print("🔔 Notification permission granted? \(granted)")
            if granted {
                self.registerForRemoteNotifications()
            } else {
                print("🔕 Notification permission denied")
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            print("📬 Registering with APNs")
            UIApplication.shared.registerForRemoteNotifications()
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
    
    func setActiveConversation(id: String?) {
        activeConversationId = id
    }
    
    func isConversationActive(_ id: String?) -> Bool {
        guard let id, let activeConversationId else { return false }
        return activeConversationId == id
    }

    @objc
    private func applicationDidBecomeActive() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
