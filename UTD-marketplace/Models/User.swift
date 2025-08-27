import Foundation

struct User: Identifiable, Codable {
    let id: Int?
    let email: String
    let name: String?
    let imageUrl: String?
    let bio: String?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, imageUrl, bio
    }
} 