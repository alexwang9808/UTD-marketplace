import Foundation

struct Listing: Identifiable, Codable {
    let id: Int?
    let title: String
    let price: Double
    let description: String?
    let location: String?
    let imageUrl: String?
    let imageData: Data?
    let createdAt: String?
    let userId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, title, price, description, location, imageUrl, createdAt, userId
        // imageData is not sent to/from backend
    }
    
    // Custom initializer for decoding (imageData will be nil from backend)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        price = try container.decode(Double.self, forKey: .price)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        imageData = nil // Always nil when decoding from backend
    }
    
    // Custom initializer for local use (with imageData)
    init(id: Int? = nil, title: String, price: Double, description: String? = nil, location: String? = nil, imageUrl: String? = nil, imageData: Data? = nil, createdAt: String? = nil, userId: Int? = nil) {
        self.id = id
        self.title = title
        self.price = price
        self.description = description
        self.location = location
        self.imageUrl = imageUrl
        self.imageData = imageData
        self.createdAt = createdAt
        self.userId = userId
    }
    
    // Custom price display as String
    var priceString: String {
        return String(format: "%.0f", price)
    }
}
