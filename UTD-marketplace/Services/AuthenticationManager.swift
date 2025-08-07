import Foundation
import SwiftUI

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: AuthUser?
    @Published var authToken: String?
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        if let token = UserDefaults.standard.string(forKey: "auth_token"),
           let userId = UserDefaults.standard.object(forKey: "current_user_id") as? Int {
            self.authToken = token
            self.isAuthenticated = true
            
            // Load user data if available
            if let userData = UserDefaults.standard.data(forKey: "current_user_data"),
               let user = try? JSONDecoder().decode(AuthUser.self, from: userData) {
                self.currentUser = user
            }
            
            print("User authenticated: ID \(userId)")
        }
    }
    
    func login(token: String, user: AuthUser) {
        self.authToken = token
        self.currentUser = user
        self.isAuthenticated = true
        
        // Store in UserDefaults
        UserDefaults.standard.set(token, forKey: "auth_token")
        UserDefaults.standard.set(user.id, forKey: "current_user_id")
        
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "current_user_data")
        }
        
        print("Login successful: \(user.email)")
    }
    
    func logout() {
        self.authToken = nil
        self.currentUser = nil
        self.isAuthenticated = false
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "current_user_id")
        UserDefaults.standard.removeObject(forKey: "current_user_data")
        
        print("User logged out")
    }
    
    func getAuthHeaders() -> [String: String] {
        guard let token = authToken else { return [:] }
        return ["Authorization": "Bearer \(token)"]
    }
}

struct AuthUser: Codable, Equatable {
    let id: Int
    let email: String
    let name: String?
    let imageUrl: String?
}