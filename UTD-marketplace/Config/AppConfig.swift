import Foundation

struct AppConfig {
    static let shared = AppConfig()
    
    private init() {}
    
    // MARK: - Environment Configuration
    
    // Always use Railway production URL
    static let baseURL = "https://utd-marketplace-production.up.railway.app"
    static let environment = "production"
    
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
