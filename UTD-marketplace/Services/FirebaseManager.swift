import Foundation
import Firebase
import FirebaseMessaging
import UserNotifications

class FirebaseManager: NSObject, ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var fcmToken: String?
    weak var authManager: AuthenticationManager?
    
    override init() {
        super.init()
        
        // Configure Firebase
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        // Set messaging delegate
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        // Request permission for notifications
        requestNotificationPermission()
        
        // Get FCM token
        getFCMToken()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if granted {
                print("Notification permission granted")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    func getFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                DispatchQueue.main.async {
                    self.fcmToken = token
                    self.updateFCMTokenOnServer(token: token)
                }
            }
        }
    }
    
    func updateFCMTokenOnServer(token: String) {
        // Get current user ID from AuthenticationManager
        guard let authManager = authManager,
              let currentUser = authManager.currentUser,
              let url = URL(string: "\(AppConfig.baseURL)/users/\(currentUser.id)/fcm-token") else {
            print("Cannot update FCM token: No authenticated user or invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header
        if let authToken = authManager.authToken {
            request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        }
        
        let body = ["fcmToken": token]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("Error encoding FCM token request: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating FCM token: \(error)")
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("FCM token updated successfully on server")
                } else {
                    print("Failed to update FCM token on server: \(httpResponse.statusCode)")
                }
            }
        }.resume()
    }
}

// MARK: - MessagingDelegate
extension FirebaseManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        
        print("Firebase registration token refreshed: \(fcmToken)")
        DispatchQueue.main.async {
            self.fcmToken = fcmToken
            self.updateFCMTokenOnServer(token: fcmToken)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FirebaseManager: UNUserNotificationCenterDelegate {
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        
        print("Notification received in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        print("Notification tapped: \(userInfo)")
        
        // Handle navigation based on notification data
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract notification data
        guard let type = userInfo["type"] as? String else { return }
        
        if type == "message" {
            // Navigate to conversation
            if let listingIdString = userInfo["listingId"] as? String,
               let listingId = Int(listingIdString) {
                
                // Post notification to navigate to conversation
                NotificationCenter.default.post(
                    name: .navigateToConversation,
                    object: nil,
                    userInfo: ["listingId": listingId]
                )
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let navigateToConversation = Notification.Name("navigateToConversation")
}

