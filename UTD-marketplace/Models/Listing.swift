import Foundation

struct Listing: Identifiable, Codable {
    let id: Int?
    let title: String
    let price: Double
    let description: String?
    let location: String?
    let imageUrl: String?
    let createdAt: String?
    let userId: Int?
    let user: User?
    
    // Local-only property for temporary image data (not encoded/decoded)
    var imageData: Data? {
        return nil // Always nil since we use imageUrl from backend
    }
    
    // Custom price display as String
    var priceString: String {
        return String(format: "%.0f", price)
    }
}
