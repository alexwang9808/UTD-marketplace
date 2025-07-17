import Foundation

struct Message: Identifiable, Codable {
    let id: Int
    let content: String
    let createdAt: String
    let userId: Int
    let listingId: Int
    let user: User?
    
    // Local-only properties for UI state
    let isSender: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, content, createdAt, userId, listingId, user
        // isSender is not sent to/from backend
    }
    
    // Custom initializer for decoding (isSender will be determined locally)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        userId = try container.decode(Int.self, forKey: .userId)
        listingId = try container.decode(Int.self, forKey: .listingId)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        isSender = nil // Will be determined based on current user
    }
    
    // Custom initializer for local use
    init(id: Int, content: String, createdAt: String = "", userId: Int, listingId: Int, user: User? = nil, isSender: Bool = false) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.userId = userId
        self.listingId = listingId
        self.user = user
        self.isSender = isSender
    }
    
    // Helper to determine if message is from current user
    func isFromCurrentUser(currentUserId: Int) -> Bool {
        return userId == currentUserId
    }
}
