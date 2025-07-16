import Foundation

struct Listing: Identifiable, Codable {
    let id: Int?
    let title: String
    let price: Double
    let description: String?
    let location: String?
    let imageData: Data?
    let createdAt: String?
    let userId: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, title, price, description, location, imageData, createdAt, userId
    }
    
    // Custom price display as String
    var priceString: String {
        return String(format: "%.0f", price)
    }
}
