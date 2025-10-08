import Foundation

struct AppConfig {
    static let shared = AppConfig()
    
    private init() {}
    
    // MARK: - Environment Configuration
    
    #if DEBUG
    // Development Configuration
    static let baseURL = "http://11.26.5.201:3001"
    static let environment = "development"
    #else
    // Production Configuration
    static let baseURL = "https://your-production-server.com"  // Replace with your actual production URL
    static let environment = "production"
    #endif
    
    // MARK: - API Endpoints
    
    var apiBaseURL: String {
        return AppConfig.baseURL
    }
    
    var authSignupURL: String {
        return "\(apiBaseURL)/auth/signup"
    }
    
    var authLoginURL: String {
        return "\(apiBaseURL)/auth/login"
    }
    
    var forgotPasswordURL: String {
        return "\(apiBaseURL)/auth/forgot-password"
    }
    
    var listingsURL: String {
        return "\(apiBaseURL)/listings"
    }
    
    var messagesURL: String {
        return "\(apiBaseURL)/messages"
    }
    
    var usersURL: String {
        return "\(apiBaseURL)/users"
    }
    
    // MARK: - Helper Methods
    
    func imageURL(for path: String) -> String {
        return "\(apiBaseURL)\(path)"
    }
    
    func userConversationsURL(for userId: Int) -> String {
        return "\(apiBaseURL)/users/\(userId)/conversations"
    }
    
    func listingMessagesURL(for listingId: Int) -> String {
        return "\(apiBaseURL)/listings/\(listingId)/messages"
    }
    
    func userURL(for userId: Int) -> String {
        return "\(apiBaseURL)/users/\(userId)"
    }
    
    func fcmTokenURL(for userId: Int) -> String {
        return "\(apiBaseURL)/users/\(userId)/fcm-token"
    }
    
    func listingClickURL(for listingId: Int) -> String {
        return "\(apiBaseURL)/listings/\(listingId)/click"
    }
}
