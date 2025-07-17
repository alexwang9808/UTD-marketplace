import Foundation

struct Conversation: Identifiable, Codable {
    let id: String
    let listingId: Int
    let listing: Listing
    let otherUser: User
    let lastMessage: Message
    let messages: [Message]
    
    enum CodingKeys: String, CodingKey {
        case id, listingId, listing, otherUser, lastMessage, messages
    }
} 