import Foundation
import UserNotifications
import UIKit

protocol NotificationPresenting {
    func handleRemoteRegistrationIfNeeded()
    func presentLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any])
}

final class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private weak var authService: AuthService?
    private var hasRequestedAuthorization = false
    private var activeConversationId: String?
    private let presenter: NotificationPresenting
    
    private override init() {
    #if targetEnvironment(simulator)
        presenter = SimulatorNotificationPresenter()
    #else
        presenter = RemoteNotificationPresenter()
    #endif
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
            self.presenter.handleRemoteRegistrationIfNeeded()
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
    
    func presentLocalDebugNotification(title: String, body: String, userInfo: [AnyHashable: Any]) {
        presenter.presentLocalNotification(title: title, body: body, userInfo: userInfo)
    }

    @objc
    private func applicationDidBecomeActive() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

private final class RemoteNotificationPresenter: NotificationPresenting {
    func handleRemoteRegistrationIfNeeded() {
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func presentLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any]) {
        // No-op in production builds; real pushes handled via APNs
    }
}

private final class SimulatorNotificationPresenter: NotificationPresenting {
    func handleRemoteRegistrationIfNeeded() {
        print("🧪 Simulator detected – skipping APNs registration")
    }
    
    func presentLocalNotification(title: String, body: String, userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
