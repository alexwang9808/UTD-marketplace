import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let content: String
    let createdAt: String
    let userId: Int
    let listingId: Int
    let user: User?
    
    // Helper to determine if message is from current user
    func isFromCurrentUser(currentUserId: Int) -> Bool {
        return userId == currentUserId
    }
}
